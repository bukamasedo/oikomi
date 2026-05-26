import Foundation
import SwiftData

#if canImport(WidgetKit)
    import WidgetKit
#endif

/// ワークアウトセッション関連の書き込み操作を集約する。
///
/// 読み取りは SwiftUI 側で `@Query` を直接使う方が慣用的なので、
/// ここでは create / addSet / finish などの書き込み・更新系のみ提供する。
@MainActor
public final class WorkoutSessionRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 新規セッションを開始して保存する。
    ///
    /// - Parameter routine: 紐付けたいルーティン。`markUsed` も同時に呼ばれる。
    /// - Parameter startLiveActivity: true なら ActivityKit の Live Activity も同時起動（iOSのみ）。
    /// - Parameter fetchHealthSnapshot: true なら HealthKit から HRV/睡眠/安静時心拍数を取得して紐付け。
    @discardableResult
    public func startSession(
        at date: Date = Date(),
        routine: Routine? = nil,
        startLiveActivity: Bool = true,
        fetchHealthSnapshot: Bool = true,
        expandPlannedSets: Bool = true
    ) throws -> WorkoutSession {
        let session = WorkoutSession(startedAt: date, routine: routine)
        context.insert(session)
        if let routine {
            routine.lastUsedAt = date
            // RoutineExercise の planned* を未完了 SetRecord に展開する。
            // ユーザーは Watch 側でこれをタップするだけで完了化できる。
            // `startSessionByCopying` のように既に実績セットを足す予定があれば false で抑止。
            if expandPlannedSets {
                var order = 0
                for routineEx in routine.orderedExercises {
                    guard let exercise = routineEx.exercise else { continue }
                    let plannedReps = routineEx.plannedReps > 0 ? routineEx.plannedReps : nil
                    for _ in 0..<max(routineEx.plannedSets, 0) {
                        let plannedSet = SetRecord(
                            exercise: exercise,
                            session: session,
                            order: order,
                            weight: routineEx.plannedWeight,
                            reps: plannedReps,
                            isCompleted: false
                        )
                        context.insert(plannedSet)
                        order += 1
                    }
                }
            }
        }
        try context.save()

        if startLiveActivity {
            WorkoutActivityController.shared.start(
                sessionId: session.id,
                routineName: routine?.name,
                startedAt: date,
                setCount: 0
            )
        }

        // 受信側 (Watch ↔ iPhone) で session.routine を解決できるよう、
        // Routine 本体を先に送ってからセッションを送る。順序保証はないが、
        // 受信側の pendingSessionRoutineLinks で遅延リンクのフォールバックも入っている。
        if let routine {
            WCSyncBridge.shared.sendRoutineUpsert(routine)
        }
        // expandPlannedSets で生成した未完了 SetRecord を相手端末でも復元できるよう、
        // セット配列を同梱する。空セッションでは空配列が流れるだけで害はない。
        WCSyncBridge.shared.sendSessionUpsert(session, sets: session.orderedSets)
        reloadStatsWidgetTimelines()
        ForgottenSessionNotifier.refresh()

        if fetchHealthSnapshot {
            let sessionId = session.id
            let captureContext = self.context
            Task { @MainActor in
                let snapshot = await HealthStore.shared.fetchSnapshot(referenceDate: date)
                // データが何も取れなければ無駄なレコードを残さない
                guard snapshot.hrvSDNN != nil || snapshot.restingHeartRate != nil || snapshot.sleepScore != nil else {
                    return
                }
                let descriptor = FetchDescriptor<WorkoutSession>(
                    predicate: #Predicate { $0.id == sessionId }
                )
                if let target = try? captureContext.fetch(descriptor).first {
                    captureContext.insert(snapshot)
                    target.healthSnapshot = snapshot
                    try? captureContext.save()
                }
            }
        }

        return session
    }

    /// セット記録をセッションに追加する。
    ///
    /// 自重種目の場合は `weight` を nil、時間計測種目では `reps` を nil で渡す。
    @discardableResult
    public func addSet(
        to session: WorkoutSession,
        exercise: Exercise,
        weight: Double?,
        reps: Int?,
        durationSeconds: Int? = nil,
        isWarmup: Bool = false,
        restSecondsOverride: Int? = nil,
        completedAt: Date = Date()
    ) throws -> SetRecord {
        let nextOrder = (session.sets ?? []).map(\.order).max().map { $0 + 1 } ?? 0

        let estimated1RM: Double? = {
            guard let weight, weight > 0, let reps, reps > 0 else { return nil }
            return OneRepMax.epley(weight: weight, reps: reps)
        }()

        let set = SetRecord(
            exercise: exercise,
            session: session,
            order: nextOrder,
            weight: weight,
            reps: reps,
            durationSeconds: durationSeconds,
            isWarmup: isWarmup,
            estimated1RM: estimated1RM,
            restSecondsOverride: restSecondsOverride,
            completedAt: completedAt
        )
        context.insert(set)
        try context.save()

        // ウォームアップでない限り、自己ベスト更新を試みる
        if !isWarmup {
            let prRepo = PersonalRecordRepository(context: context)
            _ = try? prRepo.updateIfNewBest(from: set)
        }

        WCSyncBridge.shared.sendSetUpsert(set)
        reloadStatsWidgetTimelines()
        ForgottenSessionNotifier.refresh()

        // Live Activity の更新（Live Activity が立ち上がっている時のみ）
        if WorkoutActivityController.shared.isActive {
            let name = exercise.name
            let count = session.sets?.count ?? 0
            let restSec = set.resolveRestSeconds()
            let endAt: Date? =
                restSec > 0
                ? completedAt.addingTimeInterval(TimeInterval(restSec))
                : nil
            Task { @MainActor in
                await WorkoutActivityController.shared.update(
                    currentExerciseName: name,
                    setCount: count,
                    restEndAt: endAt
                )
            }
        }

        return set
    }

    /// 計画セット（未完了）をセッションに追加する。
    ///
    /// iPhone の「今日のメニュー」やセッション途中での追加計画から呼ぶ。
    /// `markSetCompleted(_:)` で実績化されるまで PR 評価・Live Activity 更新は走らない。
    @discardableResult
    public func addPlannedSet(
        to session: WorkoutSession,
        exercise: Exercise,
        weight: Double?,
        reps: Int?,
        durationSeconds: Int? = nil,
        isWarmup: Bool = false,
        restSecondsOverride: Int? = nil
    ) throws -> SetRecord {
        let nextOrder = (session.sets ?? []).map(\.order).max().map { $0 + 1 } ?? 0
        let set = SetRecord(
            exercise: exercise,
            session: session,
            order: nextOrder,
            weight: weight,
            reps: reps,
            durationSeconds: durationSeconds,
            isWarmup: isWarmup,
            restSecondsOverride: restSecondsOverride,
            isCompleted: false
        )
        context.insert(set)
        try context.save()
        WCSyncBridge.shared.sendSetUpsert(set)
        return set
    }

    /// 計画セットを完了化する。
    ///
    /// `actualWeight` / `actualReps` を渡せば実績で上書き（Watch の「調整」フロー）。
    /// nil なら計画値のままで完了（Watch の 1 タップ完了フロー）。
    /// PR 自動更新と Live Activity 更新が走り、レストタイマー終了時刻を返す。
    @discardableResult
    public func markSetCompleted(
        _ set: SetRecord,
        actualWeight: Double? = nil,
        actualReps: Int? = nil,
        actualDurationSeconds: Int? = nil,
        completedAt: Date = Date()
    ) throws -> Date? {
        if let actualWeight { set.weight = actualWeight }
        if let actualReps { set.reps = actualReps }
        if let actualDurationSeconds { set.durationSeconds = actualDurationSeconds }
        set.isCompleted = true
        set.completedAt = completedAt
        if let weight = set.weight, weight > 0, let reps = set.reps, reps > 0 {
            set.estimated1RM = OneRepMax.epley(weight: weight, reps: reps)
        }
        let restSec = set.resolveRestSeconds()
        if restSec > 0 {
            set.restSeconds = restSec
        }
        try context.save()

        if !set.isWarmup {
            let prRepo = PersonalRecordRepository(context: context)
            _ = try? prRepo.updateIfNewBest(from: set)
        }

        WCSyncBridge.shared.sendSetUpsert(set)
        reloadStatsWidgetTimelines()
        ForgottenSessionNotifier.refresh()

        let restEndAt: Date? =
            restSec > 0
            ? completedAt.addingTimeInterval(TimeInterval(restSec))
            : nil

        // 相手端末のレストタイマーも起動。完了時刻と total を確定した値で渡し、
        // 受信側で defaultRestSeconds を再計算しない（種目マスタ差分による表示ずれを回避）。
        // 直前完了セットの weight / reps も同梱して、受信側でサブテキスト表示
        // （「80kg × 5 · 180秒」）に使えるようにする。bodyweight など値が nil の場合はそのまま nil で送る。
        if let endAt = restEndAt {
            WCSyncBridge.shared.sendRestTimerStart(
                endAt: endAt,
                totalSeconds: restSec,
                completedWeightKg: set.weight,
                completedReps: set.reps
            )
        }

        if WorkoutActivityController.shared.isActive, let exercise = set.exercise {
            let name = exercise.name
            let count = set.session?.sets?.filter { $0.isCompleted }.count ?? 0
            Task { @MainActor in
                await WorkoutActivityController.shared.update(
                    currentExerciseName: name,
                    setCount: count,
                    restEndAt: restEndAt
                )
            }
        }

        return restEndAt
    }

    /// 完了済みセットを未完了 (planned) 状態に戻す。
    ///
    /// 「うっかりチェックを入れてしまった」ケースの取消用。1RM スナップショットと
    /// レスト秒数はクリアし、再完了時に再計算される。
    /// 過去に発生した PR は遡って取消さない (履歴の整合性より UX 単純さを優先)。
    @discardableResult
    public func uncompleteSet(_ set: SetRecord) throws -> SetRecord {
        set.isCompleted = false
        set.estimated1RM = nil
        set.restSeconds = nil
        try context.save()

        WCSyncBridge.shared.sendSetUpsert(set)
        // 完了→未完了に戻したら、相手端末のレストタイマーも止める（スキップと同じ扱い）。
        WCSyncBridge.shared.sendRestTimerCancel()
        reloadStatsWidgetTimelines()

        // Live Activity の setCount を再計算
        if WorkoutActivityController.shared.isActive, let session = set.session {
            let count = session.sets?.filter { $0.isCompleted }.count ?? 0
            let lastCompletedName =
                session.orderedSets.last(where: { $0.isCompleted })?.exercise?.name
                ?? set.exercise?.name ?? ""
            Task { @MainActor in
                await WorkoutActivityController.shared.update(
                    currentExerciseName: lastCompletedName,
                    setCount: count,
                    restEndAt: nil
                )
            }
        }

        return set
    }

    /// 既存セット (planned / completed どちらも) の重量・レップ・所要秒数を上書きする。
    ///
    /// 完了済みセットは 1RM 再計算と PR 自動再評価が走る。
    /// 未完了 (planned) セットは値だけ更新し、完了化は別途 `markSetCompleted` を呼ぶこと。
    /// Live Activity の更新は伴わない (種目自体は変わらないため UI コストに見合わない)。
    @discardableResult
    public func updateSet(
        _ set: SetRecord,
        weight: Double?,
        reps: Int?,
        durationSeconds: Int? = nil
    ) throws -> SetRecord {
        set.weight = weight
        set.reps = reps
        if let durationSeconds {
            set.durationSeconds = durationSeconds
        }
        if set.isCompleted {
            if let w = weight, w > 0, let r = reps, r > 0 {
                set.estimated1RM = OneRepMax.epley(weight: w, reps: r)
            } else {
                set.estimated1RM = nil
            }
        }
        try context.save()

        // 完了済み・非ウォームアップなら PR 再評価。値を下げた場合に既存 PR が下回ることはあるが、
        // PersonalRecordRepository.updateIfNewBest は「新記録なら更新」しかしないので副作用は安全側。
        if set.isCompleted && !set.isWarmup {
            let prRepo = PersonalRecordRepository(context: context)
            _ = try? prRepo.updateIfNewBest(from: set)
        }

        WCSyncBridge.shared.sendSetUpsert(set)
        reloadStatsWidgetTimelines()
        return set
    }

    /// セッション内の特定セットに対してレスト秒数の上書きを設定/解除する。
    /// `value == nil` で上書き解除（種目デフォルトに戻す）。
    public func setRestSecondsOverride(_ value: Int?, on set: SetRecord) throws {
        set.restSecondsOverride = value
        try context.save()
        WCSyncBridge.shared.sendSetUpsert(set)
    }

    /// セット 1 件を削除する。完了済みの場合は履歴から消える。
    /// `WorkoutSession.sets` の cascade 削除ルールに従って関連は自動整理。
    public func deleteSet(_ set: SetRecord) throws {
        let session = set.session
        context.delete(set)
        try context.save()
        reloadStatsWidgetTimelines()

        if WorkoutActivityController.shared.isActive, let session {
            let count = session.sets?.filter { $0.isCompleted }.count ?? 0
            let lastName = session.orderedSets.last?.exercise?.name ?? ""
            Task { @MainActor in
                await WorkoutActivityController.shared.update(
                    currentExerciseName: lastName,
                    setCount: count,
                    restEndAt: nil
                )
            }
        }
    }

    /// セッション内の特定種目に紐づく全セットを削除する。
    /// 「クイック追加で間違って入れた種目を丸ごと消したい」ユースケース。
    /// 削除件数を返す（呼び出し側のフィードバック用）。
    @discardableResult
    public func deleteExercise(_ exercise: Exercise, from session: WorkoutSession) throws -> Int {
        let targets = (session.sets ?? []).filter { $0.exercise?.id == exercise.id }
        for set in targets {
            context.delete(set)
        }
        try context.save()
        reloadStatsWidgetTimelines()

        if WorkoutActivityController.shared.isActive {
            let count = session.sets?.filter { $0.isCompleted }.count ?? 0
            let lastName = session.orderedSets.last?.exercise?.name ?? ""
            Task { @MainActor in
                await WorkoutActivityController.shared.update(
                    currentExerciseName: lastName,
                    setCount: count,
                    restEndAt: nil
                )
            }
        }

        return targets.count
    }

    /// 既存セッションを複製して新しいセッションを開始する。
    ///
    /// 仕様書 §4.1.4「履歴コピー」の実装。`source` の routine 紐付けと全セット内容（種目・重量・
    /// レップ・durationSeconds・isWarmup）を引き継いで新セッションに格納する。完了時刻は現時刻。
    /// 推定 1RM の再計算と PR 自動更新は addSet 経由で行われる。
    @discardableResult
    public func startSessionByCopying(
        _ source: WorkoutSession,
        at date: Date = Date()
    ) throws -> WorkoutSession {
        // 履歴の実績を即「完了済み」で複製するため、ルーティンの planned 展開は抑止する
        let newSession = try startSession(at: date, routine: source.routine, expandPlannedSets: false)
        // 過去のセッションに残った planned (未完了) セットは「実績」ではないので複製対象外
        for sourceSet in source.orderedSets where sourceSet.isCompleted {
            guard let exercise = sourceSet.exercise else { continue }
            try addSet(
                to: newSession,
                exercise: exercise,
                weight: sourceSet.weight,
                reps: sourceSet.reps,
                durationSeconds: sourceSet.durationSeconds,
                isWarmup: sourceSet.isWarmup,
                completedAt: date
            )
        }
        return newSession
    }

    /// セッションを終了し、終了時刻を記録する。
    ///
    /// `writeToHealthKit` が true なら HKWorkout として書き込みも試みる（権限拒否時は無視）。
    public func finishSession(
        _ session: WorkoutSession,
        at date: Date = Date(),
        writeToHealthKit: Bool = true
    ) async throws {
        let sid = session.id.uuidString.prefix(8)
        print("[Oikomi.sync] finishSession step=enter id=\(sid)")
        session.endedAt = date
        do {
            try context.save()
            print("[Oikomi.sync] finishSession step=saved id=\(sid)")
        } catch {
            print("[Oikomi.sync] finishSession step=save_failed id=\(sid) error=\(error)")
            throw error
        }

        if writeToHealthKit {
            do {
                if let uuid = try await HealthStore.shared.saveWorkout(session) {
                    session.healthKitWorkoutUUID = uuid
                    try context.save()
                }
                print("[Oikomi.sync] finishSession step=hk_done id=\(sid)")
            } catch {
                // HealthKit 書き込み失敗はセッション保存自体には影響させない
                print("[Oikomi.sync] finishSession step=hk_skipped id=\(sid) error=\(error)")
            }
        }

        await WorkoutActivityController.shared.end()
        print("[Oikomi.sync] finishSession step=activity_ended id=\(sid)")

        WCSyncBridge.shared.sendSessionUpsert(session)
        reloadStatsWidgetTimelines()
        ForgottenSessionNotifier.cancel()
        print("[Oikomi.sync] finishSession step=upsert_called id=\(sid)")
    }

    /// セッションを削除する（途中で破棄したい場合）。
    ///
    /// 削除対象が現在 Live Activity を持っているセッションなら、Live Activity も即座に閉じる。
    /// 別セッションを誤って end しないよう `currentSessionId` と ID 照合する。
    public func deleteSession(_ session: WorkoutSession) async throws {
        let sessionId = session.id
        context.delete(session)
        try context.save()
        reloadStatsWidgetTimelines()
        ForgottenSessionNotifier.cancel()

        if WorkoutActivityController.shared.currentSessionId == sessionId {
            await WorkoutActivityController.shared.end()
        }
    }

    private func reloadStatsWidgetTimelines() {
        #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: "OikomiStatsWidget")
        #endif
    }

    /// 指定種目について、過去全セッション横断で最終完了 SetRecord を返す。
    ///
    /// ルーティン編集 UI で planned* の初期値を「直近実績」から埋める用途。
    /// ウォームアップと未完了 (計画) セットは除外し、`completedAt` 降順の先頭を取る。
    public func lastCompletedSet(for exercise: Exercise) throws -> SetRecord? {
        let exerciseId = exercise.id
        var descriptor = FetchDescriptor<SetRecord>(
            predicate: #Predicate<SetRecord> { set in
                set.isCompleted == true
                    && set.isWarmup == false
                    && set.exercise?.id == exerciseId
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// `olderThan` 秒以上前に開始されたまま終了していないセッションを自動終了する。
    ///
    /// 開発中のクラッシュ/再インストールで「endedAt が nil のまま残った」
    /// stale active session を起動時に掃除し、UI の「アクティブ表示が消えない」
    /// 症状を防ぐ。終了時刻は startedAt + 1 秒（即時終了扱い）。
    /// WCSyncBridge へは送らない（他デバイスも各自掃除する想定）。
    ///
    /// - Returns: 終了に切り替えたセッションの数
    @discardableResult
    public func cleanupStaleActiveSessions(olderThan: TimeInterval = 24 * 3600) throws -> Int {
        let cutoff = Date().addingTimeInterval(-olderThan)
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endedAt == nil && $0.startedAt < cutoff }
        )
        let stale = try context.fetch(descriptor)
        guard !stale.isEmpty else { return 0 }
        for session in stale {
            session.endedAt = session.startedAt.addingTimeInterval(1)
        }
        try context.save()
        return stale.count
    }
}

extension SetRecord {
    /// このセット完了時に採用するレスト秒数を解決する。
    ///
    /// 優先順位:
    /// 1. このセット自身の restSecondsOverride（クイック追加時のユーザー明示指定）
    /// 2. セッションが Routine 由来で、その RoutineExercise に plannedRestSeconds があればそれを使う
    /// 3. なければ Exercise.defaultRestSeconds（種目マスター値）にフォールバック
    public func resolveRestSeconds() -> Int {
        if let override = restSecondsOverride {
            return max(0, override)
        }
        guard let exercise else { return 0 }
        if let routineEx = linkedRoutineExercise(),
            let override = routineEx.plannedRestSeconds
        {
            return max(0, override)
        }
        return exercise.defaultRestSeconds
    }

    /// このセットがルーティン由来かを判定し、対応する RoutineExercise を返す。
    /// セッションに routine が紐付き、その routine 内に同じ Exercise を持つ entry があればそれを返す。
    public func linkedRoutineExercise() -> RoutineExercise? {
        guard let routine = session?.routine,
            let exerciseId = exercise?.id
        else { return nil }
        return (routine.exercises ?? []).first { $0.exercise?.id == exerciseId }
    }
}

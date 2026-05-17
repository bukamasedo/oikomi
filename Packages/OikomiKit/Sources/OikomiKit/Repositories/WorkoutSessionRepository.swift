import Foundation
import SwiftData

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
        fetchHealthSnapshot: Bool = true
    ) throws -> WorkoutSession {
        let session = WorkoutSession(startedAt: date, routine: routine)
        context.insert(session)
        if let routine {
            routine.lastUsedAt = date
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

        WCSyncBridge.shared.notifyChange(kind: .sessionStarted)

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
            completedAt: completedAt
        )
        context.insert(set)
        try context.save()

        // ウォームアップでない限り、自己ベスト更新を試みる
        if !isWarmup {
            let prRepo = PersonalRecordRepository(context: context)
            _ = try? prRepo.updateIfNewBest(from: set)
        }

        WCSyncBridge.shared.notifyChange(kind: .setRecorded)

        // Live Activity の更新（Live Activity が立ち上がっている時のみ）
        if WorkoutActivityController.shared.isActive {
            let name = exercise.name
            let count = session.sets?.count ?? 0
            let endAt: Date? = exercise.defaultRestSeconds > 0
                ? completedAt.addingTimeInterval(TimeInterval(exercise.defaultRestSeconds))
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
        let newSession = try startSession(at: date, routine: source.routine)
        for sourceSet in source.orderedSets {
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
        session.endedAt = date
        try context.save()

        if writeToHealthKit {
            do {
                if let uuid = try await HealthStore.shared.saveWorkout(session) {
                    session.healthKitWorkoutUUID = uuid
                    try context.save()
                }
            } catch {
                // HealthKit 書き込み失敗はセッション保存自体には影響させない
            }
        }

        await WorkoutActivityController.shared.end()
        WCSyncBridge.shared.notifyChange(kind: .sessionFinished)
    }

    /// セッションを削除する（途中で破棄したい場合）。
    public func deleteSession(_ session: WorkoutSession) throws {
        context.delete(session)
        try context.save()
    }
}

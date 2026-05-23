import Foundation
import SwiftData

#if canImport(WatchConnectivity)
    import WatchConnectivity
#endif

#if canImport(WidgetKit)
    import WidgetKit
#endif

/// iPhone ↔ Apple Watch のリアルタイム実データ同期ブリッジ。
///
/// 設計:
/// - `WCSession.delegateQueue` は未設定（API 上 read-only）。delegate メソッドは
///   WatchConnectivity の bg queue で発火するため、各 delegate 実装内で
///   `Task { @MainActor in ... }` により MainActor に hop してから WCSyncBridge へ
///   状態を渡す。これにより actor 隔離の crossing を安全に閉じ込める。
/// - クラスは `@MainActor` 全体隔離。delegate からのコールバックは Task hop 経由で
///   渡されるため、内部状態（applyingRemoteUpdate / lastReachable / contextProvider）は
///   常に MainActor 上で読み書きされる。
/// - `sendMessage` の errorHandler から WC API を再呼び出ししない（libdispatch assertion 回避）。
///   reachable 判定で OS の queueing 機構に責任を委譲。
/// - リーチャビリティ復旧時（false→true）は `sessionReachabilityDidChange` から
///   `requestFullSync()` を発火し、Bluetooth 切断や iPhone 一時停止から戻ったときの
///   取りこぼしを自動回復する。
@MainActor
public final class WCSyncBridge {

    public static let shared = WCSyncBridge()

    /// 互換維持のための通知（旧コードからの呼び出し対応）。
    public static let dataDidChangeNotification = Notification.Name("OikomiDataDidChange")

    /// receive 由来の write 中は send を抑制する。
    private var applyingRemoteUpdate: Bool = false

    /// 受信時に upsert に使う ModelContext を返すクロージャ。
    private var modelContextProvider: (() -> ModelContext)?

    /// session upsert 時に対象 routine がローカルに未到着だった場合の遅延リンク辞書。
    /// 後続の routine upsert 受信時に走査して session.routine を貼り直す。
    /// Key: sessionId, Value: routineId
    private var pendingSessionRoutineLinks: [UUID: UUID] = [:]

    /// 直前に観測した WCSession.isReachable。false→true の変化検知に使う。
    /// reachability が復旧した瞬間に fullSync を再要求するためのトリガー。
    private var lastReachable: Bool = false

    /// 最後に処理した restTimerStart / restTimerCancel envelope の timestamp。
    /// 送受信どちらでも更新し、これより古い timestamp の envelope / applicationContext は無視する。
    /// 連続セット完了で sendMessage + transferUserInfo + applicationContext が三重に届くケースや、
    /// cancel→start の順序逆転で UI が消える事故を防ぐ。
    private var lastRestTimerEnvelopeAt: Date?

    #if canImport(WatchConnectivity)
        /// delegate は内部のヘルパーオブジェクトに委譲（NSObject 要件のため）。
        private let delegate = SyncDelegate()
    #endif

    private init() {}

    // MARK: - Testing

    /// 単体テスト専用: singleton の内部 state（restTimer envelope timestamp ガード）をリセットする。
    /// アプリ本体では呼ばないこと。
    internal func _resetRestTimerStateForTesting() {
        lastRestTimerEnvelopeAt = nil
    }

    // MARK: - Activate

    /// アプリ起動時に呼ぶ。WCSession を activate + delegate 設定。
    ///
    /// - Parameter contextProvider: 受信時に upsert に使う ModelContext を返すクロージャ。
    ///   `MainActor` 上で呼ばれる（delegateQueue=.main により保証）。
    public func activate(contextProvider: @escaping () -> ModelContext) {
        modelContextProvider = contextProvider
        #if canImport(WatchConnectivity)
            guard WCSession.isSupported() else { return }
            let session = WCSession.default
            session.delegate = delegate
            session.activate()
        #endif
    }

    // MARK: - リーチャビリティ復旧フック

    #if canImport(WatchConnectivity)
        /// `SyncDelegate.session(_:activationDidCompleteWith:error:)` から MainActor hop 後に呼ばれる。
        /// activated + reachable のときに一度だけ pull を投げ、起動直後の取りこぼしを埋める。
        internal func handleActivationCompleted(
            state: WCSessionActivationState,
            reachable: Bool
        ) {
            lastReachable = reachable
            guard state == .activated, reachable else { return }
            print("[Oikomi.sync] activation completed + reachable, requesting fullSync")
            requestFullSync()
        }
    #endif

    /// `SyncDelegate.sessionReachabilityDidChange(_:)` から MainActor hop 後に呼ばれる。
    /// false→true の遷移時のみ fullSync を要求する。
    /// 双方向で発火するので二重リクエストになり得るが、`respondToFullSyncRequest` は
    /// id ベース upsert で冪等なため副作用なし。
    internal func handleReachabilityChange(_ reachable: Bool) {
        let previous = lastReachable
        lastReachable = reachable
        print("[Oikomi.sync] reachability \(previous) -> \(reachable)")
        guard !previous, reachable else { return }
        requestFullSync()
    }

    // MARK: - 送信

    public func sendSessionUpsert(_ session: WorkoutSession, sets: [SetRecord] = []) {
        print(
            "[Oikomi.sync] sendSessionUpsert entry id=\(session.id.uuidString.prefix(8)) endedAt=\(session.endedAt?.description ?? "nil") applyingRemoteUpdate=\(applyingRemoteUpdate)"
        )
        if applyingRemoteUpdate {
            print("[Oikomi.sync] sendSessionUpsert SKIPPED (applyingRemoteUpdate=true)")
            return
        }
        let setDTOs = sets.compactMap { $0.makeDTO() }
        let envelope = SyncEnvelope(
            kind: .sessionUpsert,
            sessions: [session.makeDTO()],
            sets: setDTOs
        )
        let isFinish = session.endedAt != nil
        print(
            "[Oikomi.sync] send sessionUpsert id=\(session.id.uuidString.prefix(8)) endedAt=\(session.endedAt?.description ?? "nil") guaranteed=\(isFinish)"
        )
        // 終了イベントは reachable の揺れで sendMessage が cancel されることがあるため、
        // OS の永続キュー transferUserInfo に並行配送して必着にする。
        dispatch(envelope, guaranteedDelivery: isFinish)
    }

    public func sendSetUpsert(_ set: SetRecord) {
        if applyingRemoteUpdate { return }
        guard let dto = set.makeDTO() else { return }
        var sessionDTOs: [WorkoutSessionDTO] = []
        if let session = set.session {
            sessionDTOs.append(session.makeDTO())
        }
        let envelope = SyncEnvelope(
            kind: .setUpsert,
            sessions: sessionDTOs,
            sets: [dto]
        )
        dispatch(envelope)
    }

    public func sendRoutineUpsert(_ routine: Routine) {
        if applyingRemoteUpdate { return }
        let envelope = SyncEnvelope(
            kind: .routineUpsert,
            routines: [routine.makeDTO()]
        )
        dispatch(envelope)
    }

    public func sendRoutineDeleted(_ id: UUID) {
        if applyingRemoteUpdate { return }
        let envelope = SyncEnvelope(
            kind: .routineDeleted,
            deletedRoutineIds: [id]
        )
        dispatch(envelope)
    }

    /// 「すべてのデータを削除」を相手デバイスに伝える。
    /// 失敗すると Watch 側に古いデータが残るため guaranteedDelivery=true で必着送信。
    public func sendBulkDelete() {
        if applyingRemoteUpdate { return }
        let envelope = SyncEnvelope(kind: .bulkDelete)
        print("[Oikomi.sync] sendBulkDelete dispatched")
        dispatch(envelope, guaranteedDelivery: true)
    }

    /// 種目のお気に入り状態を相手デバイスに送る。Exercise は name で照合する既存規約に従う。
    public func sendExerciseFavoriteUpdate(exerciseId: UUID, isFavorite: Bool) {
        if applyingRemoteUpdate { return }
        guard let provider = modelContextProvider else { return }
        let context = provider()
        guard
            let exercise = try? context.fetch(
                FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == exerciseId })
            ).first
        else { return }
        let envelope = SyncEnvelope(
            kind: .exerciseFavoriteUpdate,
            exerciseFavorites: [ExerciseFavoriteDTO(exerciseName: exercise.name, isFavorite: isFavorite)]
        )
        dispatch(envelope)
    }

    public func requestFullSync() {
        let envelope = SyncEnvelope(kind: .fullSyncRequest)
        dispatch(envelope)
    }

    /// iPhone でアプリアイコンを切り替えた時に Watch へ通知する。
    /// `iconName` は `UIApplication.setAlternateIconName` と同じ規約: `nil` = primary（デフォルト）。
    /// Watch 側は受信時に `WKApplication.shared().setAlternateIconName` を呼んで自動追従する。
    /// reachable 揺れに備え guaranteedDelivery で送る。
    public func sendIconChange(iconName: String?) {
        if applyingRemoteUpdate { return }
        let envelope = SyncEnvelope(kind: .iconChange, iconName: iconName)
        print("[Oikomi.sync] sendIconChange dispatched name=\(iconName ?? "<primary>")")
        dispatch(envelope, guaranteedDelivery: true)
    }

    /// iPhone で Sign in with Apple のサインイン / サインアウト状態が変わった時に Watch へ通知する。
    /// Watch には SIWA UI が無いため、iPhone 由来の状態を表示専用に同期する。
    /// `userID` が nil ならサインアウト扱い。
    public func sendAuthStateChange(userID: String?, displayName: String?) {
        if applyingRemoteUpdate { return }
        let envelope = SyncEnvelope(
            kind: .authStateChange,
            authUserID: userID,
            authDisplayName: displayName
        )
        print("[Oikomi.sync] sendAuthStateChange dispatched signedIn=\(userID != nil)")
        dispatch(envelope, guaranteedDelivery: true)
    }

    /// レストタイマーをスキップしたことを相手デバイスに伝え、相手のローカル通知も止める。
    /// iPhone でも Watch でも skip ハンドラから呼ぶ。
    /// guaranteedDelivery=true で sendMessage + transferUserInfo に並行配送し、reachable の
    /// 瞬間揺れでも必着にする。さらに applicationContext を最新状態（cancel=nil）に更新し、
    /// アプリ起動直後や再 reachable 時の自動回復を狙う。
    public func sendRestTimerCancel() {
        if applyingRemoteUpdate { return }
        let envelope = SyncEnvelope(kind: .restTimerCancel)
        lastRestTimerEnvelopeAt = envelope.timestamp
        print("[Oikomi.sync] sendRestTimerCancel dispatched")
        dispatch(envelope, guaranteedDelivery: true)
        updateRestTimerContext(endAt: nil, totalSeconds: nil, envelopeAt: envelope.timestamp)
    }

    /// セット完了によりレストタイマーが起動したことを相手デバイスに伝える。
    /// 受信側はローカル通知をスケジュールし、UI / Live Activity を更新する。
    /// guaranteedDelivery=true で sendMessage + transferUserInfo を並行配送し、reachable の
    /// 瞬間揺れでも必着にする。さらに applicationContext を最新状態（endAt / totalSeconds）に
    /// 更新し、アプリ起動直後や再 reachable 時の自動回復を狙う。
    public func sendRestTimerStart(endAt: Date, totalSeconds: Int) {
        if applyingRemoteUpdate { return }
        let envelope = SyncEnvelope(
            kind: .restTimerStart,
            restEndAt: endAt,
            restTotalSeconds: totalSeconds
        )
        lastRestTimerEnvelopeAt = envelope.timestamp
        print("[Oikomi.sync] sendRestTimerStart dispatched endAt=\(endAt) total=\(totalSeconds)")
        dispatch(envelope, guaranteedDelivery: true)
        updateRestTimerContext(
            endAt: endAt,
            totalSeconds: totalSeconds,
            envelopeAt: envelope.timestamp
        )
    }

    /// 現在のレストタイマー状態を applicationContext に投影する。
    /// applicationContext は WCSession が「最新値だけ保持」する別経路で、未起動 / 未到達中の
    /// 相手にも OS が起動直後・reachable 復旧直後に自動配送してくれる。
    /// endAt=nil は cancel 状態を意味する（キーを付けない）。envelopeAt は受信側のガードに使う。
    private func updateRestTimerContext(endAt: Date?, totalSeconds: Int?, envelopeAt: Date) {
        #if canImport(WatchConnectivity)
            guard WCSession.isSupported() else { return }
            let session = WCSession.default
            guard session.activationState == .activated else { return }

            var context: [String: Any] = [
                "oikomi.restTimer.envelopeAt": envelopeAt
            ]
            if let endAt {
                context["oikomi.restTimer.endAt"] = endAt
                context["oikomi.restTimer.totalSeconds"] = totalSeconds ?? 60
            }

            do {
                try session.updateApplicationContext(context)
                print(
                    "[Oikomi.sync] updateApplicationContext restTimer endAt=\(endAt?.description ?? "nil")"
                )
            } catch {
                print("WCSyncBridge updateApplicationContext failed: \(error)")
            }
        #endif
    }

    // MARK: - 受信（delegate から MainActor で呼ばれる）

    internal func handleEnvelope(_ envelope: SyncEnvelope) {
        print(
            "[Oikomi.sync] received envelope kind=\(envelope.kind.rawValue) sessions=\(envelope.sessions.count) sets=\(envelope.sets.count) routines=\(envelope.routines.count)"
        )

        var restEndAtForNotification: Date? = nil

        switch envelope.kind {
        case .sessionUpsert, .setUpsert, .routineUpsert, .routineDeleted, .fullSyncResponse,
            .exerciseFavoriteUpdate:
            applyEnvelopeToLocalStore(envelope)
        case .bulkDelete:
            applyBulkDeleteToLocalStore()
        case .fullSyncRequest:
            respondToFullSyncRequest()
        case .restTimerCancel:
            // 古い envelope の後着で UI が消えるのを防ぐ stale ガード。
            // stale なら NotificationCenter にも何も流さない。
            if isStaleRestTimerEnvelope(envelope) {
                print(
                    "[Oikomi.sync] restTimerCancel skipped (stale timestamp \(envelope.timestamp))"
                )
                return
            }
            lastRestTimerEnvelopeAt = envelope.timestamp
            applyRestTimerCancel()
        case .restTimerStart:
            // stale ガードは expired チェックと分離する（expired は kind だけ通知される
            // 既存挙動を維持、stale は完全に無視）。
            if isStaleRestTimerEnvelope(envelope) {
                print(
                    "[Oikomi.sync] restTimerStart skipped (stale timestamp \(envelope.timestamp))"
                )
                return
            }
            lastRestTimerEnvelopeAt = envelope.timestamp
            restEndAtForNotification = applyRestTimerStart(envelope)
        case .iconChange:
            applyIconChange(iconName: envelope.iconName)
        case .authStateChange:
            applyAuthStateChange(
                userID: envelope.authUserID,
                displayName: envelope.authDisplayName
            )
        }

        var userInfo: [String: Any] = ["kind": envelope.kind.rawValue]
        if envelope.kind == .restTimerStart {
            // 送信側 envelope.restEndAt ではなく、受信側時計に補正した localEndAt を流す。
            // expired (nil) ならキー自体を付けず、UI 層の endAt > Date() ガードで自然にスキップさせる。
            if let local = restEndAtForNotification {
                userInfo["endAt"] = local
            }
            if let total = envelope.restTotalSeconds { userInfo["totalSeconds"] = total }
        }
        NotificationCenter.default.post(
            name: Self.dataDidChangeNotification,
            object: nil,
            userInfo: userInfo
        )
    }

    private func applyEnvelopeToLocalStore(_ envelope: SyncEnvelope) {
        guard let provider = modelContextProvider else { return }
        let context = provider()

        applyingRemoteUpdate = true
        defer { applyingRemoteUpdate = false }

        for dto in envelope.routines { upsert(routine: dto, in: context) }
        for dto in envelope.sessions { upsert(session: dto, in: context) }
        for dto in envelope.sets { upsert(set: dto, in: context) }
        for id in envelope.deletedRoutineIds { deleteRoutine(id: id, in: context) }
        for dto in envelope.exerciseFavorites ?? [] { applyExerciseFavorite(dto, in: context) }

        do {
            try context.save()
            // @Query が予期せぬキャッシュを持っている場合に備えて pending changes を flush。
            // SwiftData は save() で内部的に通知を出すが、processPendingChanges でさらに
            // 観察者に確実にイベントを伝える保険。
            context.processPendingChanges()
        } catch {
            print("WCSyncBridge: applyEnvelope save failed: \(error)")
        }

        reloadStatsWidgetTimelines()
    }

    /// 相手デバイスから iconChange を受け取ったときの処理。
    /// watchOS は alternate icon の runtime 切替 API が存在しない（`UIApplication.setAlternateIconName`
    /// は `API_UNAVAILABLE(watchos)`）ため、現状ログのみ。iOS 側は送信のみで自動適用しない。
    /// 将来 watchOS が API を公開した場合に enable できるよう envelope kind は残す。
    private func applyIconChange(iconName: String?) {
        print(
            "[Oikomi.sync] iconChange received name=\(iconName ?? "<primary>") (no-op: alternate icons unsupported on watchOS)"
        )
    }

    /// 相手デバイス (主に Watch) から authStateChange を受け取った時の処理。
    /// AppleAuthManager に反映して UserDefaults にも書き戻す。
    private func applyAuthStateChange(userID: String?, displayName: String?) {
        print("[Oikomi.sync] authStateChange received signedIn=\(userID != nil)")
        applyingRemoteUpdate = true
        defer { applyingRemoteUpdate = false }
        AppleAuthManager.shared.applyRemoteState(userID: userID, displayName: displayName)
    }

    /// 相手デバイスから restTimerCancel を受け取ったときの処理。
    /// ローカルの pending notification をキャンセルし、Live Activity の restEndAt をクリア。
    /// UI 層 (restEndAt @State) は dataDidChangeNotification を観察してクリアする。
    ///
    /// 呼び出し側で `isStaleRestTimerEnvelope` ガード済みを前提とする。
    private func applyRestTimerCancel() {
        RestTimerNotifier.cancel()
        if WorkoutActivityController.shared.isActive {
            Task { @MainActor in
                await WorkoutActivityController.shared.clearRestEnd()
            }
        }
    }

    /// `envelope.timestamp` が直近処理済みの restTimer envelope より古ければ stale と判定する。
    /// 連続セット完了で sendMessage + transferUserInfo + applicationContext が三重に届くケースや、
    /// cancel→start の順序逆転で UI が消える事故を防ぐ。
    private func isStaleRestTimerEnvelope(_ envelope: SyncEnvelope) -> Bool {
        guard let last = lastRestTimerEnvelopeAt else { return false }
        return envelope.timestamp <= last
    }

    /// 相手デバイスから restTimerStart を受け取ったときの処理。
    ///
    /// 送信側時計と受信側時計のドリフト + WCSession 配送遅延を `envelope.timestamp` を
    /// 基準に補正し、受信側ローカル時計で `localEndAt` を再構築する。これにより
    /// 「iPhone と Apple Watch の内部クロック差」が残り秒数のずれとして現れる問題を解消する。
    /// 戻り値: 補正後の `localEndAt`（expired のときは nil）。呼び出し側で NotificationCenter
    /// にも同じ値を載せ、UI / Live Activity / ローカル通知の 3 経路を揃える。
    private func applyRestTimerStart(_ envelope: SyncEnvelope) -> Date? {
        guard let senderEndAt = envelope.restEndAt else { return nil }

        // 呼び出し側で `isStaleRestTimerEnvelope` を判定してから来ることを前提とする。
        // 戻り値 nil は「expired（配送遅延が rest 全長を超えた）」を意味する。

        // 送信側時計基準の純粋な rest 時間（時計差・配送遅延を含まない）
        let originalRemaining = senderEndAt.timeIntervalSince(envelope.timestamp)
        // 送信→受信の経過時間（時計差 + 配送遅延の合算）
        let transitLatency = Date().timeIntervalSince(envelope.timestamp)
        let remaining = originalRemaining - transitLatency

        guard remaining > 0.5 else {
            print(
                "[Oikomi.sync] applyRestTimerStart skipped (expired) originalRemaining=\(originalRemaining) transitLatency=\(transitLatency)"
            )
            return nil
        }

        let localEndAt = Date().addingTimeInterval(remaining)
        print(
            "[Oikomi.sync] applyRestTimerStart senderEndAt=\(senderEndAt) localEndAt=\(localEndAt) transitLatency=\(transitLatency)"
        )

        RestTimerNotifier.scheduleRestEnd(at: localEndAt)
        if WorkoutActivityController.shared.isActive {
            Task { @MainActor in
                await WorkoutActivityController.shared.setRestEnd(localEndAt)
            }
        }
        return localEndAt
    }

    /// `applicationContext` 経由で届いたレストタイマー状態を処理する。
    /// envelope に組み直してから `applyRestTimerStart` / `applyRestTimerCancel` に流し、
    /// timestamp ガード・transit latency 補正・Notifier / Live Activity 連動を共通化する。
    /// アプリ起動直後（WCSession activate 完了時）や reachable 復旧時に OS が自動配送し、
    /// sendMessage / transferUserInfo が取りこぼした最新状態をここで復元する。
    ///
    /// `[String: Any]` は Sendable でないため、SyncDelegate 側で Sendable な要素（Date, Int）に
    /// 分解してからこの API を呼ぶ。`endAt == nil` は cancel 状態を表す。
    internal func handleRestTimerContext(
        envelopeAt: Date?,
        endAt: Date?,
        totalSeconds: Int?
    ) {
        guard let envelopeAt else { return }

        if let endAt {
            let total = totalSeconds ?? 60
            let envelope = SyncEnvelope(
                kind: .restTimerStart,
                timestamp: envelopeAt,
                restEndAt: endAt,
                restTotalSeconds: total
            )
            if isStaleRestTimerEnvelope(envelope) {
                print("[Oikomi.sync] restTimer context start skipped (stale \(envelopeAt))")
                return
            }
            lastRestTimerEnvelopeAt = envelope.timestamp
            guard let localEndAt = applyRestTimerStart(envelope) else { return }
            NotificationCenter.default.post(
                name: Self.dataDidChangeNotification,
                object: nil,
                userInfo: [
                    "kind": SyncEnvelope.Kind.restTimerStart.rawValue,
                    "endAt": localEndAt,
                    "totalSeconds": total,
                ]
            )
        } else {
            let envelope = SyncEnvelope(kind: .restTimerCancel, timestamp: envelopeAt)
            if isStaleRestTimerEnvelope(envelope) {
                print("[Oikomi.sync] restTimer context cancel skipped (stale \(envelopeAt))")
                return
            }
            lastRestTimerEnvelopeAt = envelope.timestamp
            applyRestTimerCancel()
            NotificationCenter.default.post(
                name: Self.dataDidChangeNotification,
                object: nil,
                userInfo: ["kind": SyncEnvelope.Kind.restTimerCancel.rawValue]
            )
        }
    }

    /// 相手デバイスからの bulkDelete を受け取った時のローカル全削除処理。
    /// 設定画面の resetAllData と同じ範囲を削除し、シード種目を再投入する。
    private func applyBulkDeleteToLocalStore() {
        guard let provider = modelContextProvider else { return }
        let context = provider()

        applyingRemoteUpdate = true
        defer { applyingRemoteUpdate = false }

        do {
            try context.delete(model: WorkoutSession.self)
            try context.delete(model: SetRecord.self)
            try context.delete(model: Routine.self)
            try context.delete(model: RoutineExercise.self)
            try context.delete(model: PersonalRecord.self)
            try context.delete(model: HealthSnapshot.self)
            try context.delete(model: Exercise.self)
            try context.save()
            try ExerciseRepository(context: context).seedIfNeeded()
            context.processPendingChanges()
            pendingSessionRoutineLinks.removeAll()
            print("[Oikomi.sync] applyBulkDelete done")
        } catch {
            print("WCSyncBridge: applyBulkDelete failed: \(error)")
        }

        reloadStatsWidgetTimelines()
    }

    /// ウィジェットのタイムラインをリロード。
    /// iOS / watchOS / macOS で WidgetKit が利用可能（tvOS のみ非対応）。
    private func reloadStatsWidgetTimelines() {
        #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: "OikomiStatsWidget")
        #endif
    }

    private func respondToFullSyncRequest() {
        guard let provider = modelContextProvider else { return }
        let context = provider()

        // 直近 7 日のセッション (active と ended の両方) を返す。
        // active のみだと「Watch 側は終了済みだが iPhone は active と認識」
        // という終了イベント取りこぼし状態を修復できない。最近終了したセッションも
        // 含めて配ることで、iPhone の foreground 復帰時に endedAt を引き直せる。
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        let recentDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.startedAt > cutoff }
        )
        let routineDescriptor = FetchDescriptor<Routine>()

        let sessions = (try? context.fetch(recentDescriptor)) ?? []
        let routines = (try? context.fetch(routineDescriptor)) ?? []

        let sessionDTOs = sessions.map { $0.makeDTO() }
        let setDTOs = sessions.flatMap { $0.orderedSets.compactMap { $0.makeDTO() } }
        let routineDTOs = routines.map { $0.makeDTO() }

        let envelope = SyncEnvelope(
            kind: .fullSyncResponse,
            sessions: sessionDTOs,
            sets: setDTOs,
            routines: routineDTOs
        )
        dispatch(envelope)
    }

    // MARK: - Upsert

    private func upsert(session dto: WorkoutSessionDTO, in context: ModelContext) {
        let id = dto.id
        let existing = try? context.fetch(
            FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id })
        ).first

        let session: WorkoutSession
        let wasExisting = existing != nil
        if let existing {
            session = existing
        } else {
            session = WorkoutSession(id: dto.id, startedAt: dto.startedAt)
            context.insert(session)
        }

        session.startedAt = dto.startedAt
        session.endedAt = dto.endedAt
        session.notes = dto.notes

        if let rid = dto.routineId {
            let r = try? context.fetch(
                FetchDescriptor<Routine>(predicate: #Predicate { $0.id == rid })
            ).first
            session.routine = r
            if r == nil {
                // 該当 Routine がまだローカルに到着していない（envelope 順序保証なし）。
                // 後続の routineUpsert を受けた時に再リンクする。
                pendingSessionRoutineLinks[dto.id] = rid
                print(
                    "[Oikomi.sync] pending routine link queued session=\(dto.id.uuidString.prefix(8)) routine=\(rid.uuidString.prefix(8))"
                )
            } else {
                pendingSessionRoutineLinks.removeValue(forKey: dto.id)
            }
        } else {
            session.routine = nil
            pendingSessionRoutineLinks.removeValue(forKey: dto.id)
        }

        print(
            "[Oikomi.sync] upsert session id=\(dto.id.uuidString.prefix(8)) endedAt=\(dto.endedAt?.description ?? "nil") existing=\(wasExisting ? "Y" : "N")"
        )

        // 不変条件「アクティブセッションは 1 つだけ」を強制。
        // 新規アクティブな session が来たら、他のアクティブはすべて終了扱いにする。
        // 多デバイス間の独立スタートで活アクティブが累積する症状を防ぐ。
        if dto.endedAt == nil {
            let myId = dto.id
            let othersDescriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> {
                    $0.endedAt == nil && $0.id != myId
                }
            )
            if let others = try? context.fetch(othersDescriptor) {
                for other in others {
                    other.endedAt = other.startedAt.addingTimeInterval(1)
                    print(
                        "[Oikomi.sync] auto-ended stale active session id=\(other.id.uuidString.prefix(8)) (single-active invariant)"
                    )
                }
            }
        }
    }

    private func upsert(set dto: SetRecordDTO, in context: ModelContext) {
        let id = dto.id
        let existing = try? context.fetch(
            FetchDescriptor<SetRecord>(predicate: #Predicate { $0.id == id })
        ).first

        let exerciseName = dto.exerciseName
        let exercise = try? context.fetch(
            FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == exerciseName })
        ).first

        let sessionId = dto.sessionId
        let session = try? context.fetch(
            FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == sessionId })
        ).first

        let setRecord: SetRecord
        if let existing {
            setRecord = existing
        } else {
            setRecord = SetRecord(id: dto.id)
            context.insert(setRecord)
        }

        setRecord.exercise = exercise
        setRecord.session = session
        setRecord.order = dto.order
        setRecord.weight = dto.weight
        setRecord.reps = dto.reps
        setRecord.durationSeconds = dto.durationSeconds
        setRecord.isWarmup = dto.isWarmup
        setRecord.completedAt = dto.completedAt
        // 古い envelope は isCompleted を持たない → true として扱う（既存挙動互換）
        setRecord.isCompleted = dto.isCompleted ?? true

        if let weight = dto.weight, let reps = dto.reps, weight > 0, reps > 0 {
            setRecord.estimated1RM = OneRepMax.epley(weight: weight, reps: reps)
        }
    }

    private func applyExerciseFavorite(_ dto: ExerciseFavoriteDTO, in context: ModelContext) {
        let name = dto.exerciseName
        guard
            let exercise = try? context.fetch(
                FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == name })
            ).first
        else { return }
        exercise.isFavorite = dto.isFavorite
    }

    private func upsert(routine dto: RoutineDTO, in context: ModelContext) {
        let id = dto.id
        let existing = try? context.fetch(
            FetchDescriptor<Routine>(predicate: #Predicate { $0.id == id })
        ).first

        let routine: Routine
        if let existing {
            routine = existing
        } else {
            routine = Routine(id: dto.id, name: dto.name, createdAt: dto.createdAt)
            context.insert(routine)
        }

        routine.name = dto.name
        routine.lastUsedAt = dto.lastUsedAt

        for entry in routine.exercises ?? [] {
            context.delete(entry)
        }
        // 新形式 (`dto.exercises`) があれば planned* を反映。旧バイナリは `exerciseNames` のみ
        // 送ってくるので、その場合は RoutineExercise.init のデフォルト値で再構築する（既存挙動）。
        let entries: [RoutineExerciseDTO]
        if let provided = dto.exercises {
            entries = provided.sorted { $0.order < $1.order }
        } else {
            entries = dto.exerciseNames.enumerated().map { idx, name in
                RoutineExerciseDTO(
                    exerciseName: name,
                    order: idx,
                    plannedSets: 3,
                    plannedReps: 8,
                    plannedWeight: nil
                )
            }
        }
        for entry in entries {
            let exerciseName = entry.exerciseName
            let exercise = try? context.fetch(
                FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == exerciseName })
            ).first
            guard let exercise else { continue }
            let routineExercise = RoutineExercise(
                routine: routine,
                exercise: exercise,
                order: entry.order,
                plannedSets: entry.plannedSets,
                plannedReps: entry.plannedReps,
                plannedWeight: entry.plannedWeight
            )
            context.insert(routineExercise)
        }

        resolvePendingRoutineLinks(routine: routine, in: context)
    }

    /// `upsert(session:)` で routine が未到着だったセッションを、routine が届いたタイミングで
    /// 貼り直す。Watch でルーティン選択 → iPhone 反映時の race condition 対策。
    private func resolvePendingRoutineLinks(routine: Routine, in context: ModelContext) {
        let routineId = routine.id
        let pendingSessionIds =
            pendingSessionRoutineLinks
            .filter { $0.value == routineId }
            .map { $0.key }
        guard !pendingSessionIds.isEmpty else { return }
        for sid in pendingSessionIds {
            let descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == sid })
            if let session = try? context.fetch(descriptor).first {
                session.routine = routine
                print(
                    "[Oikomi.sync] resolved pending routine link session=\(sid.uuidString.prefix(8)) routine=\(routineId.uuidString.prefix(8))"
                )
            }
            pendingSessionRoutineLinks.removeValue(forKey: sid)
        }
    }

    private func deleteRoutine(id: UUID, in context: ModelContext) {
        let descriptor = FetchDescriptor<Routine>(predicate: #Predicate { $0.id == id })
        if let routine = try? context.fetch(descriptor).first {
            context.delete(routine)
        }
    }

    // MARK: - 送信路

    private func dispatch(_ envelope: SyncEnvelope, guaranteedDelivery: Bool = false) {
        #if canImport(WatchConnectivity)
            guard WCSession.isSupported() else { return }
            let session = WCSession.default
            guard session.activationState == .activated else { return }

            let data: Data
            do {
                data = try JSONEncoder.oikomi.encode(envelope)
            } catch {
                print("WCSyncBridge encode failed: \(error)")
                return
            }

            let payload: [String: Any] = [
                "type": "oikomi.sync",
                "data": data,
            ]

            if session.isReachable {
                // errorHandler は WatchConnectivity の bg queue (NSOperationQueue UTILITY) で呼ばれる。
                // WCSyncBridge は @MainActor なので inline closure を渡すと MainActor 隔離を継承し、
                // bg queue で実行された瞬間 swift_task_checkIsolatedSwift が assertion を発火させる。
                // ファイルスコープの @Sendable 関数経由でアクター継承を断ち切り、失敗時は OS の
                // 配送キュー transferUserInfo にフォールバックさせる（reachable 復旧時に自動配送）。
                sendWithFallback(session: session, payload: payload)
                if guaranteedDelivery {
                    // 終了イベントなど絶対に届けたいものは、sendMessage が OS 内部で cancel
                    // されるケースに備えて transferUserInfo に並行投入する。
                    // upsert は id ベースの冪等処理なので二重受信しても結果は同じ。
                    print("[Oikomi.sync] dispatch route=sendMessage+transferUserInfo (guaranteed)")
                    session.transferUserInfo(payload)
                } else {
                    print("[Oikomi.sync] dispatch route=sendMessage")
                }
            } else {
                // 相手が起動していない / バックグラウンドのとき → キューイング
                print("[Oikomi.sync] dispatch route=transferUserInfo (not reachable)")
                session.transferUserInfo(payload)
            }
        #endif
    }
}

#if canImport(WatchConnectivity)

    /// sendMessage 失敗時の transferUserInfo フォールバックを担う @Sendable ヘルパー。
    /// 失敗 closure は WC の bg queue で呼ばれるため、アクター継承を断ち切る必要がある。
    /// payload `[String: Any]` 自体は非 Sendable なので、closure 内では Sendable な要素
    /// (Data) だけ capture し、retry 用 payload は closure 内で再構築する。
    private func sendWithFallback(session: WCSession, payload: [String: Any]) {
        let dataForRetry = payload["data"] as? Data
        session.sendMessage(
            payload,
            replyHandler: nil,
            errorHandler: { @Sendable (error: any Error) in
                // bg queue で実行される。print と WCSession の API 呼び出しは thread-safe。
                print("WCSyncBridge sendMessage failed: \(error.localizedDescription)")
                // OS の配送キューに乗せる。reachable=NO 時や直後の unreachable 化でも
                // 後で必ず配送される。
                guard let data = dataForRetry else { return }
                let retryPayload: [String: Any] = ["type": "oikomi.sync", "data": data]
                WCSession.default.transferUserInfo(retryPayload)
            }
        )
    }

#endif

// MARK: - JSON encoder / decoder（ISO8601）

extension JSONEncoder {
    fileprivate static let oikomi: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    fileprivate static let oikomi: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

#if canImport(WatchConnectivity)

    /// WCSession の delegate。`delegateQueue` は未設定（API 上 read-only）のため、
    /// delegate メソッドは WatchConnectivity の bg queue で発火する。
    /// 各 delegate 実装内で `Task { @MainActor in ... }` により MainActor へ hop してから
    /// WCSyncBridge の状態を変更する。
    private final class SyncDelegate: NSObject, WCSessionDelegate {

        func session(
            _ session: WCSession,
            activationDidCompleteWith activationState: WCSessionActivationState,
            error: (any Error)?
        ) {
            if let error {
                print("WCSession activation failed: \(error)")
            }
            let reachable = session.isReachable
            // activate 完了時点で OS が既に保持している最新 applicationContext を読み出す。
            // ここから restTimer 状態を復元できれば、Watch アプリを開いた瞬間に進行中の
            // レストタイマーが即時表示される（didReceiveApplicationContext を待たない）。
            // [String: Any] は Sendable でないため Sendable 要素に分解してから渡す。
            let receivedContext = session.receivedApplicationContext
            let envelopeAt = receivedContext["oikomi.restTimer.envelopeAt"] as? Date
            let endAt = receivedContext["oikomi.restTimer.endAt"] as? Date
            let totalSeconds = receivedContext["oikomi.restTimer.totalSeconds"] as? Int
            Task { @MainActor in
                WCSyncBridge.shared.handleActivationCompleted(
                    state: activationState,
                    reachable: reachable
                )
                if envelopeAt != nil {
                    WCSyncBridge.shared.handleRestTimerContext(
                        envelopeAt: envelopeAt,
                        endAt: endAt,
                        totalSeconds: totalSeconds
                    )
                }
            }
        }

        /// reachability が変化したとき発火（iOS / watchOS 両方）。
        /// false→true の遷移で WCSyncBridge.handleReachabilityChange が fullSync を引く。
        func sessionReachabilityDidChange(_ session: WCSession) {
            let reachable = session.isReachable
            Task { @MainActor in
                WCSyncBridge.shared.handleReachabilityChange(reachable)
            }
        }

        #if os(iOS)
            func sessionDidBecomeInactive(_ session: WCSession) {}
            func sessionDidDeactivate(_ session: WCSession) {
                WCSession.default.activate()
            }
        #endif

        func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
            decodeAndApply(message)
        }

        func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
            decodeAndApply(userInfo)
        }

        /// `updateApplicationContext` で投影されたレストタイマー状態を受け取る。
        /// アプリ起動直後 / reachable 復旧直後に OS が自動配送する。
        /// delegate は WC の bg queue で呼ばれるので、Sendable な要素に分解してから
        /// MainActor へ hop して WCSyncBridge に渡す（`[String: Any]` は Sendable でない）。
        func session(
            _ session: WCSession,
            didReceiveApplicationContext applicationContext: [String: Any]
        ) {
            let envelopeAt = applicationContext["oikomi.restTimer.envelopeAt"] as? Date
            let endAt = applicationContext["oikomi.restTimer.endAt"] as? Date
            let totalSeconds = applicationContext["oikomi.restTimer.totalSeconds"] as? Int
            Task { @MainActor in
                WCSyncBridge.shared.handleRestTimerContext(
                    envelopeAt: envelopeAt,
                    endAt: endAt,
                    totalSeconds: totalSeconds
                )
            }
        }

        /// payload を decode し、MainActor で WCSyncBridge に渡す。
        /// delegate は WC の bg queue で呼ばれるため、`Task { @MainActor in ... }` で
        /// MainActor に hop してから状態を触る。
        private func decodeAndApply(_ payload: [String: Any]) {
            guard payload["type"] as? String == "oikomi.sync" else { return }
            guard let data = payload["data"] as? Data else { return }
            let envelope: SyncEnvelope
            do {
                envelope = try JSONDecoder.oikomi.decode(SyncEnvelope.self, from: data)
            } catch {
                print("WCSyncBridge decode failed: \(error)")
                return
            }
            // delegate は WC の bg queue で呼ばれるので、Task で MainActor に hop してから
            // WCSyncBridge の状態（@MainActor 隔離）を触る。
            Task { @MainActor in
                WCSyncBridge.shared.handleEnvelope(envelope)
            }
        }
    }

#endif

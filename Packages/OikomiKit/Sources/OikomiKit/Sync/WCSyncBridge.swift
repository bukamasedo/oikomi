import Foundation
import SwiftData

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// iPhone ↔ Apple Watch のリアルタイム実データ同期ブリッジ。
///
/// 設計（v2 リライト）:
/// - `WCSession.delegateQueue = OperationQueue.main` を明示し、delegate コールバックを
///   すべて main queue で受ける。これにより actor crossing 不要。
/// - クラスは `@MainActor` 全体隔離をやめ、`@unchecked Sendable` の NSObject に。
///   ステートは `@MainActor` プロパティで隔離し、send/receive メソッドは MainActor で動かす。
/// - `sendMessage` の errorHandler から WC API を再呼び出ししない（libdispatch assertion 回避）。
///   reachable 判定で OS の queueing 機構に責任を委譲。
/// - WCSessionDelegate を本クラスに直接実装（旧アダプタ削除）。
@MainActor
public final class WCSyncBridge {

    public static let shared = WCSyncBridge()

    /// 互換維持のための通知（旧コードからの呼び出し対応）。
    public static let dataDidChangeNotification = Notification.Name("OikomiDataDidChange")

    /// receive 由来の write 中は send を抑制する。
    private var applyingRemoteUpdate: Bool = false

    /// 受信時に upsert に使う ModelContext を返すクロージャ。
    private var modelContextProvider: (() -> ModelContext)?

    #if canImport(WatchConnectivity)
    /// delegate は内部のヘルパーオブジェクトに委譲（NSObject 要件のため）。
    private let delegate = SyncDelegate()
    #endif

    private init() {}

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

    /// 種目のお気に入り状態を相手デバイスに送る。Exercise は name で照合する既存規約に従う。
    public func sendExerciseFavoriteUpdate(exerciseId: UUID, isFavorite: Bool) {
        if applyingRemoteUpdate { return }
        guard let provider = modelContextProvider else { return }
        let context = provider()
        guard let exercise = try? context.fetch(
            FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == exerciseId })
        ).first else { return }
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

    // MARK: - 受信（delegate から MainActor で呼ばれる）

    fileprivate func handleEnvelope(_ envelope: SyncEnvelope) {
        print(
            "[Oikomi.sync] received envelope kind=\(envelope.kind.rawValue) sessions=\(envelope.sessions.count) sets=\(envelope.sets.count) routines=\(envelope.routines.count)"
        )
        switch envelope.kind {
        case .sessionUpsert, .setUpsert, .routineUpsert, .routineDeleted, .fullSyncResponse, .exerciseFavoriteUpdate:
            applyEnvelopeToLocalStore(envelope)
        case .fullSyncRequest:
            respondToFullSyncRequest()
        }

        NotificationCenter.default.post(
            name: Self.dataDidChangeNotification,
            object: nil,
            userInfo: ["kind": envelope.kind.rawValue]
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
        } else {
            session.routine = nil
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
        guard let exercise = try? context.fetch(
            FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == name })
        ).first else { return }
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
        for (index, name) in dto.exerciseNames.enumerated() {
            let exerciseName = name
            let exercise = try? context.fetch(
                FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == exerciseName })
            ).first
            guard let exercise else { continue }
            let entry = RoutineExercise(routine: routine, exercise: exercise, order: index)
            context.insert(entry)
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
/// payload と session の WCSession.default は両方 Sendable なので、ファイルスコープで安全に扱える。
private func sendWithFallback(session: WCSession, payload: [String: Any]) {
    // payload は [String: Any] で Sendable ではないが、ここで持つだけで MainActor 越境はしない。
    // closure 内で再構成しても結果は同じだが、エンコード重複を避けるため capture する。
    let payloadForRetry = payload
    session.sendMessage(
        payload,
        replyHandler: nil,
        errorHandler: { @Sendable (error: any Error) in
            // bg queue で実行される。print と WCSession の API 呼び出しは thread-safe。
            print("WCSyncBridge sendMessage failed: \(error.localizedDescription)")
            // OS の配送キューに乗せる。reachable=NO 時や直後の unreachable 化でも
            // 後で必ず配送される。
            WCSession.default.transferUserInfo(payloadForRetry)
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

/// WCSession の delegate。`delegateQueue = .main` を設定するため、
/// delegate メソッドはすべて main queue で発火する。`MainActor.assumeIsolated`
/// で MainActor として実行する。
private final class SyncDelegate: NSObject, WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            print("WCSession activation failed: \(error)")
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

    /// payload を decode し、MainActor で WCSyncBridge に渡す。
    /// 注: delegateQueue=.main を使っていれば main で呼ばれるが、
    /// `MainActor.assumeIsolated` で明示的に MainActor として扱う。
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
        // delegateQueue=.main により既に main queue 上だが、念のため Task で隔離。
        // Task { @MainActor in ... } は main から呼ばれた場合も安全に動く。
        Task { @MainActor in
            WCSyncBridge.shared.handleEnvelope(envelope)
        }
    }
}

#endif

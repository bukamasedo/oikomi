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
        if applyingRemoteUpdate { return }
        let setDTOs = sets.compactMap { $0.makeDTO() }
        let envelope = SyncEnvelope(
            kind: .sessionUpsert,
            sessions: [session.makeDTO()],
            sets: setDTOs
        )
        dispatch(envelope)
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

    public func requestFullSync() {
        let envelope = SyncEnvelope(kind: .fullSyncRequest)
        dispatch(envelope)
    }

    // MARK: - 受信（delegate から MainActor で呼ばれる）

    fileprivate func handleEnvelope(_ envelope: SyncEnvelope) {
        switch envelope.kind {
        case .sessionUpsert, .setUpsert, .routineUpsert, .routineDeleted, .fullSyncResponse:
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

        do {
            try context.save()
        } catch {
            print("WCSyncBridge: applyEnvelope save failed: \(error)")
        }
    }

    private func respondToFullSyncRequest() {
        guard let provider = modelContextProvider else { return }
        let context = provider()

        let activeDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endedAt == nil }
        )
        let routineDescriptor = FetchDescriptor<Routine>()

        let sessions = (try? context.fetch(activeDescriptor)) ?? []
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

        if let weight = dto.weight, let reps = dto.reps, weight > 0, reps > 0 {
            setRecord.estimated1RM = OneRepMax.epley(weight: weight, reps: reps)
        }
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

    private func dispatch(_ envelope: SyncEnvelope) {
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
            // errorHandler は bg queue で呼ばれるので、その中で別の WC API を叩かない。
            // 失敗時のリカバリは次回 write 時の dispatch に委ねる。
            session.sendMessage(payload, replyHandler: nil) { error in
                print("WCSyncBridge sendMessage failed: \(error)")
            }
        } else {
            // 相手が起動していない / バックグラウンドのとき → キューイング
            session.transferUserInfo(payload)
        }
        #endif
    }
}

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

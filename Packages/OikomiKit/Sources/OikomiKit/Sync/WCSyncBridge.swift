import Foundation
import SwiftData

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// iPhone ↔ Apple Watch のリアルタイム実データ同期ブリッジ。
///
/// 設計:
/// - 任意の write 後に `SyncEnvelope` を送信。ペイロードは Codable な DTO を JSON 化して
///   `[String: Any]` の `"data"` キーに `Data` として詰める
/// - 受信側は decode して SwiftData の `ModelContext` に upsert（id で fetch → 存在すれば
///   更新 / 無ければ insert）
/// - 受信由来の更新では `applyingRemoteUpdate` を true にして send をスキップ → 送り返しループ防止
/// - Watch 起動時に `fullSyncRequest` を投げ、iPhone が進行中セッション + ルーティンを `fullSyncResponse` で返す
@MainActor
public final class WCSyncBridge: NSObject {

    public static let shared = WCSyncBridge()

    /// 互換維持のため残してある通知（旧 ping ベースの呼び出し先で使われる）。
    /// 新しい仕組みは context-aware の upsert なので、UI 側で個別ハンドラ不要。
    public static let dataDidChangeNotification = Notification.Name("OikomiDataDidChange")

    /// receive 由来の context 書き込みを抑制するためのフラグ。
    /// repository の send* メソッドは冒頭でこれをチェックして送信スキップする。
    private(set) var applyingRemoteUpdate: Bool = false

    #if canImport(WatchConnectivity)
    private var sessionDelegate: WCSessionDelegateAdapter?
    #endif

    /// receive 時に書き込む対象の context。アプリ起動時に bootstrap 完了後に注入する。
    private var modelContextProvider: (@MainActor () -> ModelContext)?

    /// アプリ起動時に呼ぶ。WCSession を activate + delegate 設定。
    ///
    /// - Parameter contextProvider: 受信時に upsert に使う ModelContext を返すクロージャ。
    ///   SwiftData の `@MainActor` 制約と相性を取るため、毎回取りに行く形にする。
    public func activate(contextProvider: @escaping @MainActor () -> ModelContext) {
        modelContextProvider = contextProvider
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let adapter = WCSessionDelegateAdapter()
        sessionDelegate = adapter
        let session = WCSession.default
        session.delegate = adapter
        session.activate()
        #endif
    }

    // MARK: - 送信

    /// 単一セッション（および任意で同梱セット）を送信。
    public func sendSessionUpsert(_ session: WorkoutSession, sets: [SetRecord] = []) {
        guard !applyingRemoteUpdate else { return }
        let setDTOs = sets.compactMap { $0.makeDTO() }
        let envelope = SyncEnvelope(
            kind: .sessionUpsert,
            sessions: [session.makeDTO()],
            sets: setDTOs
        )
        dispatch(envelope)
    }

    public func sendSetUpsert(_ set: SetRecord) {
        guard !applyingRemoteUpdate else { return }
        guard let dto = set.makeDTO() else { return }
        // セット送信時に親セッションも含めると初回受信側でセッション不在のとき自動作成できる
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
        guard !applyingRemoteUpdate else { return }
        let envelope = SyncEnvelope(
            kind: .routineUpsert,
            routines: [routine.makeDTO()]
        )
        dispatch(envelope)
    }

    public func sendRoutineDeleted(_ id: UUID) {
        guard !applyingRemoteUpdate else { return }
        let envelope = SyncEnvelope(
            kind: .routineDeleted,
            deletedRoutineIds: [id]
        )
        dispatch(envelope)
    }

    /// 受信側（主に Watch 起動時）から呼ぶ。送信側（iPhone）に「全部送って」を依頼。
    public func requestFullSync() {
        let envelope = SyncEnvelope(kind: .fullSyncRequest)
        dispatch(envelope)
    }

    // MARK: - 受信

    /// WCSessionDelegateAdapter からデコード済み envelope が渡される。
    fileprivate func didReceive(envelope: SyncEnvelope) {
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
        for dto in envelope.sets     { upsert(set: dto, in: context) }
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

        // 進行中セッション + 全ルーティンを返す
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

        // Last Write Wins: dto の値を全反映
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

        // 推定 1RM を再計算
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

        // 既存の RoutineExercise を全部消して、dto の順序で作り直す（シンプル & 確実）
        for entry in routine.exercises ?? [] {
            context.delete(entry)
        }
        for (index, name) in dto.exerciseNames.enumerated() {
            let exerciseName = name
            let exercise = try? context.fetch(
                FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == exerciseName })
            ).first
            guard let exercise else { continue }
            let entry = RoutineExercise(
                routine: routine,
                exercise: exercise,
                order: index
            )
            context.insert(entry)
        }
    }

    private func deleteRoutine(id: UUID, in context: ModelContext) {
        let descriptor = FetchDescriptor<Routine>(predicate: #Predicate { $0.id == id })
        if let routine = try? context.fetch(descriptor).first {
            context.delete(routine)
        }
    }

    // MARK: - 送信路（reachable なら sendMessage / 不可なら transferUserInfo）

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
            session.sendMessage(payload, replyHandler: nil) { _ in
                // 失敗時は queueing で再送
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
        #endif
    }
}

// MARK: - JSON encoder / decoder で Date を ISO8601 で扱う

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
private final class WCSessionDelegateAdapter: NSObject, WCSessionDelegate {

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
        decodeAndDispatch(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        decodeAndDispatch(userInfo)
    }

    private func decodeAndDispatch(_ payload: [String: Any]) {
        guard payload["type"] as? String == "oikomi.sync" else { return }
        guard let data = payload["data"] as? Data else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope: SyncEnvelope
        do {
            envelope = try decoder.decode(SyncEnvelope.self, from: data)
        } catch {
            print("WCSyncBridge decode failed: \(error)")
            return
        }
        Task { @MainActor in
            WCSyncBridge.shared.didReceive(envelope: envelope)
        }
    }
}
#endif

import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("SyncDTO + Envelope")
struct SyncDTOTests {

    @Test("WorkoutSessionDTO は encode → decode で同値")
    func sessionRoundTrip() throws {
        // ISO8601 strategy は小数秒を落とすので、テストは秒精度の Date で構築
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_700_003_600)
        let dto = WorkoutSessionDTO(
            id: UUID(),
            startedAt: start,
            endedAt: end,
            routineId: UUID(),
            notes: "test"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(dto)
        let decoded = try decoder.decode(WorkoutSessionDTO.self, from: data)
        #expect(decoded == dto)
    }

    @Test("RoutineDTO は exercises (計画情報) を含む round-trip で全フィールドを保持")
    func routineDTORoundTripWithPlannedFields() throws {
        let dto = RoutineDTO(
            id: UUID(),
            name: "プッシュ",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastUsedAt: Date(timeIntervalSince1970: 1_700_001_000),
            exerciseNames: ["ベンチプレス", "スクワット"],
            exercises: [
                RoutineExerciseDTO(
                    exerciseName: "ベンチプレス",
                    order: 0,
                    plannedSets: 5,
                    plannedReps: 5,
                    plannedWeight: 80
                ),
                RoutineExerciseDTO(
                    exerciseName: "スクワット",
                    order: 1,
                    plannedSets: 3,
                    plannedReps: 10,
                    plannedWeight: 100
                ),
            ]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(dto)
        let decoded = try decoder.decode(RoutineDTO.self, from: data)
        #expect(decoded == dto)
        #expect(decoded.exercises?.count == 2)
        #expect(decoded.exercises?[0].plannedWeight == 80)
        #expect(decoded.exercises?[1].plannedReps == 10)
    }

    @Test("RoutineDTO は exerciseNames のみの旧形式 JSON も decode できる (legacy compat)")
    func routineDTODecodeWithoutNewField_legacyCompat() throws {
        // 旧バイナリが送ってきた JSON: exercises キーなし
        let json = """
            {
                "id": "11111111-1111-1111-1111-111111111111",
                "name": "プッシュ",
                "createdAt": "2024-01-01T00:00:00Z",
                "exerciseNames": ["ベンチプレス", "スクワット"]
            }
            """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RoutineDTO.self, from: Data(json.utf8))
        #expect(decoded.exerciseNames == ["ベンチプレス", "スクワット"])
        #expect(decoded.exercises == nil)
    }

    @Test("RoutineExerciseDTO は plannedRestSeconds を保持して round-trip")
    func routineExerciseDTOPreservesPlannedRestSeconds() throws {
        let dto = RoutineExerciseDTO(
            exerciseName: "ベンチプレス",
            order: 0,
            plannedSets: 4,
            plannedReps: 6,
            plannedWeight: 90,
            plannedRestSeconds: 240
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(dto)
        let decoded = try decoder.decode(RoutineExerciseDTO.self, from: data)
        #expect(decoded == dto)
        #expect(decoded.plannedRestSeconds == 240)
    }

    @Test("RoutineExerciseDTO は plannedRestSeconds 欠落 JSON も decode 可能")
    func routineExerciseDTODecodeWithoutRestSeconds_legacyCompat() throws {
        let json = """
            {
                "exerciseName": "ベンチプレス",
                "order": 0,
                "plannedSets": 3,
                "plannedReps": 8
            }
            """
        let decoded = try JSONDecoder().decode(RoutineExerciseDTO.self, from: Data(json.utf8))
        #expect(decoded.plannedRestSeconds == nil)
        #expect(decoded.plannedWeight == nil)
    }

    @Test("SetRecordDTO は encode → decode で同値")
    func setRoundTrip() throws {
        let dto = SetRecordDTO(
            id: UUID(),
            sessionId: UUID(),
            exerciseName: "ベンチプレス",
            order: 2,
            weight: 80,
            reps: 8,
            durationSeconds: nil,
            isWarmup: false,
            completedAt: Date(timeIntervalSince1970: 1_700_001_000)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(dto)
        let decoded = try decoder.decode(SetRecordDTO.self, from: data)
        #expect(decoded == dto)
    }

    @Test("SyncEnvelope は kind と body をすべて保持")
    func envelopeRoundTrip() throws {
        let envelope = SyncEnvelope(
            kind: .sessionUpsert,
            sessions: [
                WorkoutSessionDTO(id: UUID(), startedAt: Date())
            ],
            routines: [
                RoutineDTO(id: UUID(), name: "プッシュ", createdAt: Date(), exerciseNames: ["ベンチプレス"])
            ]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(envelope)
        let decoded = try decoder.decode(SyncEnvelope.self, from: data)
        #expect(decoded.kind == .sessionUpsert)
        #expect(decoded.sessions.count == 1)
        #expect(decoded.routines.first?.name == "プッシュ")
    }

    @Test("bulkDelete envelope は kind を保持して body は空")
    func bulkDeleteEnvelopeRoundTrip() throws {
        let envelope = SyncEnvelope(kind: .bulkDelete)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(envelope)
        let decoded = try decoder.decode(SyncEnvelope.self, from: data)
        #expect(decoded.kind == .bulkDelete)
        #expect(decoded.sessions.isEmpty)
        #expect(decoded.sets.isEmpty)
        #expect(decoded.routines.isEmpty)
        #expect(decoded.deletedRoutineIds.isEmpty)
    }
}

@Suite("WorkoutSession → DTO 変換")
@MainActor
struct ModelToDTOTests {

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test("WorkoutSession.makeDTO は id/startedAt/routineId を反映")
    func sessionToDTO() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let routineRepo = RoutineRepository(context: context)
        let routine = try routineRepo.createRoutine(name: "プッシュ", exercises: [bench])

        let sessionRepo = WorkoutSessionRepository(context: context)
        let session = try sessionRepo.startSession(
            routine: routine,
            startLiveActivity: false,
            fetchHealthSnapshot: false
        )

        let dto = session.makeDTO()
        #expect(dto.id == session.id)
        #expect(dto.routineId == routine.id)
        #expect(dto.endedAt == nil)
    }

    @Test("SetRecord.makeDTO は exerciseName と sessionId を反映")
    func setToDTO() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let sessionRepo = WorkoutSessionRepository(context: context)
        let session = try sessionRepo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false
        )
        let set = try sessionRepo.addSet(to: session, exercise: bench, weight: 80, reps: 8)
        let dto = set.makeDTO()
        #expect(dto?.exerciseName == "ベンチプレス")
        #expect(dto?.sessionId == session.id)
        #expect(dto?.weight == 80)
        #expect(dto?.reps == 8)
    }

    @Test("Routine.makeDTO は exerciseNames を順序通り返す")
    func routineToDTO() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let squat = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "スクワット" }!

        let routineRepo = RoutineRepository(context: context)
        let routine = try routineRepo.createRoutine(
            name: "Mix",
            exercises: [bench, squat]
        )
        let dto = routine.makeDTO()
        #expect(dto.exerciseNames == ["ベンチプレス", "スクワット"])
    }

    @Test("Routine.makeDTO は plannedSets/Reps/Weight を exercises に乗せる")
    func routineMakeDTO_planFieldsPropagated() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let squat = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "スクワット" }!

        let routineRepo = RoutineRepository(context: context)
        let routine = try routineRepo.createRoutine(
            name: "プッシュ",
            exercises: [bench, squat]
        )
        // 既定値で作成されている entries の plan を上書きする
        let ordered = routine.orderedExercises
        ordered[0].plannedSets = 5
        ordered[0].plannedReps = 5
        ordered[0].plannedWeight = 80
        ordered[1].plannedSets = 3
        ordered[1].plannedReps = 10
        ordered[1].plannedWeight = 100
        try context.save()

        let dto = routine.makeDTO()
        #expect(dto.exercises?.count == 2)
        #expect(dto.exercises?[0].exerciseName == "ベンチプレス")
        #expect(dto.exercises?[0].plannedSets == 5)
        #expect(dto.exercises?[0].plannedReps == 5)
        #expect(dto.exercises?[0].plannedWeight == 80)
        #expect(dto.exercises?[1].plannedWeight == 100)
        // 既存テスト互換: exerciseNames も併送される
        #expect(dto.exerciseNames == ["ベンチプレス", "スクワット"])
    }
}

@Suite("WCSyncBridge handleEnvelope (受信側ロジック)")
@MainActor
struct WCSyncBridgeReceiveTests {

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test("routineUpsert で exercises が来たら RoutineExercise.plannedSets/Reps/Weight に反映")
    func upsertRoutine_appliesPlannedFields_fromExercisesDTO() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        WCSyncBridge.shared.activate(contextProvider: { context })

        let routineId = UUID()
        let dto = RoutineDTO(
            id: routineId,
            name: "プッシュ",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            exerciseNames: ["ベンチプレス", "スクワット"],
            exercises: [
                RoutineExerciseDTO(
                    exerciseName: "ベンチプレス",
                    order: 0,
                    plannedSets: 5,
                    plannedReps: 5,
                    plannedWeight: 80
                ),
                RoutineExerciseDTO(
                    exerciseName: "スクワット",
                    order: 1,
                    plannedSets: 3,
                    plannedReps: 10,
                    plannedWeight: 100
                ),
            ]
        )
        WCSyncBridge.shared.handleEnvelope(
            SyncEnvelope(kind: .routineUpsert, routines: [dto])
        )

        let stored = try context.fetch(
            FetchDescriptor<Routine>(predicate: #Predicate { $0.id == routineId })
        ).first
        #expect(stored != nil)
        let entries = stored?.orderedExercises ?? []
        #expect(entries.count == 2)
        #expect(entries[0].exercise?.name == "ベンチプレス")
        #expect(entries[0].plannedSets == 5)
        #expect(entries[0].plannedReps == 5)
        #expect(entries[0].plannedWeight == 80)
        #expect(entries[1].plannedSets == 3)
        #expect(entries[1].plannedReps == 10)
        #expect(entries[1].plannedWeight == 100)
    }

    @Test("routineUpsert: 受信側に無い種目は definition から復元され脱落しない")
    func upsertRoutine_recreatesMissingExercise_fromDefinition() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()  // 「ベンチプレス」はシード済み・カスタムは未存在
        WCSyncBridge.shared.activate(contextProvider: { context })

        let routineId = UUID()
        let customDefinition = ExerciseDefinitionDTO(
            name: "オリジナルカール",
            nameEn: "",
            muscleGroupRawValues: [MuscleGroup.biceps.rawValue],
            equipmentRawValue: Equipment.dumbbell.rawValue,
            locationRawValues: [Location.home.rawValue],
            measurementTypeRawValue: MeasurementType.weightReps.rawValue,
            defaultRestSeconds: 60,
            isCustom: true
        )
        let dto = RoutineDTO(
            id: routineId,
            name: "腕の日",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            exerciseNames: ["ベンチプレス", "オリジナルカール"],
            exercises: [
                RoutineExerciseDTO(
                    exerciseName: "ベンチプレス", order: 0, plannedSets: 3, plannedReps: 8),
                RoutineExerciseDTO(
                    exerciseName: "オリジナルカール",
                    order: 1,
                    plannedSets: 3,
                    plannedReps: 12,
                    plannedWeight: 10,
                    definition: customDefinition
                ),
            ]
        )
        WCSyncBridge.shared.handleEnvelope(
            SyncEnvelope(kind: .routineUpsert, routines: [dto])
        )

        let stored = try context.fetch(
            FetchDescriptor<Routine>(predicate: #Predicate { $0.id == routineId })
        ).first
        let entries = stored?.orderedExercises ?? []
        #expect(entries.count == 2)  // 旧実装ではここが 1 に脱落していた
        #expect(entries[1].exercise?.name == "オリジナルカール")
        #expect(entries[1].exercise?.isCustom == true)
        #expect(entries[1].exercise?.equipment == .dumbbell)

        // 種目マスタにも復元され、以後の照合で見つかる
        let recreated = try context.fetch(
            FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.name == "オリジナルカール" })
        ).first
        #expect(recreated != nil)
    }

    @Test("routineUpsert: definition も同名種目も無い旧形式エントリはスキップ（既存挙動維持）")
    func upsertRoutine_skipsEntry_whenNoExerciseAndNoDefinition() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        WCSyncBridge.shared.activate(contextProvider: { context })

        let routineId = UUID()
        let dto = RoutineDTO(
            id: routineId,
            name: "壊れた同期",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            exerciseNames: ["ベンチプレス", "存在しない種目"],
            exercises: [
                RoutineExerciseDTO(
                    exerciseName: "ベンチプレス", order: 0, plannedSets: 3, plannedReps: 8),
                RoutineExerciseDTO(
                    exerciseName: "存在しない種目", order: 1, plannedSets: 3, plannedReps: 8),
            ]
        )
        WCSyncBridge.shared.handleEnvelope(
            SyncEnvelope(kind: .routineUpsert, routines: [dto])
        )

        let stored = try context.fetch(
            FetchDescriptor<Routine>(predicate: #Predicate { $0.id == routineId })
        ).first
        #expect((stored?.orderedExercises ?? []).count == 1)
    }

    @Test("routineUpsert で exercises が nil の旧形式は exerciseNames + デフォルト値で再構築")
    func upsertRoutine_fallsBackToExerciseNames_whenExercisesNil() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        WCSyncBridge.shared.activate(contextProvider: { context })

        let routineId = UUID()
        let dto = RoutineDTO(
            id: routineId,
            name: "プル",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            exerciseNames: ["デッドリフト"],
            exercises: nil
        )
        WCSyncBridge.shared.handleEnvelope(
            SyncEnvelope(kind: .routineUpsert, routines: [dto])
        )

        let stored = try context.fetch(
            FetchDescriptor<Routine>(predicate: #Predicate { $0.id == routineId })
        ).first
        let entries = stored?.orderedExercises ?? []
        #expect(entries.count == 1)
        #expect(entries[0].exercise?.name == "デッドリフト")
        // RoutineExercise.init のデフォルト値で再構築されること
        #expect(entries[0].plannedSets == 3)
        #expect(entries[0].plannedReps == 8)
        #expect(entries[0].plannedWeight == nil)
    }

    @Test("startSession で routine の planned* がローカル SetRecord に展開される")
    func startSession_expandsPlannedSetsLocally() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        WCSyncBridge.shared.activate(contextProvider: { context })

        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let squat = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "スクワット" }!
        let routine = try RoutineRepository(context: context).createRoutine(
            name: "プッシュ",
            exercises: [bench, squat]
        )
        // 既定値: 各種目 3 セット → 合計 6 セット
        let session = try WorkoutSessionRepository(context: context).startSession(
            routine: routine,
            startLiveActivity: false,
            fetchHealthSnapshot: false
        )
        #expect(session.orderedSets.count == 6)
        #expect(session.orderedSets.allSatisfy { $0.isCompleted == false })
    }

    @Test("sessionUpsert envelope の sets 配列は受信側で SetRecord として保存される")
    func upsertSession_carriesSetsArray() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        WCSyncBridge.shared.activate(contextProvider: { context })

        let sessionId = UUID()
        let sessionDTO = WorkoutSessionDTO(id: sessionId, startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let setDTO = SetRecordDTO(
            id: UUID(),
            sessionId: sessionId,
            exerciseName: "ベンチプレス",
            order: 0,
            weight: 80,
            reps: 5,
            completedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isCompleted: false
        )
        WCSyncBridge.shared.handleEnvelope(
            SyncEnvelope(
                kind: .sessionUpsert,
                sessions: [sessionDTO],
                sets: [setDTO]
            )
        )

        let stored = try context.fetch(
            FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == sessionId })
        ).first
        #expect(stored != nil)
        let sets = stored?.orderedSets ?? []
        #expect(sets.count == 1)
        #expect(sets.first?.exercise?.name == "ベンチプレス")
        #expect(sets.first?.weight == 80)
        #expect(sets.first?.reps == 5)
        #expect(sets.first?.isCompleted == false)
    }

    // MARK: - restTimerStart clock skew correction

    /// envelope.timestamp と受信時刻のずれ（送信側時計が遅れている / 配送遅延）を受信側で吸収し、
    /// userInfo["endAt"] に「受信側ローカル時計基準の endAt」が載ることを確認。
    @Test("restTimerStart: 送信から 5 秒経過した envelope は受信時刻 + 残り 55 秒で復元")
    func restTimerStart_correctsForClockSkew() throws {
        let context = try Self.makeContext()
        WCSyncBridge.shared.activate(contextProvider: { context })
        WCSyncBridge.shared._resetRestTimerStateForTesting()

        let totalMarker = 60_001
        let senderNow = Date().addingTimeInterval(-5)
        let senderEndAt = senderNow.addingTimeInterval(60)
        let envelope = SyncEnvelope(
            kind: .restTimerStart,
            timestamp: senderNow,
            restEndAt: senderEndAt,
            restTotalSeconds: totalMarker
        )

        let outcome = observeRestTimerStartEndAt(marker: totalMarker) {
            WCSyncBridge.shared.handleEnvelope(envelope)
        }

        let inner = try #require(outcome, "通知が受信されていない")
        let endAt = try #require(inner, "endAt キーが userInfo にない")
        let remaining = endAt.timeIntervalSinceNow
        #expect(abs(remaining - 55) < 1.0, "remaining=\(remaining) expected ≈55")
    }

    /// 配送遅延が rest 全長を超えた envelope（例: transferUserInfo で 120s 遅延、rest 60s）は
    /// expired として扱い、userInfo["endAt"] キーごと省略される。
    @Test("restTimerStart: 配送遅延 > rest 全長は expired として endAt キーを省略")
    func restTimerStart_skipsWhenLatencyExceedsRest() throws {
        let context = try Self.makeContext()
        WCSyncBridge.shared.activate(contextProvider: { context })
        WCSyncBridge.shared._resetRestTimerStateForTesting()

        let totalMarker = 60_002
        let senderNow = Date().addingTimeInterval(-120)
        let senderEndAt = senderNow.addingTimeInterval(60)
        let envelope = SyncEnvelope(
            kind: .restTimerStart,
            timestamp: senderNow,
            restEndAt: senderEndAt,
            restTotalSeconds: totalMarker
        )

        let outcome = observeRestTimerStartEndAt(marker: totalMarker) {
            WCSyncBridge.shared.handleEnvelope(envelope)
        }

        let inner = try #require(outcome, "通知が受信されていない")
        #expect(inner == nil, "expired のため endAt キーは無いはず")
    }

    /// 配送遅延ほぼゼロの fresh envelope はリグレッション保護として
    /// userInfo["endAt"] ≈ Date() + 90s で来ること。
    @Test("restTimerStart: 配送遅延ほぼゼロなら受信時刻 + rest 全長で復元（リグレッション保護）")
    func restTimerStart_handlesFreshEnvelope() throws {
        let context = try Self.makeContext()
        WCSyncBridge.shared.activate(contextProvider: { context })
        WCSyncBridge.shared._resetRestTimerStateForTesting()

        let totalMarker = 60_003
        let senderNow = Date()
        let senderEndAt = senderNow.addingTimeInterval(90)
        let envelope = SyncEnvelope(
            kind: .restTimerStart,
            timestamp: senderNow,
            restEndAt: senderEndAt,
            restTotalSeconds: totalMarker
        )

        let outcome = observeRestTimerStartEndAt(marker: totalMarker) {
            WCSyncBridge.shared.handleEnvelope(envelope)
        }

        let inner = try #require(outcome, "通知が受信されていない")
        let endAt = try #require(inner, "endAt キーが userInfo にない")
        let remaining = endAt.timeIntervalSinceNow
        #expect(abs(remaining - 90) < 1.0, "remaining=\(remaining) expected ≈90")
    }

    /// `dataDidChangeNotification` を 1 回だけ同期的に受け取り、userInfo["endAt"] (Date?) を返すヘルパー。
    /// nil の場合は expired（キー欠落）として扱う。
    /// `queue: nil` で post と同じスレッドで observer が同期実行される（MainActor 上）ため、
    /// trigger() 完了後にすでに continuation が resume された状態になる。
    private func observeRestTimerStartEndAt(
        marker totalSeconds: Int,
        _ trigger: () -> Void
    ) -> Date?? {
        nonisolated(unsafe) var captured: Date??
        let observer = NotificationCenter.default.addObserver(
            forName: WCSyncBridge.dataDidChangeNotification,
            object: nil,
            queue: nil
        ) { note in
            guard
                let kind = note.userInfo?["kind"] as? String,
                kind == SyncEnvelope.Kind.restTimerStart.rawValue
            else { return }
            // 並列テストで別 envelope の通知を拾わないよう totalSeconds でマーカ照合。
            guard (note.userInfo?["totalSeconds"] as? Int) == totalSeconds else { return }
            guard captured == nil else { return }
            captured = .some(note.userInfo?["endAt"] as? Date)
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        trigger()
        return captured
    }
}

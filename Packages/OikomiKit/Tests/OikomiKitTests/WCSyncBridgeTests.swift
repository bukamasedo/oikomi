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
}

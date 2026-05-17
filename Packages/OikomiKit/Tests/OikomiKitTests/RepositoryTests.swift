import Foundation
import SwiftData
import Testing
@testable import OikomiKit

@Suite("Repositories")
@MainActor
struct RepositoryTests {

    /// インメモリ ModelContext を作成（ディスクに書き出さないテスト用）
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

    @Test("seedIfNeeded: 初回は全種目を投入する")
    func seedFirstTime() throws {
        let context = try Self.makeContext()
        let repo = ExerciseRepository(context: context)

        try repo.seedIfNeeded()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == SeedData.starterExercises.count)
        #expect(exercises.count >= 30)  // v0.1 で 30 種目以上
        #expect(exercises.contains { $0.name == "ベンチプレス" })
        #expect(exercises.contains { $0.name == "スクワット" })
        #expect(exercises.contains { $0.name == "プランク" })  // 時間計測種目
    }

    @Test("seedIfNeeded: 既存データがあれば再投入しない（冪等）")
    func seedIsIdempotent() throws {
        let context = try Self.makeContext()
        let repo = ExerciseRepository(context: context)

        try repo.seedIfNeeded()
        try repo.seedIfNeeded()  // 2回目

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == SeedData.starterExercises.count)
    }

    @Test("startSession + addSet + finishSession の一連")
    func workoutFlow() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()

        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try sessionRepo.startSession()
        #expect(session.endedAt == nil)
        #expect(session.sets?.isEmpty == true)

        _ = try sessionRepo.addSet(to: session, exercise: bench, weight: 80, reps: 8)
        _ = try sessionRepo.addSet(to: session, exercise: bench, weight: 80, reps: 7)
        _ = try sessionRepo.addSet(to: session, exercise: bench, weight: 80, reps: 6)

        try sessionRepo.finishSession(session)

        let stored = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(stored.count == 1)
        #expect(stored.first?.sets?.count == 3)
        #expect(stored.first?.endedAt != nil)
    }

    @Test("addSet: order は 0 から連番で振られる")
    func addSetOrderIsSequential() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()
        let exercise = try context.fetch(FetchDescriptor<Exercise>()).first!

        let session = try sessionRepo.startSession()
        let s1 = try sessionRepo.addSet(to: session, exercise: exercise, weight: 60, reps: 10)
        let s2 = try sessionRepo.addSet(to: session, exercise: exercise, weight: 60, reps: 10)
        let s3 = try sessionRepo.addSet(to: session, exercise: exercise, weight: 60, reps: 10)

        #expect(s1.order == 0)
        #expect(s2.order == 1)
        #expect(s3.order == 2)
    }

    @Test("addSet: 推定1RMが自動計算される")
    func addSetCalculatesOneRepMax() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()
        let exercise = try context.fetch(FetchDescriptor<Exercise>()).first!

        let session = try sessionRepo.startSession()
        let set = try sessionRepo.addSet(to: session, exercise: exercise, weight: 100, reps: 5)

        // Epley: 100 × (1 + 5/30) ≈ 116.67
        #expect(set.estimated1RM != nil)
        #expect(abs(set.estimated1RM! - 116.667) < 0.01)
    }

    @Test("startSessionByCopying: ルーティンと全セットを複製")
    func copySession() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let routineRepo = RoutineRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()

        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let squat = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "スクワット" }!

        let routine = try routineRepo.createRoutine(name: "プッシュ", exercises: [bench])

        let source = try sessionRepo.startSession(routine: routine)
        try sessionRepo.addSet(to: source, exercise: bench, weight: 80, reps: 8)
        try sessionRepo.addSet(to: source, exercise: bench, weight: 80, reps: 7)
        try sessionRepo.addSet(to: source, exercise: squat, weight: 100, reps: 5)
        try sessionRepo.finishSession(source)

        let copied = try sessionRepo.startSessionByCopying(source)

        #expect(copied.id != source.id)
        #expect(copied.routine?.id == routine.id)
        #expect(copied.endedAt == nil)
        #expect(copied.sets?.count == 3)
        let ordered = copied.orderedSets
        #expect(ordered[0].exercise?.id == bench.id)
        #expect(ordered[0].weight == 80)
        #expect(ordered[0].reps == 8)
        #expect(ordered[2].exercise?.id == squat.id)
    }

    @Test("addCustomExercise: isCustom=true で保存される")
    func addCustomExercise() throws {
        let context = try Self.makeContext()
        let repo = ExerciseRepository(context: context)

        let custom = try repo.addCustomExercise(
            name: "ブルガリアンスクワット",
            muscleGroups: [.quads, .glutes],
            equipment: .dumbbell
        )

        #expect(custom.isCustom == true)
        #expect(custom.muscleGroups.contains(.quads))
    }
}

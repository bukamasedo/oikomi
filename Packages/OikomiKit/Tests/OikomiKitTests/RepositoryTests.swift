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
        #expect(exercises.count >= 100)  // 仕様書§4.1.4 の v1.0 目標 100 種達成
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

    @Test("ensureSeedExercisesPresent: 空DBで全シード種目を投入する")
    func ensureSeedFreshDB() throws {
        let context = try Self.makeContext()
        let repo = ExerciseRepository(context: context)

        try repo.ensureSeedExercisesPresent()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == SeedData.starterExercises.count)
        #expect(exercises.count >= 800)  // free-exercise-db v1 取り込みで 873 種に拡充
        #expect(exercises.contains { $0.nameEn == "Hamstring Stretch" })  // stretching 追加分
        #expect(exercises.contains { $0.nameEn == "Stairmaster" })  // cardio 追加分
    }

    @Test("ensureSeedExercisesPresent: 2回呼んでも重複追加しない（冪等）")
    func ensureSeedIdempotent() throws {
        let context = try Self.makeContext()
        let repo = ExerciseRepository(context: context)

        try repo.ensureSeedExercisesPresent()
        try repo.ensureSeedExercisesPresent()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == SeedData.starterExercises.count)
    }

    @Test("ensureSeedExercisesPresent: 部分的に投入済みでも不足分のみ追加する（差分シード）")
    func ensureSeedAddsMissingOnly() throws {
        let context = try Self.makeContext()
        let repo = ExerciseRepository(context: context)

        // 既存ユーザーを模擬: starterExercises の先頭 50 件だけを投入
        let preexisting = Array(SeedData.starterExercises.prefix(50))
        for seed in preexisting {
            context.insert(seed.makeExercise())
        }
        try context.save()

        try repo.ensureSeedExercisesPresent()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == SeedData.starterExercises.count)
        let nameEnSet = Set(exercises.map(\.nameEn))
        #expect(nameEnSet.count == exercises.count)  // 重複なし
    }

    @Test("startSession + addSet + finishSession の一連")
    func workoutFlow() async throws {
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

        try await sessionRepo.finishSession(session, writeToHealthKit: false)

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
    func copySession() async throws {
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
        try await sessionRepo.finishSession(source, writeToHealthKit: false)

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

    @Test("startSession(routine:) ルーティンの plannedSets を未完了セットに展開")
    func startSessionExpandsPlannedSets() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let routineRepo = RoutineRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()

        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let squat = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "スクワット" }!

        let routine = try routineRepo.createRoutine(name: "プッシュ脚", exercises: [bench, squat])
        // RoutineExercise の plannedSets デフォルトは 3 なので合計 6 セット展開される想定
        let session = try sessionRepo.startSession(routine: routine)

        let sets = session.orderedSets
        #expect(sets.count == 6)
        #expect(sets.allSatisfy { !$0.isCompleted })
        // 順序保証: ベンチ x3 → スクワット x3
        #expect(sets[0].exercise?.id == bench.id)
        #expect(sets[2].exercise?.id == bench.id)
        #expect(sets[3].exercise?.id == squat.id)
        #expect(sets[5].exercise?.id == squat.id)
        #expect(sets.map(\.order) == [0, 1, 2, 3, 4, 5])
    }

    @Test("markSetCompleted: isCompleted=true + 推定1RM + restEndAt を返す")
    func markSetCompletedFlow() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()

        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try sessionRepo.startSession()
        let planned = try sessionRepo.addPlannedSet(to: session, exercise: bench, weight: 80, reps: 8)
        #expect(planned.isCompleted == false)
        #expect(planned.estimated1RM == nil)

        let endAt = try sessionRepo.markSetCompleted(planned)

        #expect(planned.isCompleted == true)
        #expect(planned.estimated1RM != nil)
        #expect(abs(planned.estimated1RM! - 80 * (1 + 8.0 / 30)) < 0.01)
        // ベンチプレスの defaultRestSeconds = 180 で restEndAt が返る
        #expect(endAt != nil)
        if let endAt {
            let delta = endAt.timeIntervalSinceNow
            #expect(delta > 170 && delta <= 181)
        }
    }

    @Test("markSetCompleted: actualWeight/Reps で実績を上書きできる")
    func markSetCompletedWithOverride() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()

        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let session = try sessionRepo.startSession()
        let planned = try sessionRepo.addPlannedSet(to: session, exercise: bench, weight: 80, reps: 8)

        _ = try sessionRepo.markSetCompleted(planned, actualWeight: 85, actualReps: 6)

        #expect(planned.weight == 85)
        #expect(planned.reps == 6)
        #expect(planned.isCompleted)
    }

    @Test("toggleFavorite: isFavorite が反転して永続化される")
    func toggleFavoriteFlips() throws {
        let context = try Self.makeContext()
        let repo = ExerciseRepository(context: context)
        try repo.ensureSeedExercisesPresent()

        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        #expect(bench.isFavorite == false)

        try repo.toggleFavorite(bench)
        #expect(bench.isFavorite == true)

        try repo.toggleFavorite(bench)
        #expect(bench.isFavorite == false)
    }

    @Test("addSet（既存パス）は isCompleted=true のまま後方互換")
    func legacyAddSetStaysCompleted() throws {
        let context = try Self.makeContext()
        let exerciseRepo = ExerciseRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)
        try exerciseRepo.seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try sessionRepo.startSession()
        let set = try sessionRepo.addSet(to: session, exercise: bench, weight: 80, reps: 8)

        #expect(set.isCompleted == true)
    }
}

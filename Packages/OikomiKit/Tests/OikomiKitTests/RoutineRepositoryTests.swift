import Foundation
import SwiftData
import Testing
@testable import OikomiKit

@Suite("RoutineRepository")
@MainActor
struct RoutineRepositoryTests {

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

    private static func seededExercises(in context: ModelContext) throws -> [Exercise] {
        let repo = ExerciseRepository(context: context)
        try repo.seedIfNeeded()
        return try context.fetch(FetchDescriptor<Exercise>(sortBy: [.init(\Exercise.name)]))
    }

    @Test("createRoutine: 指定種目を順番通りに登録")
    func createRoutineWithExercises() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let repo = RoutineRepository(context: context)

        let routine = try repo.createRoutine(
            name: "プッシュデー",
            exercises: [exercises[0], exercises[1]]
        )

        #expect(routine.name == "プッシュデー")
        let ordered = routine.orderedExercises
        #expect(ordered.count == 2)
        #expect(ordered[0].order == 0)
        #expect(ordered[1].order == 1)
        #expect(ordered[0].exercise?.id == exercises[0].id)
    }

    @Test("addExercise: 末尾に追加され order が連番")
    func addExerciseAppends() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let repo = RoutineRepository(context: context)

        let routine = try repo.createRoutine(name: "テスト", exercises: [exercises[0]])
        try repo.addExercise(to: routine, exercise: exercises[1])
        try repo.addExercise(to: routine, exercise: exercises[2])

        let ordered = routine.orderedExercises
        #expect(ordered.count == 3)
        #expect(ordered.map(\.order) == [0, 1, 2])
    }

    @Test("removeExercise: 削除後 order が詰められる")
    func removeExerciseRepacksOrder() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let repo = RoutineRepository(context: context)

        let routine = try repo.createRoutine(
            name: "test",
            exercises: [exercises[0], exercises[1], exercises[2], exercises[3]]
        )

        // index 1（2番目）を削除
        let toRemove = routine.orderedExercises[1]
        try repo.removeExercise(toRemove)

        let after = routine.orderedExercises
        #expect(after.count == 3)
        #expect(after.map(\.order) == [0, 1, 2])
    }

    @Test("reorderExercises: 任意順に並べ替え可能")
    func reorderExercises() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let repo = RoutineRepository(context: context)

        let routine = try repo.createRoutine(
            name: "test",
            exercises: [exercises[0], exercises[1], exercises[2]]
        )

        let initial = routine.orderedExercises
        // 逆順に
        let reversedIds = initial.reversed().map(\.id)
        try repo.reorderExercises(in: routine, orderedIds: reversedIds)

        let after = routine.orderedExercises
        #expect(after[0].id == initial[2].id)
        #expect(after[2].id == initial[0].id)
    }

    @Test("markUsed: lastUsedAt が更新される")
    func markUsed() throws {
        let context = try Self.makeContext()
        let repo = RoutineRepository(context: context)

        let routine = try repo.createRoutine(name: "test")
        #expect(routine.lastUsedAt == nil)

        try repo.markUsed(routine)
        #expect(routine.lastUsedAt != nil)
    }

    @Test("startSession with routine: lastUsedAtが更新されsession.routineが設定される")
    func startSessionWithRoutine() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let routineRepo = RoutineRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)

        let routine = try routineRepo.createRoutine(
            name: "プッシュデー",
            exercises: [exercises[0]]
        )
        #expect(routine.lastUsedAt == nil)

        let session = try sessionRepo.startSession(routine: routine)
        #expect(session.routine?.id == routine.id)
        #expect(routine.lastUsedAt != nil)
        #expect(routine.sessions?.count == 1)
    }

    @Test("deleteRoutine: cascade で RoutineExercise も削除")
    func deleteRoutineCascades() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let repo = RoutineRepository(context: context)

        let routine = try repo.createRoutine(
            name: "test",
            exercises: [exercises[0], exercises[1]]
        )

        let countBefore = try context.fetchCount(FetchDescriptor<RoutineExercise>())
        #expect(countBefore == 2)

        try repo.deleteRoutine(routine)

        let routineCount = try context.fetchCount(FetchDescriptor<Routine>())
        let entryCount = try context.fetchCount(FetchDescriptor<RoutineExercise>())
        #expect(routineCount == 0)
        #expect(entryCount == 0)
    }
}

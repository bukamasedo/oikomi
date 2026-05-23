import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("WorkoutSessionRepository.lastCompletedSet")
@MainActor
struct WorkoutSessionRepositoryTests {

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

    @Test("最終完了セットが completedAt 降順で返る")
    func returnsLatestCompleted() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        let base = Date()
        _ = try repo.addSet(
            to: session, exercise: target, weight: 50, reps: 10,
            completedAt: base.addingTimeInterval(-200)
        )
        _ = try repo.addSet(
            to: session, exercise: target, weight: 60, reps: 8,
            completedAt: base.addingTimeInterval(-100)
        )
        _ = try repo.addSet(
            to: session, exercise: target, weight: 65, reps: 6,
            completedAt: base
        )

        let latest = try repo.lastCompletedSet(for: target)
        #expect(latest?.weight == 65)
        #expect(latest?.reps == 6)
    }

    @Test("対象種目の履歴が無ければ nil")
    func returnsNilWhenNoHistory() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        _ = try repo.addSet(
            to: session, exercise: exercises[0], weight: 50, reps: 10
        )

        let result = try repo.lastCompletedSet(for: exercises[1])
        #expect(result == nil)
    }

    @Test("未完了 (計画) セットは除外")
    func excludesPlannedSets() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        _ = try repo.addPlannedSet(
            to: session, exercise: target, weight: 80, reps: 5
        )

        let result = try repo.lastCompletedSet(for: target)
        #expect(result == nil)
    }

    @Test("ウォームアップセットは除外")
    func excludesWarmupSets() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        _ = try repo.addSet(
            to: session, exercise: target, weight: 20, reps: 10, isWarmup: true
        )

        let result = try repo.lastCompletedSet(for: target)
        #expect(result == nil)
    }
}

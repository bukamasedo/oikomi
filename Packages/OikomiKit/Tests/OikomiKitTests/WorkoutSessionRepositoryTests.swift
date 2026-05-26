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

    @Test("markSetCompleted: Routine 上書きを優先")
    func usesRoutineOverrideForRest() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        target.defaultRestSeconds = 90
        let routineRepo = RoutineRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)

        let routine = try routineRepo.createRoutine(name: "test")
        try routineRepo.addExercise(
            to: routine,
            exercise: target,
            plannedSets: 1,
            plannedReps: 8,
            plannedWeight: nil,
            plannedRestSeconds: 180
        )

        let session = try sessionRepo.startSession(
            routine: routine,
            startLiveActivity: false,
            fetchHealthSnapshot: false
        )
        let plannedSet = session.orderedSets.first!
        let completedAt = Date()
        let endAt = try sessionRepo.markSetCompleted(plannedSet, completedAt: completedAt)
        let interval = endAt!.timeIntervalSince(completedAt)
        #expect(abs(interval - 180) < 1)
        #expect(plannedSet.restSeconds == 180)
    }

    @Test("markSetCompleted: 上書き nil なら種目デフォルト")
    func fallsBackToExerciseDefaultRest() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        target.defaultRestSeconds = 75
        let routineRepo = RoutineRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)

        let routine = try routineRepo.createRoutine(name: "test")
        try routineRepo.addExercise(
            to: routine,
            exercise: target,
            plannedSets: 1,
            plannedReps: 5,
            plannedWeight: nil,
            plannedRestSeconds: nil
        )

        let session = try sessionRepo.startSession(
            routine: routine,
            startLiveActivity: false,
            fetchHealthSnapshot: false
        )
        let plannedSet = session.orderedSets.first!
        _ = try sessionRepo.markSetCompleted(plannedSet)
        #expect(plannedSet.restSeconds == 75)
    }

    @Test("markSetCompleted: routine 未紐付きセッションは種目デフォルト")
    func quickStartUsesExerciseDefaultRest() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        target.defaultRestSeconds = 60
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        let plannedSet = try repo.addPlannedSet(
            to: session, exercise: target, weight: 50, reps: 8
        )
        _ = try repo.markSetCompleted(plannedSet)
        #expect(plannedSet.restSeconds == 60)
    }

    @Test("addSet: restSecondsOverride を渡すと SetRecord に保持される")
    func addSetStoresRestOverride() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        target.defaultRestSeconds = 60
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        let set = try repo.addSet(
            to: session, exercise: target, weight: 50, reps: 8,
            restSecondsOverride: 120
        )
        #expect(set.restSecondsOverride == 120)
        #expect(set.resolveRestSeconds() == 120)
    }

    @Test("resolveRestSeconds: override は Exercise.defaultRestSeconds より優先")
    func overrideBeatsExerciseDefault() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        target.defaultRestSeconds = 60
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        let set = try repo.addPlannedSet(
            to: session, exercise: target, weight: 50, reps: 8,
            restSecondsOverride: 30
        )
        #expect(set.resolveRestSeconds() == 30)
    }

    @Test("resolveRestSeconds: override は RoutineExercise.plannedRestSeconds より優先")
    func overrideBeatsRoutinePlanned() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        target.defaultRestSeconds = 60
        let routineRepo = RoutineRepository(context: context)
        let sessionRepo = WorkoutSessionRepository(context: context)

        let routine = try routineRepo.createRoutine(name: "t")
        try routineRepo.addExercise(
            to: routine, exercise: target,
            plannedSets: 1, plannedReps: 8, plannedWeight: nil,
            plannedRestSeconds: 180
        )

        let session = try sessionRepo.startSession(
            routine: routine,
            startLiveActivity: false,
            fetchHealthSnapshot: false
        )
        let plannedSet = session.orderedSets.first!
        try sessionRepo.setRestSecondsOverride(45, on: plannedSet)
        #expect(plannedSet.resolveRestSeconds() == 45)
    }

    @Test("setRestSecondsOverride(nil): 上書きをクリアして fallback に戻る")
    func clearingOverrideRestoresFallback() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let target = exercises[0]
        target.defaultRestSeconds = 90
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        let set = try repo.addSet(
            to: session, exercise: target, weight: 50, reps: 8,
            restSecondsOverride: 30
        )
        try repo.setRestSecondsOverride(nil, on: set)
        #expect(set.restSecondsOverride == nil)
        #expect(set.resolveRestSeconds() == 90)
    }

    @Test("deleteExercise: 該当種目の全セットだけが削除される")
    func deleteExerciseRemovesOnlyThatExerciseSets() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let bench = exercises[0]
        let squat = exercises[1]
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false,
            fetchHealthSnapshot: false,
            expandPlannedSets: false
        )
        _ = try repo.addSet(to: session, exercise: bench, weight: 60, reps: 10)
        _ = try repo.addSet(to: session, exercise: bench, weight: 65, reps: 8)
        _ = try repo.addSet(to: session, exercise: squat, weight: 80, reps: 5)

        let removed = try repo.deleteExercise(bench, from: session)
        #expect(removed == 2)
        #expect(session.sets?.count == 1)
        #expect(session.sets?.first?.exercise?.id == squat.id)
    }

    @Test("deleteExercise: 他セッションには影響しない")
    func deleteExerciseDoesNotTouchOtherSessions() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let bench = exercises[0]
        let repo = WorkoutSessionRepository(context: context)

        let s1 = try repo.startSession(
            startLiveActivity: false, fetchHealthSnapshot: false, expandPlannedSets: false
        )
        _ = try repo.addSet(to: s1, exercise: bench, weight: 60, reps: 10)

        let s2 = try repo.startSession(
            startLiveActivity: false, fetchHealthSnapshot: false, expandPlannedSets: false
        )
        _ = try repo.addSet(to: s2, exercise: bench, weight: 70, reps: 8)

        let removed = try repo.deleteExercise(bench, from: s2)
        #expect(removed == 1)
        #expect(s2.sets?.count == 0)
        #expect(s1.sets?.count == 1)
    }

    @Test("deleteSet: 単一セットだけが消える")
    func deleteSetRemovesOnlyTarget() throws {
        let context = try Self.makeContext()
        let exercises = try Self.seededExercises(in: context)
        let bench = exercises[0]
        let repo = WorkoutSessionRepository(context: context)

        let session = try repo.startSession(
            startLiveActivity: false, fetchHealthSnapshot: false, expandPlannedSets: false
        )
        let first = try repo.addSet(to: session, exercise: bench, weight: 60, reps: 10)
        _ = try repo.addSet(to: session, exercise: bench, weight: 65, reps: 8)
        try repo.deleteSet(first)
        #expect(session.sets?.count == 1)
        #expect(session.sets?.first?.weight == 65)
    }
}

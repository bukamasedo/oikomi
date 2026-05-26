import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("PersonalRecord")
@MainActor
struct PersonalRecordTests {

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

    @Test("addSet: 初回の本セットで PR が自動作成される")
    func firstWorkingSetCreatesPR() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let session = try WorkoutSessionRepository(context: context).startSession()
        try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 80, reps: 8)

        let prs = try context.fetch(FetchDescriptor<PersonalRecord>())
        #expect(prs.count == 1)
        #expect(prs.first?.weight == 80)
        #expect(prs.first?.reps == 8)
    }

    @Test("addSet: より重い PR が出たら更新（複数行作らない）")
    func updatesExistingPR() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()

        try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8)  // 1RM ≈ 101.3
        try repo.addSet(to: session, exercise: bench, weight: 90, reps: 5)  // 1RM ≈ 105.0

        let prs = try context.fetch(FetchDescriptor<PersonalRecord>())
        #expect(prs.count == 1)
        #expect(prs.first?.weight == 90)
        #expect(prs.first?.reps == 5)
    }

    @Test("addSet: ウォームアップは PR 評価対象外")
    func warmupSkipsPR() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()

        try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8, isWarmup: true)

        let prs = try context.fetch(FetchDescriptor<PersonalRecord>())
        #expect(prs.isEmpty)
    }

    @Test("addSet: 既存ベスト以下のセットでは更新されない")
    func lowerSetDoesNotUpdate() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()

        try repo.addSet(to: session, exercise: bench, weight: 100, reps: 5)  // 1RM ≈ 116.7
        try repo.addSet(to: session, exercise: bench, weight: 80, reps: 5)  // 1RM ≈ 93.3

        let prs = try context.fetch(FetchDescriptor<PersonalRecord>())
        #expect(prs.count == 1)
        #expect(prs.first?.weight == 100)
    }
}

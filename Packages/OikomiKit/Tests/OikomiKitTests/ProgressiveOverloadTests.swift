import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("ProgressiveOverload")
@MainActor
struct ProgressiveOverloadTests {

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let config = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2
        return cal
    }()

    @Test("不足部位は warning、MEV〜MAV の鍛えている部位は info（漸進）")
    func insufficientAndProgressable() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!  // chest mev10 mav22
        let repo = WorkoutSessionRepository(context: context)
        let s = try repo.startSession()
        // chest を 15 セット（10<=15<22 → 漸進候補）。他部位は 0（< mev → 不足）。
        for _ in 0..<15 { try repo.addSet(to: s, exercise: bench, weight: 60, reps: 8) }
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())

        let advices = ProgressiveOverload.progressiveOverloadAdvice(
            sets: allSets, referenceDate: Date(), calendar: Self.calendar)
        #expect(advices.contains { $0.severity == .warning && $0.title == "MEV未達" })
        let progress = advices.first { $0.title == "漸進的に増やす" }
        #expect(progress?.severity == .info)
        #expect(progress?.message.contains("胸") == true)
    }

    @Test("セット記録なし → MEV未達 warning のみ（漸進候補なし）")
    func emptyProducesInsufficientOnly() {
        let advices = ProgressiveOverload.progressiveOverloadAdvice(
            sets: [], referenceDate: Date(), calendar: Self.calendar)
        #expect(advices.contains { $0.title == "MEV未達" })
        #expect(!advices.contains { $0.title == "漸進的に増やす" })
    }

    @Test("profile で漸進判定が変わる（上級者は MAV が高い）")
    func profileAffectsProgressable() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let s = try repo.startSession()
        // chest 23 セット: 中級 MAV=22 を超える（漸進候補外）が上級 MAV=26 は未達（漸進候補）。
        for _ in 0..<23 { try repo.addSet(to: s, exercise: bench, weight: 60, reps: 8) }
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())

        let mid = ProgressiveOverload.progressiveOverloadAdvice(
            sets: allSets, profile: .default, referenceDate: Date(), calendar: Self.calendar)
        let adv = ProgressiveOverload.progressiveOverloadAdvice(
            sets: allSets,
            profile: TrainingProfile(experience: .advanced, goal: .hypertrophy),
            referenceDate: Date(), calendar: Self.calendar)

        #expect(!mid.contains { $0.title == "漸進的に増やす" && $0.message.contains("胸") })
        #expect(adv.contains { $0.title == "漸進的に増やす" && $0.message.contains("胸") })
    }
}

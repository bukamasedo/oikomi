import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("MonthlyDigest")
@MainActor
struct MonthlyDigestTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2
        return cal
    }()

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    @Test("対象月に完了セッションが無ければ nil")
    func nilWhenEmpty() throws {
        let digest = MonthlyDigest.build(
            sessions: [], sets: [], records: [], snapshots: [],
            yearMonth: "2026-05", calendar: Self.calendar)
        #expect(digest == nil)
    }

    @Test("当月のセッション数・トレ日数・総ボリュームを集計")
    func aggregatesBasics() throws {
        let context = try Self.makeContext()
        let bench = Exercise(name: "ベンチプレス", muscleGroups: [.chest])
        context.insert(bench)
        // 当月 2 セッション（別日）、各 working set 1 つ。前月のセッションは除外される。
        let s1 = WorkoutSession(startedAt: date(2026, 5, 10))
        s1.endedAt = date(2026, 5, 10)
        let s2 = WorkoutSession(startedAt: date(2026, 5, 20))
        s2.endedAt = date(2026, 5, 20)
        let prev = WorkoutSession(startedAt: date(2026, 4, 25))
        prev.endedAt = date(2026, 4, 25)
        let set1 = SetRecord(exercise: bench, weight: 60, reps: 10)
        set1.session = s1
        set1.completedAt = date(2026, 5, 10)
        let set2 = SetRecord(exercise: bench, weight: 60, reps: 10)
        set2.session = s2
        set2.completedAt = date(2026, 5, 20)
        let setPrev = SetRecord(exercise: bench, weight: 100, reps: 10)
        setPrev.session = prev
        setPrev.completedAt = date(2026, 4, 25)
        for o in [s1, s2, prev, set1, set2, setPrev] as [any PersistentModel] { context.insert(o) }

        let digest = MonthlyDigest.build(
            sessions: [s1, s2, prev], sets: [set1, set2, setPrev], records: [], snapshots: [],
            yearMonth: "2026-05", calendar: Self.calendar)

        #expect(digest?.sessionCount == 2)
        #expect(digest?.trainingDays == 2)
        #expect(digest?.totalVolumeKg == 1200)  // 60*10 * 2、前月分は除外
        #expect(digest?.muscleSetCounts.first?.muscle == .chest)
        #expect(digest?.isSubstantial == false)  // セッション 2 < 4
        // 胸しか鍛えていない → まったく鍛えていない部位（例: ハムストリング、0セット）も
        // underTrained として検出される（setCountByMuscleGroup は出現部位しか返さないため要・全 case 走査）
        #expect(digest?.underTrainedMuscles.contains(.hamstrings) == true)
    }

    @Test("当月達成 PR のみ抽出")
    func extractsMonthPRs() throws {
        let context = try Self.makeContext()
        let bench = Exercise(name: "ベンチプレス", muscleGroups: [.chest])
        context.insert(bench)
        let s = WorkoutSession(startedAt: date(2026, 5, 5))
        s.endedAt = date(2026, 5, 5)
        let set = SetRecord(exercise: bench, weight: 80, reps: 5)
        set.session = s
        set.completedAt = date(2026, 5, 5)
        let prThis = PersonalRecord(
            exercise: bench, weight: 80, reps: 5, estimated1RM: 93, achievedAt: date(2026, 5, 5))
        let prPrev = PersonalRecord(
            exercise: bench, weight: 70, reps: 5, estimated1RM: 81, achievedAt: date(2026, 4, 5))
        for o in [s, set, prThis, prPrev] as [any PersistentModel] { context.insert(o) }

        let digest = MonthlyDigest.build(
            sessions: [s], sets: [set], records: [prThis, prPrev], snapshots: [],
            yearMonth: "2026-05", calendar: Self.calendar)
        #expect(digest?.personalRecords.count == 1)
        #expect(digest?.personalRecords.first?.exerciseName == "ベンチプレス")
    }

    @Test("readiness 平均とバンド別日数を集計")
    func aggregatesReadiness() throws {
        let context = try Self.makeContext()
        let s = WorkoutSession(startedAt: date(2026, 5, 5))
        s.endedAt = date(2026, 5, 5)
        let set = SetRecord(exercise: Exercise(name: "X"), weight: 50, reps: 5)
        set.session = s
        set.completedAt = date(2026, 5, 5)
        let snapLow = HealthSnapshot(date: date(2026, 5, 5), readinessScore: 30)
        let snapHigh = HealthSnapshot(date: date(2026, 5, 6), readinessScore: 80)
        for o in [s, set.exercise!, set, snapLow, snapHigh] as [any PersistentModel] { context.insert(o) }

        let digest = MonthlyDigest.build(
            sessions: [s], sets: [set], records: [], snapshots: [snapLow, snapHigh],
            yearMonth: "2026-05", calendar: Self.calendar)
        #expect(digest?.readiness?.average == 55)
        #expect(digest?.readiness?.lowDays == 1)
        #expect(digest?.readiness?.highDays == 1)
    }
}

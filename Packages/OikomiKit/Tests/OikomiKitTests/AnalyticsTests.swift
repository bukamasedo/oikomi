import Foundation
import SwiftData
import Testing
@testable import OikomiKit

@Suite("Analytics")
@MainActor
struct AnalyticsTests {

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

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2  // 月曜
        return cal
    }()

    // MARK: - streakDays

    @Test("streakDays: 完了済みセッションがゼロなら0")
    func streakEmpty() {
        let result = Analytics.streakDays(sessions: [], calendar: Self.calendar)
        #expect(result == 0)
    }

    @Test("streakDays: 今日に1セッションのみなら1")
    func streakToday() {
        let session = WorkoutSession(startedAt: Date())
        session.endedAt = Date()
        let result = Analytics.streakDays(sessions: [session], calendar: Self.calendar)
        #expect(result == 1)
    }

    @Test("streakDays: 連続3日なら3")
    func streakThreeDays() {
        let now = Date()
        let cal = Self.calendar
        let sessions = (0...2).map { offset -> WorkoutSession in
            let date = cal.date(byAdding: .day, value: -offset, to: now)!
            let s = WorkoutSession(startedAt: date)
            s.endedAt = date
            return s
        }
        let result = Analytics.streakDays(sessions: sessions, referenceDate: now, calendar: cal)
        #expect(result == 3)
    }

    @Test("streakDays: 2日前で止まっていれば（昨日抜け）0")
    func streakBrokenAtYesterday() {
        let now = Date()
        let cal = Self.calendar
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: now)!
        let s = WorkoutSession(startedAt: twoDaysAgo)
        s.endedAt = twoDaysAgo
        let result = Analytics.streakDays(sessions: [s], referenceDate: now, calendar: cal)
        #expect(result == 0)
    }

    @Test("streakDays: 完了していないセッションは無視")
    func streakIgnoresInProgress() {
        let session = WorkoutSession(startedAt: Date())  // endedAt = nil
        let result = Analytics.streakDays(sessions: [session], calendar: Self.calendar)
        #expect(result == 0)
    }

    // MARK: - volumeByMuscleGroup

    @Test("volumeByMuscleGroup: ベンチプレス80kg×8レップは chest/triceps/shoulders に 640 加算")
    func volumeByGroup() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let set = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 80, reps: 8)

        let range = set.completedAt.addingTimeInterval(-60)...set.completedAt.addingTimeInterval(60)
        let volume = Analytics.volumeByMuscleGroup(sets: [set], in: range)
        #expect(volume[.chest] == 640)
        #expect(volume[.triceps] == 640)
        #expect(volume[.shoulders] == 640)
    }

    @Test("volumeByMuscleGroup: 範囲外のセットは集計しない")
    func volumeRespectsRange() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let set = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 100, reps: 5)

        // 1時間以上前の範囲を指定 → 集計対象外
        let oldEnd = set.completedAt.addingTimeInterval(-3600)
        let oldStart = oldEnd.addingTimeInterval(-3600)
        let volume = Analytics.volumeByMuscleGroup(sets: [set], in: oldStart...oldEnd)
        #expect(volume.isEmpty)
    }

    // MARK: - currentWeekRange

    @Test("currentWeekRange: 月曜開始の7日間 range")
    func weekRangeIsSevenDays() {
        let range = Analytics.currentWeekRange(calendar: Self.calendar)
        let cal = Self.calendar
        let startWeekday = cal.component(.weekday, from: range.lowerBound)
        #expect(startWeekday == 2)  // 月曜
        let duration = range.upperBound.timeIntervalSince(range.lowerBound)
        #expect(duration > 6 * 24 * 3600)
        #expect(duration < 7 * 24 * 3600)
    }
}

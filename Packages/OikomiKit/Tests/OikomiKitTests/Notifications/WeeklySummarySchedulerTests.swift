import Foundation
import Testing

@testable import OikomiKit

@Suite("WeeklySummaryScheduler.nextSunday")
@MainActor
struct WeeklySummarySchedulerTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }()

    @Test("nextSunday: 月曜から見ると 6 日後")
    func mondayReturnsSixDaysLater() {
        let cal = Self.calendar
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 25  // 2026-05-25 月曜
        let monday = cal.date(from: components)!
        let result = WeeklySummaryScheduler.nextSunday(after: monday, calendar: cal)
        let resultWeekday = cal.component(.weekday, from: result!)
        #expect(resultWeekday == 1)  // 日曜
        let diff = cal.dateComponents([.day], from: cal.startOfDay(for: monday), to: result!).day
        #expect(diff == 6)
    }

    @Test("nextSunday: 日曜から見ると 7 日後（来週の日曜）")
    func sundayReturnsNextSunday() {
        let cal = Self.calendar
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 24  // 2026-05-24 日曜
        let sunday = cal.date(from: components)!
        let result = WeeklySummaryScheduler.nextSunday(after: sunday, calendar: cal)
        let diff = cal.dateComponents([.day], from: cal.startOfDay(for: sunday), to: result!).day
        #expect(diff == 7)
        #expect(cal.component(.weekday, from: result!) == 1)
    }

    @Test("nextSunday: 土曜から見ると 1 日後")
    func saturdayReturnsOneDayLater() {
        let cal = Self.calendar
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 23  // 2026-05-23 土曜
        let saturday = cal.date(from: components)!
        let result = WeeklySummaryScheduler.nextSunday(after: saturday, calendar: cal)
        let diff = cal.dateComponents([.day], from: cal.startOfDay(for: saturday), to: result!).day
        #expect(diff == 1)
    }
}

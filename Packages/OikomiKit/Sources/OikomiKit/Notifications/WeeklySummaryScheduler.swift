import Foundation

#if canImport(UserNotifications)
    import UserNotifications
#endif

/// 週次サマリ通知のスケジューラ。次の日曜プリセット時刻に 1 回のみ通知を予約する。
///
/// 毎週日曜にユーザーがアプリを開けば `rescheduleAll()` が次の日曜を予約し直す設計。
/// `repeats: true` の繰り返し通知を使わない理由: 集計が「過去 1 週」なので、その時の最新値で
/// 本文を再生成したい。BGAppRefreshTask が動かないユーザーでも、アプリ起動時に
/// 最低 1 通は予約済みになる。
@MainActor
public enum WeeklySummaryScheduler {

    public static let identifier = "oikomi.weekly.summary"

    public static func schedule(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        referenceDate: Date,
        preset: NotificationTimePreset,
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg
    ) {
        cancel()

        guard let nextSunday = nextSunday(after: referenceDate, calendar: calendar) else { return }
        let report = WeeklySummaryFormatter.makeReport(
            sessions: sessions,
            sets: sets,
            referenceDate: nextSunday,
            calendar: calendar
        )
        let title = WeeklySummaryFormatter.title(for: report)
        let body = WeeklySummaryFormatter.body(for: report, weightUnit: weightUnit)

        CoachingNotificationScheduler.scheduleCalendarNotification(
            identifier: identifier,
            title: title,
            body: body,
            triggerDate: nextSunday,
            hour: preset.hour,
            calendar: calendar
        )
    }

    public static func cancel() {
        #if canImport(UserNotifications)
            guard !CoachingNotificationScheduler.isHostlessEnvironment else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        #endif
    }

    /// `referenceDate` 以降の最も近い日曜 0:00 を返す（純粋関数 / テスト用に公開）。
    /// 当日 referenceDate が日曜のときは「来週の日曜」を返し、過去発火を避ける。
    public static func nextSunday(after referenceDate: Date, calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: referenceDate)
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 日=1, 月=2, …, 土=7。日曜なら 7 日先にする。
        let daysToAdd = weekday == 1 ? 7 : (8 - weekday) % 7
        let normalized = daysToAdd == 0 ? 7 : daysToAdd
        return calendar.date(byAdding: .day, value: normalized, to: today)
    }
}

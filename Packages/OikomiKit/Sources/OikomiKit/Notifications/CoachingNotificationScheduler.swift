import Foundation

#if canImport(UserNotifications)
    import UserNotifications
#endif

/// PR 予測通知と HRV 連動ディロード推奨通知のスケジューラ。
///
/// 仕様書 §7.4: 「プッシュ通知 — PR 予測時・休息推奨時」を受けて、毎朝プリセット時刻に
/// 1) 翌日のルーティンに含まれる種目で PR 圏内のものがあれば通知
/// 2) 直近 7 日 HRV 平均比 -20% を下回ったら強度緩和を促す通知 (Pro 限定)
///
/// 純粋関数 (`evaluatePRPrediction` / `evaluateHRVDeload`) と副作用付き (`schedule*`) を 2 段に分離。
@MainActor
public enum CoachingNotificationScheduler {

    /// PR 予測通知のローカル identifier。日次で上書きしたいので固定値。
    public static let prPredictionIdentifier = "oikomi.coaching.pr.prediction"
    /// HRV 連動ディロード推奨通知のローカル identifier。
    public static let hrvDeloadIdentifier = "oikomi.coaching.hrv.deload"

    // MARK: - PR 予測

    /// 「翌日のルーティンに含まれる種目」のうち PR 圏内のものを抽出する純粋関数。
    /// テストはこの関数を直接呼ぶ。
    ///
    /// - Returns: `Analytics.prPredictions` で生成された `CoachingAdvice` 配列を、
    ///   翌日のルーティンに含まれる種目だけにフィルタしたもの。
    public static func evaluatePRPrediction(
        routines: [Routine],
        sets: [SetRecord],
        records: [PersonalRecord],
        tomorrow: Date,
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg
    ) -> [CoachingAdvice] {
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        let scheduledRoutines = routines.filter { $0.scheduledWeekdays.contains(tomorrowWeekday) }
        let exerciseIds = Set(
            scheduledRoutines.flatMap { routine in
                routine.orderedExercises.compactMap { $0.exercise?.id }
            }
        )
        guard !exerciseIds.isEmpty else { return [] }

        let relevantRecords = records.filter { record in
            guard let id = record.exercise?.id else { return false }
            return exerciseIds.contains(id)
        }
        return Analytics.prPredictions(
            sets: sets,
            records: relevantRecords,
            calendar: calendar,
            weightUnit: weightUnit
        )
    }

    /// 上記評価結果を翌朝のプリセット時刻にローカル通知としてスケジュールする。
    /// 既存スケジュールは差し替える。該当 advice がなければ既存通知を削除して no-op。
    public static func schedulePRPrediction(
        routines: [Routine],
        sets: [SetRecord],
        records: [PersonalRecord],
        referenceDate: Date,
        preset: NotificationTimePreset,
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg
    ) {
        cancelPRPrediction()
        // PR 予測通知は深さ＝Pro 限定（SPEC §10 split）。
        guard ProGate.canUseAdvancedCoaching else { return }

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) else { return }
        let advices = evaluatePRPrediction(
            routines: routines,
            sets: sets,
            records: records,
            tomorrow: tomorrow,
            calendar: calendar,
            weightUnit: weightUnit
        )
        guard !advices.isEmpty else { return }

        let title = "明日 PR の可能性"
        let body: String
        if advices.count == 1 {
            body = advices[0].message
        } else {
            let names = advices.prefix(3).map { advice -> String in
                advice.title  // フォールバック。1RM 数値は最初の advice のみ詳述
            }
            body = "\(advices.count) 種目で PR が狙えます。\(advices[0].message)"
            _ = names
        }
        scheduleCalendarNotification(
            identifier: prPredictionIdentifier,
            title: title,
            body: body,
            triggerDate: tomorrow,
            hour: preset.hour,
            calendar: calendar
        )
    }

    /// PR 予測通知を解除する（トグル OFF / 設定変更時）。
    public static func cancelPRPrediction() {
        #if canImport(UserNotifications)
            guard !isHostlessEnvironment else { return }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [prPredictionIdentifier])
        #endif
    }

    // MARK: - HRV 連動ディロード

    /// 直近 7 日 HRV 平均比 `thresholdPercent` 以上の低下を検出する純粋関数。
    /// - Parameters:
    ///   - today: 当日の HRV 値 (nil なら判定不能で false)
    ///   - trailing7DayAverage: 直近 7 日 (当日を除く) の HRV 平均 (nil なら判定不能で false)
    ///   - thresholdPercent: 低下のしきい値 (0.20 なら -20%)
    public static func evaluateHRVDeload(
        today: Double?,
        trailing7DayAverage: Double?,
        thresholdPercent: Double = 0.20
    ) -> Bool {
        guard let today, let avg = trailing7DayAverage, avg > 0, today > 0 else { return false }
        return today <= avg * (1.0 - thresholdPercent)
    }

    /// HealthStore から HRV を取得し、Pro チェック後に翌朝の通知をスケジュールする。
    /// Free アカウント、データ不足、しきい値未達のいずれかなら既存通知を削除して no-op。
    public static func scheduleHRVDeload(
        healthStore: HealthStore,
        referenceDate: Date,
        preset: NotificationTimePreset,
        thresholdPercent: Double = 0.20,
        calendar: Calendar = .current
    ) async {
        cancelHRVDeload()
        // HRV 連動ディロード推奨は楔＝Free（SPEC §10 split）。
        guard ProGate.canUseReadinessCoaching else { return }

        let today = await healthStore.todayValue(for: .hrv)
        let average = await healthStore.hrvAverage(days: 7, endingAt: referenceDate)
        guard
            evaluateHRVDeload(
                today: today,
                trailing7DayAverage: average,
                thresholdPercent: thresholdPercent
            )
        else { return }

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) else { return }
        let dropPercent: Int = {
            guard let today, let average, average > 0 else { return Int(thresholdPercent * 100) }
            return Int(((1 - today / average) * 100).rounded())
        }()

        scheduleCalendarNotification(
            identifier: hrvDeloadIdentifier,
            title: "HRV 低下を検知",
            body: "直近 7 日平均より \(dropPercent)% 低下しています。明日は前回比 80% 程度の重量で組むことを検討してください。",
            triggerDate: tomorrow,
            hour: preset.hour,
            calendar: calendar
        )
    }

    /// HRV ディロード通知を解除する。
    public static func cancelHRVDeload() {
        #if canImport(UserNotifications)
            guard !isHostlessEnvironment else { return }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [hrvDeloadIdentifier])
        #endif
    }

    // MARK: - 共通ヘルパー

    /// 指定日付の hour:00 に発火する `UNCalendarNotificationTrigger` でローカル通知を登録する。
    static func scheduleCalendarNotification(
        identifier: String,
        title: String,
        body: String,
        triggerDate: Date,
        hour: Int,
        calendar: Calendar = .current
    ) {
        #if canImport(UserNotifications)
            guard !isHostlessEnvironment else { return }

            var components = calendar.dateComponents([.year, .month, .day], from: triggerDate)
            components.hour = hour
            components.minute = 0
            components.second = 0

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            let center = UNUserNotificationCenter.current()
            center.add(request) { error in
                if let error {
                    print("[Oikomi.notif] calendar schedule failed (\(identifier)): \(error)")
                }
            }
        #endif
    }

    /// SwiftPM 単体テスト（XCTest 経由含む）などホストアプリ不在で実行された場合に true。
    static var isHostlessEnvironment: Bool {
        if Bundle.main.bundleIdentifier == nil { return true }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return true }
        return false
    }
}

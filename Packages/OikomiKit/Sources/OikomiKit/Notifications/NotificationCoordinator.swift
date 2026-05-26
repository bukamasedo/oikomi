import Foundation
import SwiftData

#if canImport(UserNotifications)
    import UserNotifications
#endif

#if canImport(BackgroundTasks) && os(iOS)
    import BackgroundTasks
#endif

/// 全通知の一括ライフサイクル管理。`OikomiApp` 起動時と設定変更時にエントリポイントとして呼ぶ。
///
/// - `bootstrap()` は起動時 1 回だけ
/// - `rescheduleAll()` は起動時 / 設定タブ変更時 / BGTask 起床時に呼んで現在の状態でスケジュールを差し替える
@MainActor
public enum NotificationCoordinator {

    /// BGAppRefreshTask の identifier。`Info.plist` の `BGTaskSchedulerPermittedIdentifiers` と一致させる。
    public static let bgRefreshIdentifier = "com.shuhirouchi.oikomi.coaching.refresh"

    /// アプリ起動時の 1 度だけの初期化処理。
    /// - 通知許可リクエスト (`RestTimerNotifier.requestAuthorization`)
    /// - BGTaskScheduler 登録 (iOS のみ)
    /// - 初回 `rescheduleAll()`
    public static func bootstrap() async {
        await RestTimerNotifier.requestAuthorization()
        #if canImport(BackgroundTasks) && os(iOS)
            registerBGTask()
            scheduleNextBGRefresh()
        #endif
        await rescheduleAll()
    }

    /// 現在の SwiftData / Subscription 状態に基づき、全予定通知を再スケジュールする。
    /// 起動時・scenePhase 復帰時・設定変更時・BGTask 起床時に呼ぶ。
    public static func rescheduleAll() async {
        guard let container = SharedModelContainer.container else { return }
        let context = ModelContext(container)

        let routines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let sets = (try? context.fetch(FetchDescriptor<SetRecord>())) ?? []
        let records = (try? context.fetch(FetchDescriptor<PersonalRecord>())) ?? []

        let preset = NotificationPreferences.timePreset()

        // PR 予測通知（明日のルーティン × PR 圏内の種目）
        if NotificationPreferences.isEnabled(.prPrediction) {
            CoachingNotificationScheduler.schedulePRPrediction(
                routines: routines,
                sets: sets,
                records: records,
                referenceDate: Date(),
                preset: preset
            )
        } else {
            CoachingNotificationScheduler.cancelPRPrediction()
        }

        // HRV 連動ディロード推奨通知 (Pro 限定)
        if NotificationPreferences.isEnabled(.hrvDeload) {
            await CoachingNotificationScheduler.scheduleHRVDeload(
                healthStore: HealthStore.shared,
                referenceDate: Date(),
                preset: preset
            )
        } else {
            CoachingNotificationScheduler.cancelHRVDeload()
        }

        // 週次サマリ通知（日曜のプリセット時刻）
        if NotificationPreferences.isEnabled(.weekly) {
            WeeklySummaryScheduler.schedule(
                sessions: sessions,
                sets: sets,
                referenceDate: Date(),
                preset: preset
            )
        } else {
            WeeklySummaryScheduler.cancel()
        }

        // トライアル残日数通知
        if NotificationPreferences.isEnabled(.trial) {
            await TrialDaysNotifier.schedule()
        } else {
            TrialDaysNotifier.cancel()
        }
    }

    /// レスト終了忘れ / レストタイマー終了など、トグルが OFF のときに即座に既存通知を消したい場合の便宜エントリ。
    public static func cancelDisabled() {
        if !NotificationPreferences.isEnabled(.rest) {
            RestTimerNotifier.cancel()
        }
        if !NotificationPreferences.isEnabled(.forgottenSession) {
            ForgottenSessionNotifier.cancel()
        }
    }

    // MARK: - BGTask

    #if canImport(BackgroundTasks) && os(iOS)
        private static var didRegisterBGTask = false

        private static func registerBGTask() {
            guard !didRegisterBGTask else { return }
            didRegisterBGTask = true
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: bgRefreshIdentifier,
                using: nil
            ) { task in
                handle(task: task as! BGAppRefreshTask)
            }
        }

        /// 次回起床を予約する。プリセット時刻の前日に近い時間帯で再評価したい。
        /// iOS は厳密な時刻指定を許さないので `earliestBeginDate` を翌朝の少し前にセット。
        public static func scheduleNextBGRefresh(referenceDate: Date = Date()) {
            let preset = NotificationPreferences.timePreset()
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            let target = calendar.nextDate(
                after: referenceDate,
                matching: DateComponents(hour: max(0, preset.hour - 1)),
                matchingPolicy: .nextTime
            )

            let request = BGAppRefreshTaskRequest(identifier: bgRefreshIdentifier)
            request.earliestBeginDate = target
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("[Oikomi.notif] BGAppRefresh schedule failed: \(error)")
            }
        }

        private static func handle(task: BGAppRefreshTask) {
            // 次回も予約しておく（ベストエフォート）
            scheduleNextBGRefresh()

            let work = Task { @MainActor in
                await rescheduleAll()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = {
                work.cancel()
            }
        }
    #endif
}

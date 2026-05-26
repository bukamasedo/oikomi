import Foundation

#if canImport(UserNotifications)
    import UserNotifications
#endif

/// ワークアウトセッションが長時間アイドルになったときの「終了し忘れ」リマインダー。
///
/// セッション開始時 / セット完了時に `refresh()` を呼ぶと、現在時刻から `idleMinutes` 分後の
/// 1 件のローカル通知をスケジュールする (固定 identifier で前回を上書き)。セッション終了時に
/// `cancel()` を呼ぶ。`RestTimerNotifier` と同じく `UNTimeIntervalNotificationTrigger` ベース。
public enum ForgottenSessionNotifier {

    public static let identifier = "oikomi.session.forgotten"

    /// セッションが終わったとみなすアイドル分数。
    public static let defaultIdleMinutes: Int = 90

    /// セッション開始 / セット完了時に呼ぶ。`idleMinutes` 後に発火する通知を登録（再スケジュール上書き）。
    public static func refresh(idleMinutes: Int = defaultIdleMinutes) {
        guard NotificationPreferences.isEnabled(.forgottenSession) else {
            cancel()
            return
        }
        #if canImport(UserNotifications)
            guard !isHostlessEnvironment else { return }

            let interval = TimeInterval(idleMinutes) * 60
            guard interval > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = "セッションを終了しますか？"
            content.body = "最後のセットから \(idleMinutes) 分経ちました。終了し忘れていませんか？"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.add(request) { error in
                if let error {
                    print("[Oikomi.session] forgotten notif schedule failed: \(error)")
                }
            }
        #endif
    }

    /// セッション終了 / `endedAt` 確定時に呼んで通知を取り消す。
    public static func cancel() {
        #if canImport(UserNotifications)
            guard !isHostlessEnvironment else { return }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
        #endif
    }

    private static var isHostlessEnvironment: Bool {
        if Bundle.main.bundleIdentifier == nil { return true }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return true }
        return false
    }
}

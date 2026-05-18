import Foundation

#if canImport(UserNotifications)
import UserNotifications
#endif

#if canImport(WatchKit)
import WatchKit
#endif

/// レストタイマー終了の通知・ハプティクスを抽象化するエントリポイント。
///
/// iOS / watchOS 両方でビルドできる。実体:
/// - watchOS: `UNUserNotificationCenter` でローカル通知 + `WKInterfaceDevice` でハプティクス
/// - iOS: Live Activity が iOS で動いているため、補助的にローカル通知のみ（haptic はアプリ全面時に
///   `UINotificationFeedbackGenerator` を使う UI 側に任せる）
public enum RestTimerNotifier {

    /// 通知の固定 identifier。連続して set を完了したときに前のスケジュールを上書きできるよう
    /// 安定値を使う。`identifier` パラメータでセッション毎に分けることも可能。
    public static let defaultIdentifier = "oikomi.rest.timer.end"

    /// アプリ起動後 1 度だけ呼ぶ。許可が拒否されてもクラッシュさせない。
    public static func requestAuthorization() async {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            print("[Oikomi.rest] notification authorization request failed: \(error)")
        }
        #endif
    }

    /// 指定時刻にレスト終了をユーザーに通知する。
    /// 同一 identifier の既存通知があれば差し替える（連続セット完了時の上書きをサポート）。
    public static func scheduleRestEnd(at endAt: Date, identifier: String = defaultIdentifier) {
        #if canImport(UserNotifications)
        let interval = endAt.timeIntervalSinceNow
        guard interval > 0.1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "レスト終了"
        content.body = "次のセットへ"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        // 同一 identifier は自動で置き換わる仕様だが、念のため事前削除
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request) { error in
            if let error {
                print("[Oikomi.rest] notification schedule failed: \(error)")
            }
        }
        #endif
    }

    /// 「スキップ」等で予定済み通知を取り消す。
    public static func cancel(identifier: String = defaultIdentifier) {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        #endif
    }

    /// 即座にハプティクスを発火する。Watch のカウントダウン UI が 0 到達時に呼ぶ。
    public static func playEndHaptic() {
        #if canImport(WatchKit) && os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #endif
    }
}

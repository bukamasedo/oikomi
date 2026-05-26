import Foundation
import StoreKit

#if canImport(UserNotifications)
    import UserNotifications
#endif

/// 14 日間トライアル残日数の通知。
///
/// `Transaction.currentEntitlements` を走査し、`offerType == .introductory` の取引を見つけたら
/// 「残り 3 日」と「当日 (= 残り 0 日)」の 2 件をスケジュールする。
/// トライアル中でない (Free / Paid) アカウントでは何もしない。
@MainActor
public enum TrialDaysNotifier {

    public static let identifier3Days = "oikomi.trial.days.3"
    public static let identifier0Days = "oikomi.trial.days.0"

    /// 起動時 / Subscription 状態変化時 / 設定変更時に呼ぶ。
    /// 既存スケジュールは差し替える。
    public static func schedule(now: Date = Date()) async {
        cancel()

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard ProductIDs.all.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }
            guard let expirationDate = transaction.expirationDate else { continue }
            guard expirationDate > now else { continue }
            guard transaction.offer?.type == .introductory else { continue }

            schedule(
                at: expirationDate, daysBefore: 3, identifier: identifier3Days,
                body: "Pro トライアルは残り 3 日です。Pro 機能の使用感を試してみてください。", now: now)
            schedule(
                at: expirationDate, daysBefore: 0, identifier: identifier0Days,
                body: "本日 Pro トライアルが終了します。継続しない場合は設定から解約できます。", now: now)
            return
        }
    }

    public static func cancel() {
        #if canImport(UserNotifications)
            guard !isHostlessEnvironment else { return }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier3Days, identifier0Days])
        #endif
    }

    /// 「`expirationDate` から `daysBefore` 日前の 9:00」に絶対時刻通知を予約する。
    /// 過去日になる場合は no-op。
    private static func schedule(
        at expirationDate: Date,
        daysBefore: Int,
        identifier: String,
        body: String,
        now: Date
    ) {
        let calendar = Calendar.current
        guard let target = calendar.date(byAdding: .day, value: -daysBefore, to: expirationDate) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: target)
        components.hour = 9
        components.minute = 0
        components.second = 0
        guard let fireDate = calendar.date(from: components), fireDate > now else { return }

        #if canImport(UserNotifications)
            guard !isHostlessEnvironment else { return }
            let content = UNMutableNotificationContent()
            content.title = daysBefore == 0 ? "Pro トライアル最終日" : "Pro トライアル残り \(daysBefore) 日"
            content.body = body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("[Oikomi.trial] schedule failed (\(identifier)): \(error)")
                }
            }
        #endif
    }

    private static var isHostlessEnvironment: Bool {
        if Bundle.main.bundleIdentifier == nil { return true }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return true }
        return false
    }
}

import Foundation

/// StoreKit 2 で扱う Product ID 定数。
///
/// App Store Connect で登録する商品 ID と `Oikomi.storekit` 設定ファイル内の ID は、
/// この定数と完全に一致させる必要がある。仕様書 §10 の価格に対応。
public enum ProductIDs {
    /// Pro 月額プラン (¥780/月)
    public static let proMonthly = "com.shuhirouchi.oikomi.pro.monthly"

    /// Pro 年額プラン (¥5,800/年)
    public static let proYearly = "com.shuhirouchi.oikomi.pro.yearly"

    /// StoreKit に問い合わせる際の全 ID。
    public static let all: [String] = [proMonthly, proYearly]

    /// App Store Connect 上で同一サブスクリプショングループに紐付ける名前。
    /// グループ内で月額 ⇄ 年額のアップ・ダウングレードが可能になる。
    public static let subscriptionGroup = "Oikomi Pro"
}

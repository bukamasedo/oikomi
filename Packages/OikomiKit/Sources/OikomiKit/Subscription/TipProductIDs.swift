import Foundation

/// 開発者支援（Tip Jar）用の消耗型 IAP 定義。
///
/// Pro サブスクリプションとは独立した支援機構。購入しても機能解放は伴わない。
/// App Store Connect / `Oikomi.storekit` の Product ID と完全一致させること。
public enum TipProductKind: String, CaseIterable, Sendable {
    case protein
    case chicken
    case steak
    case cheatday

    public var productID: String {
        switch self {
        case .protein: "com.shuhirouchi.oikomi.tip.protein"
        case .chicken: "com.shuhirouchi.oikomi.tip.chicken"
        case .steak: "com.shuhirouchi.oikomi.tip.steak"
        case .cheatday: "com.shuhirouchi.oikomi.tip.cheatday"
        }
    }

    public var emoji: String {
        switch self {
        case .protein: "🥛"
        case .chicken: "🍙"
        case .steak: "🥩"
        case .cheatday: "🍗"
        }
    }

    public var displayName: String {
        switch self {
        case .protein: "プロテイン 1 杯"
        case .chicken: "鶏胸肉 200g"
        case .steak: "ステーキ 1 枚"
        case .cheatday: "焼肉チートデイ"
        }
    }

    /// 表示用の参考金額（JPY）。実際の課金額は StoreKit の `Product.price` を優先する。
    /// アプリ内の累計金額の計算と、商品ロード失敗時のフォールバック表示に使う。
    public var amountJPY: Int {
        switch self {
        case .protein: 120
        case .chicken: 250
        case .steak: 500
        case .cheatday: 1_000
        }
    }
}

public enum TipProductIDs {
    public static let all: [String] = TipProductKind.allCases.map(\.productID)

    public static func kind(for productID: String) -> TipProductKind? {
        TipProductKind.allCases.first { $0.productID == productID }
    }
}

import Foundation

/// 開発者支援（Tip Jar）用の消耗型 IAP 定義。
///
/// Pro サブスクリプションとは独立した支援機構。購入しても機能解放は伴わない。
/// App Store Connect / `Oikomi.storekit` の Product ID と完全一致させること。
public enum TipProductKind: String, CaseIterable, Sendable {
    case pocari
    case protein
    case chicken
    case cheatday

    public var productID: String {
        switch self {
        case .pocari: "com.shuhirouchi.oikomi.tip.sportsdrink"
        case .protein: "com.shuhirouchi.oikomi.tip.protein"
        case .chicken: "com.shuhirouchi.oikomi.tip.chicken"
        case .cheatday: "com.shuhirouchi.oikomi.tip.cheatday"
        }
    }

    /// アプリ側 Asset Catalog（App/iOS/Assets.xcassets）に登録した PNG 名。
    /// 絵文字フォントに依存しない描画のため、各 kind に対応した手描きキャラ画像を使う。
    public var imageName: String {
        switch self {
        case .pocari: "TipPocari"
        case .protein: "TipProtein"
        case .chicken: "TipChicken"
        case .cheatday: "TipCheatday"
        }
    }

    public var displayName: String {
        switch self {
        case .pocari: loc("スポーツドリンク 1 本")
        case .protein: loc("プロテイン 1 杯")
        case .chicken: loc("鶏胸肉 200g")
        case .cheatday: loc("焼肉チートデイ")
        }
    }

    /// 表示用の参考金額（JPY）。実際の課金額は StoreKit の `Product.price` を優先する。
    /// アプリ内の累計金額の計算と、商品ロード失敗時のフォールバック表示に使う。
    public var amountJPY: Int {
        switch self {
        case .pocari: 120
        case .protein: 250
        case .chicken: 500
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

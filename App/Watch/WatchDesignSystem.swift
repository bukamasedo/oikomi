import SwiftUI

/// watchOS 用の最小デザイントークン。
///
/// iPhone の `OikomiColor` は UIKit 依存 (Color(uiColor:)) のため watchOS では使えない。
/// このファイルは Watch ターゲット専用に、ブランドカラーと spacing 定数だけを定義する。
/// 見た目のトーンは iPhone と統一（deep orange + dark card 背景）。
enum WatchColor {
    /// ブランド色 (deep orange)。iPhone の `OikomiColor.brandPrimary` と同値。
    static let brand = Color(red: 0xE8 / 255, green: 0x5D / 255, blue: 0x04 / 255)
    static let brandSecondary = Color(red: 0xFA / 255, green: 0x82 / 255, blue: 0x2B / 255)

    /// カード背景。watchOS は常時ダークなので gray opacity で十分。
    static let cardBackground = Color.white.opacity(0.10)
    static let cardBackgroundElevated = Color.white.opacity(0.16)

    static let separator = Color.white.opacity(0.20)
}

enum WatchSpacing {
    static let xs: CGFloat = 2
    static let s: CGFloat = 4
    static let m: CGFloat = 8
    static let l: CGFloat = 12
    static let xl: CGFloat = 16
}

enum WatchRadius {
    static let chip: CGFloat = 6
    static let tile: CGFloat = 10
    static let card: CGFloat = 12
}

import SwiftUI

/// iOS / watchOS の Widget 拡張で共通使用するデザイントークン。
///
/// `OikomiColor`（UIKit 依存）も `WatchColor`（App/Watch 内）も Widget からは参照できないため、
/// SwiftUI のみで定義した Widget 専用の薄いトークンを置く。色は iPhone / Watch アプリと同じ
/// deep orange ブランドカラーで揃える。
enum WidgetColor {
    static let brand = Color(red: 0xE8 / 255, green: 0x5D / 255, blue: 0x04 / 255)
    static let brandSecondary = Color(red: 0xFA / 255, green: 0x82 / 255, blue: 0x2B / 255)
    static let proAccent = Color(red: 0xFF / 255, green: 0xB7 / 255, blue: 0x3D / 255)
}

enum WidgetSpacing {
    static let xs: CGFloat = 2
    static let s: CGFloat = 4
    static let m: CGFloat = 6
    static let l: CGFloat = 10
    static let xl: CGFloat = 14
}

enum WidgetRadius {
    static let chip: CGFloat = 6
    static let tile: CGFloat = 10
    static let card: CGFloat = 14
}

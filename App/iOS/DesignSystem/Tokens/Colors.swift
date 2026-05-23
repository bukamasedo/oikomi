import SwiftUI
import UIKit

/// Oikomi のセマンティックカラー。
///
/// ブランドカラーは「追い込み」のエネルギーを表す deep orange。
/// Apple Fitness の Move リング（赤系）と衝突せず、純正アプリの間で識別できる温度感を狙う。
/// システムカラーは UIColor 経由で Light/Dark 自動対応する。
enum OikomiColor {

    static let brandPrimary = Color(red: 0xE8 / 255, green: 0x5D / 255, blue: 0x04 / 255)
    static let brandSecondary = Color(red: 0xFA / 255, green: 0x82 / 255, blue: 0x2B / 255)
    static let proAccent = Color(red: 0xFF / 255, green: 0xB7 / 255, blue: 0x3D / 255)

    static let statRed = Color.red
    static let statOrange = Color.orange
    static let statYellow = Color.yellow
    static let statGreen = Color.green
    static let statBlue = Color.blue
    static let statIndigo = Color.indigo
    static let statPink = Color.pink
    static let statPurple = Color.purple

    static let appBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedBackground = Color(uiColor: .tertiarySystemGroupedBackground)

    static let separator = Color(uiColor: .separator)
    static let separatorOpaque = Color(uiColor: .opaqueSeparator)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    static let textQuaternary = Color(uiColor: .quaternaryLabel)
}

extension Color {
    /// Foundational tint that views can opt into via `.tint(OikomiColor.brandPrimary)`.
    static let oikomiBrand = OikomiColor.brandPrimary
}

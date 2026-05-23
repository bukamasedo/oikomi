import SwiftUI

/// Oikomi のフォントトークン。
///
/// Dynamic Type に追従するため Apple のテキストスタイル (`.system(textStyle:)`) を基底にし、
/// 数値は `.monospacedDigit()` で揺れを止める。
enum OikomiFont {

    /// ホーム hero に置く一番大きな数値（週次達成日数など）。
    static let statHero = Font.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit()

    /// カード内の主要数値（今週セット数、PR 重量など）。
    static let statValue = Font.system(.title, design: .rounded, weight: .semibold).monospacedDigit()

    /// 小さい数値（StatTile の二次値など）。
    static let statValueCompact = Font.system(.title3, design: .rounded, weight: .semibold).monospacedDigit()

    /// 単位 (kg, ms, bpm, h)。
    static let metricUnit = Font.caption.weight(.medium)

    /// カードタイトル。
    static let cardTitle = Font.headline

    /// セクション見出し（"今週のハイライト" 等）。
    static let sectionTitle = Font.title3.weight(.semibold)

    /// 二次セクション見出し。
    static let sectionSubtitle = Font.subheadline.weight(.semibold)

    /// セット行の重量×レップ。
    static let setValue = Font.body.monospacedDigit()

    /// 強調メタ（"前回 +5kg" など）。
    static let metaEmphasized = Font.caption.weight(.semibold).monospacedDigit()

    /// 通常メタ。
    static let meta = Font.caption.monospacedDigit()
}

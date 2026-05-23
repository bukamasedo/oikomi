import SwiftUI

/// コーナー半径のセマンティック定数。
enum OikomiRadius {
    /// チップ・ピル要素 (8pt)。
    static let chip: CGFloat = 8
    /// 小型タイル (12pt)。
    static let tile: CGFloat = 12
    /// 標準カード (16pt) — Apple Fitness / Health のカードと同等。
    static let card: CGFloat = 16
    /// ヒーローカード (20pt)。
    static let hero: CGFloat = 20
    /// 完全な円形 (button などに `.capsule` の代替として)。
    static let pill: CGFloat = 999
}

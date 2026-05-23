import SwiftUI

/// 8pt グリッド準拠のスペーシング定数。
enum OikomiSpacing {
    /// 4pt — ラベルと値の最小密着、リスト行内縦間隔。
    static let xs: CGFloat = 4
    /// 8pt — チップ内 padding、StatTile 内行間。
    static let s: CGFloat = 8
    /// 12pt — カード内 padding 縦、リスト行縦間隔。
    static let m: CGFloat = 12
    /// 16pt — カード内 padding 横、カード間距離。
    static let l: CGFloat = 16
    /// 20pt — Section 間の縦距離。
    static let xl: CGFloat = 20
    /// 24pt — Hero と次セクションの距離、大型 padding。
    static let xxl: CGFloat = 24
    /// 32pt — 画面外周の特大マージン。
    static let xxxl: CGFloat = 32
}

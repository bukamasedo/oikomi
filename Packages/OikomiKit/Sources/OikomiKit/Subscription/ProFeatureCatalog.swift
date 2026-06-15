import Foundation

/// Oikomi Pro の機能訴求テキストを一元管理するカタログ。
///
/// オンボーディング末尾の Pro ステップと、設定タブの ProUpgradeSheet は同一ソースを参照する。
/// オンボーディングはハイライト機能のみ（`highlightFeatures`）、設定シートは全項目（`allFeatures`）を表示する。
/// 文言を変える際はこのファイルだけを編集すれば両画面に反映される。
public enum ProFeatureCatalog {

    /// 1 件の Pro 機能訴求。SwiftUI に依存しないよう SF Symbol 名は String で保持する。
    public struct Feature: Identifiable, Sendable, Hashable {
        public let id: String
        public let icon: String
        public let title: String
        public let description: String
        /// オンボーディングのハイライト 3 項目に含めるか。
        public let isHighlight: Bool

        public init(
            id: String,
            icon: String,
            title: String,
            description: String,
            isHighlight: Bool
        ) {
            self.id = id
            self.icon = icon
            self.title = title
            self.description = description
            self.isHighlight = isHighlight
        }
    }

    /// 設定シート用の全機能リスト。
    /// Family Sharing は v1.1 実装予定のため、v1.0 では掲載しない（CLAUDE.md §実装状況）。
    public static let allFeatures: [Feature] = [
        Feature(
            id: "advanced-coaching",
            icon: "waveform.path.ecg",
            title: loc("高度な AI コーチング"),
            description: loc("線形回帰 PR 予測・停滞検出・部位別ボリューム警告で次の一手を最適化"),
            isHighlight: true
        ),
        Feature(
            id: "health-trends",
            icon: "chart.line.uptrend.xyaxis",
            title: loc("コンディションの長期トレンド"),
            description: loc("HRV・睡眠・安静時心拍・体組成の推移を長期で可視化"),
            isHighlight: true
        ),
        Feature(
            id: "icloud-sync",
            icon: "icloud.fill",
            title: loc("iCloud 同期"),
            description: loc("iPhone・Apple Watch・Mac・iPad の全デバイスでデータを共有"),
            isHighlight: true
        ),
        Feature(
            id: "unlimited",
            icon: "infinity",
            title: loc("ルーティン・カスタム種目 無制限"),
            description: loc("Free は 5 / 5 まで。Pro は数の上限なし"),
            isHighlight: false
        ),
        Feature(
            id: "csv-export",
            icon: "square.and.arrow.up",
            title: loc("CSV エクスポート"),
            description: loc("全履歴を CSV ファイルに書き出して他アプリと共有"),
            isHighlight: false
        ),
    ]

    /// オンボーディング末尾のハイライト 3 項目。
    public static let highlightFeatures: [Feature] = allFeatures.filter(\.isHighlight)

    /// Hero Row（設定タブ最上部）のサブテキスト用、コンマ区切りハイライト要約。
    public static var heroSummary: String {
        highlightFeatures.map(\.title).joined(separator: " / ")
    }
}

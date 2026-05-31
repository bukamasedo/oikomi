import FoundationModels

/// Foundation Models の guided generation 出力。各フィールドは日本語。
@Generable
struct MonthlySummaryContent {
    @Guide(description: "その月のトレーニングを1文で総括する見出し（日本語）")
    var headline: String

    @Guide(description: "良かった点・成果を表す短い文。2〜3個（日本語）")
    var highlights: [String]

    @Guide(description: "気になる点・改善余地を表す短い文。1〜3個（日本語）")
    var watchPoints: [String]

    @Guide(description: "来月のフォーカス・具体的な提案。1〜2個（日本語）")
    var nextFocus: [String]
}

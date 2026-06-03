import OikomiKit
import SwiftUI

/// ホームの「直近の自己ベスト」カード内に積む 1 種目ぶんの行。
///
/// 種目名・推定1RM・達成日（左）、推定 1RM 推移のミニ・スパークライン（中央）、
/// 重量×レップ（右）を 1 行に横並びで並べる。
/// カードの枠（背景・余白）は持たず、複数行を 1 枚のカードにまとめる親側が付与する。
struct PRHighlightRow: View {

    let title: String
    let subtitle: String
    /// 右上に出す主値（例: "85 kg"）。
    let weightText: String
    /// 主値の下に出す補助値（例: "× 5"）。
    let repsText: String
    /// 推定 1RM の時系列（表示単位に変換済み・古い順）。2 点未満ならグラフは出さない。
    let series: [Double]
    var tint: Color = OikomiColor.brandSecondary

    var body: some View {
        HStack(spacing: OikomiSpacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: OikomiSpacing.s)

            // グラフ列・重量列はどの行も同じ固定幅にして縦に揃える。
            // 記録 1 件でグラフが無い行も枠だけ確保し、重量の開始位置をずらさない。
            Group {
                if series.count >= 2 {
                    MiniSparkline(series: series, tint: tint)
                } else {
                    Color.clear
                }
            }
            .frame(width: PRHighlightRow.chartWidth, height: 34)

            VStack(alignment: .trailing, spacing: 2) {
                Text(weightText)
                    .font(.headline.monospacedDigit())
                Text(repsText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: PRHighlightRow.valueWidth, alignment: .trailing)
        }
    }

    /// 全行でグラフ列を揃えるための固定幅。
    private static let chartWidth: CGFloat = 72
    /// 全行で重量列を揃えるための固定幅（"120 kg" など 3 桁重量を想定）。
    private static let valueWidth: CGFloat = 72
}

#Preview("Light") {
    VStack(alignment: .leading, spacing: OikomiSpacing.m) {
        Text("直近の自己ベスト")
            .font(OikomiFont.sectionTitle)
        PRHighlightRow(
            title: "ベンチプレス",
            subtitle: "推定1RM 95.2kg・6月1日",
            weightText: "85 kg",
            repsText: "× 5",
            series: [78, 80, 82, 81, 88, 90, 95]
        )
        Divider()
        PRHighlightRow(
            title: "デッドリフト",
            subtitle: "推定1RM 140.0kg・5月28日",
            weightText: "120 kg",
            repsText: "× 6",
            series: [140]
        )
    }
    .padding(OikomiSpacing.l)
    .background(
        OikomiColor.cardBackground,
        in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
    )
    .padding()
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    PRHighlightRow(
        title: "スクワット",
        subtitle: "推定1RM 130.0kg・6月2日",
        weightText: "110 kg",
        repsText: "× 6",
        series: [110, 115, 112, 120, 125, 130]
    )
    .padding(OikomiSpacing.l)
    .background(
        OikomiColor.cardBackground,
        in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
    )
    .padding()
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}

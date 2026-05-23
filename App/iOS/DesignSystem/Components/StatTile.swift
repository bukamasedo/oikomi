import SwiftUI

/// 数値ハイライトを 1 つ表示する小型タイル。Apple ヘルスケアの "Show All Health Data" 風。
///
/// 表示: アイコン（オプション）+ 大きな値 + 単位 + 副題。
/// 行・列どちらにも置けるよう `.frame(maxWidth: .infinity)` を内部で持つ。
struct StatTile: View {

    let title: String
    let value: String
    var unit: String? = nil
    var caption: String? = nil
    var systemImage: String? = nil
    var tint: Color = OikomiColor.brandPrimary
    var trend: Trend? = nil

    enum Trend: Equatable {
        case up(String)
        case down(String)
        case flat(String)

        var systemImage: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .flat: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .flat: return .secondary
            }
        }

        var text: String {
            switch self {
            case .up(let s), .down(let s), .flat(let s): return s
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            HStack(spacing: OikomiSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(OikomiFont.statValue)
                    .foregroundStyle(.primary)
                if let unit {
                    Text(unit)
                        .font(OikomiFont.metricUnit)
                        .foregroundStyle(.secondary)
                }
            }

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let trend {
                HStack(spacing: 2) {
                    Image(systemName: trend.systemImage)
                    Text(trend.text)
                }
                .font(OikomiFont.metaEmphasized)
                .foregroundStyle(trend.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous))
    }
}

#Preview("Light") {
    HStack {
        StatTile(
            title: "今週のセッション",
            value: "4",
            unit: "回",
            caption: "目標 3 回",
            systemImage: "figure.strengthtraining.traditional",
            tint: .orange,
            trend: .up("+1 vs 先週")
        )
        StatTile(
            title: "今日のボリューム",
            value: "5,240",
            unit: "kg",
            systemImage: "scalemass.fill",
            tint: .blue
        )
    }
    .padding()
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    HStack {
        StatTile(
            title: "今週のセッション",
            value: "4",
            unit: "回",
            caption: "目標 3 回",
            systemImage: "figure.strengthtraining.traditional",
            tint: .orange,
            trend: .up("+1 vs 先週")
        )
        StatTile(
            title: "今日のボリューム",
            value: "5,240",
            unit: "kg",
            systemImage: "scalemass.fill",
            tint: .blue
        )
    }
    .padding()
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}

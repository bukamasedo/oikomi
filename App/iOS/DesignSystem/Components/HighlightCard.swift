import SwiftUI

/// Apple ヘルスケアの "Highlights" カードに倣った横長カード。
/// 左にアイコンチップ、中央にテキスト、右に値や chevron を置く。
struct HighlightCard<Trailing: View>: View {

    let title: String
    let subtitle: String?
    let systemImage: String
    let iconTint: Color
    let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        iconTint: Color = OikomiColor.brandPrimary,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: OikomiSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                    .fill(iconTint.opacity(0.14))
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(iconTint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: OikomiSpacing.s)

            trailing()
        }
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }
}

#Preview("Light") {
    VStack(spacing: OikomiSpacing.m) {
        HighlightCard(
            title: "ベンチプレス 85kg × 5",
            subtitle: "推定1RM 95.2kg",
            systemImage: "trophy.fill",
            iconTint: .orange
        ) {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        HighlightCard(
            title: "スクワットが先週より +18%",
            subtitle: "ボリューム kg 比較",
            systemImage: "chart.line.uptrend.xyaxis",
            iconTint: .green
        )
    }
    .padding()
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    VStack(spacing: OikomiSpacing.m) {
        HighlightCard(
            title: "ベンチプレス 85kg × 5",
            subtitle: "推定1RM 95.2kg",
            systemImage: "trophy.fill",
            iconTint: .orange
        ) {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
    .padding()
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}

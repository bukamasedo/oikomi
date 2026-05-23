import SwiftUI

/// セクションタイトル + 副題 + 右側の "すべて見る" CTA。
/// Apple ヘルスケアの "Show All Data" や Fitness の "See All Workouts" に相当。
struct SectionHeader<Trailing: View>: View {

    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(OikomiFont.sectionTitle)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: OikomiSpacing.s)
            trailing()
        }
        .padding(.horizontal, OikomiSpacing.xs)
        .padding(.bottom, OikomiSpacing.xs)
    }
}

#Preview("Light") {
    VStack(alignment: .leading) {
        SectionHeader(title: "今週のハイライト", subtitle: "9 月 23 日 〜") {
            Button("すべて見る") {}
                .font(.subheadline.weight(.medium))
        }
        SectionHeader(title: "直近の自己ベスト")
    }
    .padding()
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    VStack(alignment: .leading) {
        SectionHeader(title: "今週のハイライト", subtitle: "9 月 23 日 〜") {
            Button("すべて見る") {}
                .font(.subheadline.weight(.medium))
        }
    }
    .padding()
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}

import SwiftUI

/// `ContentUnavailableView` をブランド色とトーンに統一したラッパ。
/// 中央配置・大型 SF Symbol・タイトル・短い説明・任意 CTA。
struct OikomiEmptyState<Action: View>: View {

    let title: String
    let message: String
    let systemImage: String
    var tint: Color = OikomiColor.brandPrimary
    @ViewBuilder var action: () -> Action

    init(
        title: String,
        message: String,
        systemImage: String,
        tint: Color = OikomiColor.brandPrimary,
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.tint = tint
        self.action = action
    }

    var body: some View {
        VStack(spacing: OikomiSpacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(tint)
                .padding(.bottom, OikomiSpacing.xs)

            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, OikomiSpacing.xl)

            action()
                .padding(.top, OikomiSpacing.s)
        }
        .padding(OikomiSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Light") {
    OikomiEmptyState(
        title: "まだ記録がありません",
        message: "ワークアウトを開始すると、ここに今日の達成が表示されます。",
        systemImage: "figure.strengthtraining.traditional",
        tint: .orange
    ) {
        Button {
        } label: {
            Label("ワークアウトを開始", systemImage: "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(OikomiColor.brandPrimary)
    }
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    OikomiEmptyState(
        title: "分析データなし",
        message: "ワークアウトを完了すると、推移グラフが表示されます。",
        systemImage: "chart.bar.xaxis"
    )
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}

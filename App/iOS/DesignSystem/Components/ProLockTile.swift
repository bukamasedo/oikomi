import SwiftUI

/// Pro 限定機能のロック表示を統一する。
/// 鍵アイコン + タイトル + 説明 + 「アップグレード」CTA。
struct ProLockTile: View {

    let title: String
    let message: String
    var systemImage: String = "lock.fill"
    var ctaLabel: String = "Pro にアップグレード"
    var onUpgrade: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack(spacing: OikomiSpacing.s) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OikomiColor.proAccent)
                Text("Pro 限定")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OikomiColor.proAccent)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let onUpgrade {
                Button(action: onUpgrade) {
                    Text(ctaLabel)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OikomiSpacing.s + 2)
                        .background(
                            OikomiColor.proAccent.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                        )
                        .foregroundStyle(OikomiColor.proAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .stroke(OikomiColor.proAccent.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview("Light") {
    ProLockTile(
        title: "詳細な推移グラフ",
        message: "週次総ボリュームと種目別の最大重量推移は Pro で利用できます。",
        onUpgrade: {}
    )
    .padding()
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    ProLockTile(
        title: "HealthKit コンディション分析",
        message: "HRV・安静時心拍・睡眠時間の推移は Pro プランで閲覧できます。",
        systemImage: "heart.text.square.fill",
        onUpgrade: {}
    )
    .padding()
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}

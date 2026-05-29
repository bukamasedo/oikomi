import SwiftUI

/// 商品情報や外部リソースの取得失敗時に表示する共通ビュー。
/// タイトル / 詳細メッセージ / 再試行ボタンを縦に並べる。
/// ペイウォール（Onboarding / Settings）や TipJar など、無音で固まらないために UI に出すべき経路から使う。
struct LoadFailureView: View {
    let title: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: OikomiSpacing.s) {
            Text(title)
                .font(.subheadline.bold())
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("再試行", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, OikomiSpacing.xs)
        }
    }
}

#Preview {
    LoadFailureView(
        title: "価格情報を取得できませんでした",
        message: "ネットワーク接続を確認して、もう一度お試しください。",
        onRetry: {}
    )
    .padding()
}

import SwiftUI

/// セット保存後に表示される自動レストタイマーバナー。
///
/// 仕様書 §4.1.1: 「セット完了 → そのままレストタイマー自動起動」
/// `endAt` までの残り秒数をカウントダウンする。0 になっても自動消えはせず、
/// ユーザーがスキップするか次のセットを記録すると消える設計（オーバーラン許容）。
struct RestTimerBanner: View {

    /// 終了予定時刻
    let endAt: Date

    /// スキップ（手動キャンセル）時のコールバック
    let onSkip: () -> Void

    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var remainingSeconds: Int {
        max(0, Int(endAt.timeIntervalSince(now).rounded()))
    }

    private var isOverrun: Bool { now >= endAt }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOverrun ? "checkmark.circle.fill" : "timer")
                .font(.title3)
                .foregroundStyle(isOverrun ? Color.green : Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(isOverrun ? "次のセットを開始できます" : "レスト中")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatted(remainingSeconds))
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(isOverrun ? .green : .primary)
            }

            Spacer()

            Button {
                onSkip()
            } label: {
                Text("スキップ")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isOverrun ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal)
        .onReceive(timer) { now = $0 }
    }

    private func formatted(_ seconds: Int) -> String {
        let mm = seconds / 60
        let ss = seconds % 60
        return String(format: "%d:%02d", mm, ss)
    }
}

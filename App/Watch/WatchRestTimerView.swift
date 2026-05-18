import SwiftUI
import OikomiKit

/// Watch のレストタイマー UI。指定 `endAt` までカウントダウンを表示し、
/// 0 到達でハプティクスを鳴らす。
struct WatchRestTimerView: View {

    let endAt: Date
    let onSkip: () -> Void

    @State private var now: Date = Date()
    @State private var firedHaptic: Bool = false

    private var remaining: TimeInterval {
        max(0, endAt.timeIntervalSince(now))
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("レスト")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(formatted(remaining))
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundStyle(remaining > 0 ? Color.primary : Color.green)

            Button {
                onSkip()
            } label: {
                Label("スキップ", systemImage: "forward.fill")
                    .font(.caption2)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { date in
            now = date
            if !firedHaptic, endAt.timeIntervalSince(date) <= 0 {
                firedHaptic = true
                RestTimerNotifier.playEndHaptic()
            }
        }
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

import SwiftUI

/// Watch のレストタイマー UI。
///
/// 残り秒数表示は `Text(timerInterval:countsDown:)` で OS の秒同期に乗せ、
/// 進捗リングは `TimelineView(.animation)` で滑らかに更新する。
/// 0 到達ハプティクスは `RestTimerNotifier.scheduleRestEnd` の絶対時刻ローカル通知に一本化
/// （watchOS の通知は haptic を伴うため、両端末で同時に響く）。
struct WatchRestTimerView: View {

    let endAt: Date
    /// レストタイマーの初期総秒数。リング進捗の正規化に使う。
    let totalSeconds: Int
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: WatchSpacing.m) {
            TimelineView(.animation) { context in
                let remaining = max(0, endAt.timeIntervalSince(context.date))
                let progress: Double =
                    totalSeconds > 0
                    ? max(0, min(1, remaining / Double(totalSeconds)))
                    : 0
                ZStack {
                    Circle()
                        .stroke(WatchColor.brand.opacity(0.18), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(WatchColor.brand, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "timer")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WatchColor.brand)
                }
                .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("レスト")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(timerInterval: Date()...endAt, countsDown: true)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer()

            Button {
                onSkip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WatchColor.brand)
                    .padding(WatchSpacing.s)
                    .background(WatchColor.brand.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("レストをスキップ")
        }
        .padding(.horizontal, WatchSpacing.m)
        .padding(.vertical, WatchSpacing.s)
        .background(WatchColor.cardBackground, in: RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous))
    }
}

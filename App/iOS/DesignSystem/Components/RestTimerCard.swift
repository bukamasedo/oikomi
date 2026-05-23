import SwiftUI

/// レスト中に画面下部 (safeAreaInset) に常時表示するカード。
///
/// 残り秒数表示は `Text(timerInterval:countsDown:)` で OS の秒同期に乗せ、
/// 進捗リングは `TimelineView(.animation)` で滑らかに更新する。
/// `endAt: Date` が両端末で共有されていれば、表示は端末間で揃う。
struct RestTimerCard: View {

    let endAt: Date
    let totalSeconds: Int
    var onSkip: () -> Void = {}

    var body: some View {
        HStack(spacing: OikomiSpacing.m) {
            TimelineView(.animation) { ctx in
                let remaining = max(0, endAt.timeIntervalSince(ctx.date))
                let progress: Double =
                    totalSeconds > 0
                    ? max(0, min(1, remaining / Double(totalSeconds)))
                    : 0
                ZStack {
                    Circle()
                        .stroke(OikomiColor.brandPrimary.opacity(0.18), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(OikomiColor.brandPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
                .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("レスト中")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(timerInterval: Date()...endAt, countsDown: true)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button("スキップ", action: onSkip)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OikomiColor.brandPrimary)
                .padding(.horizontal, OikomiSpacing.m)
                .padding(.vertical, OikomiSpacing.s)
                .background(OikomiColor.brandPrimary.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, OikomiSpacing.l)
        .padding(.vertical, OikomiSpacing.m)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
}

#Preview("Light") {
    RestTimerCard(
        endAt: Date().addingTimeInterval(45),
        totalSeconds: 90
    )
    .padding()
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    RestTimerCard(
        endAt: Date().addingTimeInterval(20),
        totalSeconds: 90
    )
    .padding()
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}

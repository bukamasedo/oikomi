import SwiftUI

/// レスト中に画面下部 (safeAreaInset) に常時表示するカード。
///
/// 進捗リングは `TimelineView(.animation)` で滑らかに更新、残り時間は
/// `Text(timerInterval:countsDown:)` で OS 秒同期。ボタンのラベル切替
/// （「スキップ」⇔「閉じる」）は `TimelineView(.explicit([.now, endAt]))`
/// で endAt の瞬間に確定的に再評価させる。
/// 旧実装の `@State hasEnded` + `.task(id: endAt)` 方式は SwiftUI の親再描画で
/// `Task.sleep` がキャンセルされたまま復帰しないと `hasEnded = true` まで到達せず、
/// 「カウントは 0 まで進んでいるのにボタンが切り替わらない」症状の原因になっていた。
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

            TimelineView(.explicit([Date(), endAt, endAt.addingTimeInterval(0.05)])) { ctx in
                let ended = ctx.date >= endAt
                Button(ended ? "閉じる" : "スキップ", action: onSkip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandPrimary)
                    .padding(.horizontal, OikomiSpacing.m)
                    .padding(.vertical, OikomiSpacing.s)
                    .background(OikomiColor.brandPrimary.opacity(0.12), in: Capsule())
            }
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

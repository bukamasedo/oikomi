import OikomiKit
import SwiftUI

/// Watch のレストタイマー UI。
///
/// 進捗リングは `TimelineView(.animation)` で滑らかに更新、残り時間は
/// `Text(timerInterval:countsDown:)` で OS 秒同期。アイコン切替
/// （`forward.fill` ⇔ `xmark`）は `TimelineView(.explicit([.now, endAt]))`
/// で endAt の瞬間に確定的に再評価させる。
/// 旧実装の `@State hasEnded` + `.task(id: endAt)` 方式は watchOS のサスペンドや
/// List 再評価で `Task.sleep` がキャンセルされたまま復帰せず、アイコンが切り替わらない
/// 症状の原因になっていた。
/// 0 到達ハプティクスは `RestTimerNotifier.scheduleRestEnd` の絶対時刻ローカル通知に一本化。
struct WatchRestTimerView: View {

    let endAt: Date
    /// レストタイマーの初期総秒数。リング進捗の正規化に使う。
    let totalSeconds: Int
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WatchSpacing.xs) {
            HStack(spacing: WatchSpacing.m) {
                TimelineView(.animation) { context in
                    let remaining = max(0, endAt.timeIntervalSince(context.date))
                    let progress: Double =
                        totalSeconds > 0
                        ? max(0, min(1, remaining / Double(totalSeconds)))
                        : 0
                    ZStack {
                        Circle()
                            .stroke(WatchColor.brand.opacity(0.18), lineWidth: 3.5)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(WatchColor.brand, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "timer")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WatchColor.brand)
                    }
                    .frame(width: 32, height: 32)
                }

                Text(timerInterval: Date()...endAt, countsDown: true)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: WatchSpacing.s)

                TimelineView(.explicit([Date(), endAt, endAt.addingTimeInterval(0.05)])) { ctx in
                    let ended = ctx.date >= endAt
                    Button {
                        onSkip()
                    } label: {
                        Image(systemName: ended ? "xmark" : "forward.fill")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(WatchColor.brand)
                            .padding(7)
                            .background(WatchColor.brand.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(ended ? "閉じる" : "レストをスキップ")
                }
            }
        }
        .padding(.horizontal, WatchSpacing.m)
        .padding(.vertical, WatchSpacing.l)
        .background(WatchColor.cardBackground, in: RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous))
    }
}

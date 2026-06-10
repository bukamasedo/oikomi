import SwiftUI

/// Watch アクティブセッション画面の hero として使うレストタイマー。
///
/// 上段: ステータス見出し（"レスト中" / "次のセットへ"）+ スキップ/閉じるボタン。
/// 中段: 大型リング + 残り秒数。
/// 下段: 次セットの目安テキスト（直前完了セットの重量 × レップ）。
///
/// - リング進捗は `TimelineView(.animation)` で滑らかに描画。
/// - 0:00 到達による見出し / アイコン切替は `TimelineView(.explicit([.now, endAt, endAt+0.05]))`
///   で確定的に再評価（旧 `.task(id:)` + `@State hasEnded` 方式は watchOS サスペンドで
///   `Task.sleep` がキャンセルされたまま復帰せず、アイコンが切り替わらない症状の原因だった）。
/// - 数字は OS 同期の `Text(timerInterval:countsDown:)`（endAt 以降は自動で "0:00" にクランプ）。
/// - 手首ダウン Always-On は `isLuminanceReduced` で色を抑える（レイアウトは維持）。
/// - 0 到達ハプティクスは `RestTimerNotifier.scheduleRestEnd` の絶対時刻ローカル通知に一本化。
struct WatchRestTimerView: View {

    let endAt: Date
    /// レストタイマーの初期総秒数。リング進捗の正規化に使う。
    let totalSeconds: Int
    /// 「次: 60 kg × 10」の "60 kg × 10" 部分。nil なら下部行を省略。
    let nextSetHint: String?
    let onSkip: () -> Void

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private let ringDiameter: CGFloat = 92
    private let ringWidth: CGFloat = 6

    var body: some View {
        VStack(spacing: WatchSpacing.s) {
            header
            ring
            if let hint = nextSetHint, !hint.isEmpty {
                Text("次: \(hint)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isLuminanceReduced ? .tertiary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, WatchSpacing.m)
        .padding(.vertical, WatchSpacing.m)
        .background(
            isLuminanceReduced ? Color.clear : WatchColor.cardBackground,
            in: RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous)
        )
    }

    @ViewBuilder
    private var header: some View {
        TimelineView(.explicit([Date(), endAt, endAt.addingTimeInterval(0.05)])) { ctx in
            let ended = ctx.date >= endAt
            let accent = accentColor(ended: ended)
            HStack(spacing: WatchSpacing.s) {
                Text(ended ? "次のセットへ" : "レスト中")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isLuminanceReduced ? .tertiary : .secondary)
                Spacer(minLength: WatchSpacing.xs)
                Button {
                    onSkip()
                } label: {
                    Image(systemName: ended ? "xmark" : "forward.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(6)
                        .background(
                            accent.opacity(isLuminanceReduced ? 0.10 : 0.18),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ended ? "閉じる" : "レストをスキップ")
            }
        }
    }

    @ViewBuilder
    private var ring: some View {
        ZStack {
            TimelineView(.animation) { context in
                let remaining = max(0, endAt.timeIntervalSince(context.date))
                let progress: Double =
                    totalSeconds > 0
                    ? max(0, min(1, remaining / Double(totalSeconds)))
                    : 0
                let ended = context.date >= endAt
                let accent = accentColor(ended: ended)
                ZStack {
                    Circle()
                        .stroke(
                            accent.opacity(isLuminanceReduced ? 0.10 : 0.18),
                            lineWidth: ringWidth
                        )
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accent, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }

                Text(timerInterval: Date()...endAt, countsDown: true)
                .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(isLuminanceReduced ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(width: ringDiameter, height: ringDiameter)
    }

    private func accentColor(ended: Bool) -> Color {
        let base: Color = ended ? .green : WatchColor.brand
        return isLuminanceReduced ? base.opacity(0.55) : base
    }
}

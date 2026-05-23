import SwiftUI

/// 週次トレーニング目標の達成度をリング表示する hero コンポーネント。
///
/// 筋トレは休養日込みのサイクルが前提なので「連続日数」ではなく
/// 「週あたり頻度（例: 今週 3/4 日）」を主指標にする。
/// サブで「N 週連続」を出して長期視点も与える。
/// Apple Fitness の Move リングに着想を得つつ、Oikomi のブランド色でまとめる。
struct WeeklyTargetRing: View {

    /// 今週のユニーク活動日数
    let daysThisWeek: Int
    /// ユーザーが設定した週次目標日数（リング満員の基準）
    let target: Int
    /// 連続活動週数。0 のときはサブラベル非表示。
    var consecutiveWeeks: Int = 0
    var size: CGFloat = 160
    var lineWidth: CGFloat = 18

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(daysThisWeek) / Double(target))
    }

    private var isComplete: Bool { daysThisWeek >= target }

    var body: some View {
        VStack(spacing: OikomiSpacing.s) {
            ring
            if consecutiveWeeks > 0 {
                Label("\(consecutiveWeeks) 週連続", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandPrimary)
                    .accessibilityLabel("\(consecutiveWeeks) 週連続トレーニング")
            }
        }
    }

    @ViewBuilder
    private var ring: some View {
        ZStack {
            Circle()
                .stroke(OikomiColor.brandPrimary.opacity(0.14), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [OikomiColor.brandPrimary, OikomiColor.brandSecondary, OikomiColor.brandPrimary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            VStack(spacing: 2) {
                Image(systemName: isComplete ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandPrimary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(daysThisWeek)")
                        .font(OikomiFont.statHero)
                        .foregroundStyle(.primary)
                    Text("/ \(target)")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text("今週の日数")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今週のトレーニング日数 \(daysThisWeek) / 目標 \(target) 日")
    }
}

#Preview("Light") {
    HStack(spacing: OikomiSpacing.xl) {
        WeeklyTargetRing(daysThisWeek: 3, target: 4, consecutiveWeeks: 6)
        WeeklyTargetRing(daysThisWeek: 0, target: 4)
    }
    .padding()
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    WeeklyTargetRing(daysThisWeek: 4, target: 4, consecutiveWeeks: 12)
        .padding()
        .background(OikomiColor.appBackground)
        .preferredColorScheme(.dark)
}

import OikomiKit
import SwiftUI

/// ホーム画面に置く「今日のコンディション」カード。
///
/// HRV / 安静時心拍 / 睡眠時間を 3 セル横並びで表示する。
/// Pro 未契約時は `ProLockTile` 風の lock 表示に切り替え。
/// 自立カード（Section に依存しない）として ScrollView 内に直接配置できる。
struct TodayConditionCard: View {

    /// 親（HomeView）が算出して渡すレディネス。nil なら総合スコア行は出さない。
    var readiness: ReadinessScore? = nil

    /// 今日の HealthKit 値。HomeView が一括取得して渡す（ウィジェット保存と fetch を一本化するため）。
    var hrv: Double? = nil
    var rhr: Int? = nil
    var sleepHours: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            // v0.x split（SPEC §10）: 今日のレディネス＝楔は全ユーザーに開放。
            // 権限拒否・データなしの場合は各値が "—" 表示になる（HealthStore が nil を返すため）。
            proContent
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }

    @ViewBuilder
    private var header: some View {
        Label("今日のコンディション", systemImage: "heart.text.square.fill")
            .font(.subheadline.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var proContent: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            header
            if let readiness {
                readinessBar(readiness)
            }
            metricsRow
        }
    }

    @ViewBuilder
    private var metricsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            metricCell(
                title: "HRV",
                value: hrv.map { "\(Int($0.rounded()))" } ?? "—",
                unit: "ms",
                systemImage: "waveform.path.ecg",
                tint: OikomiColor.statPink
            )
            divider
            metricCell(
                title: String(localized: "安静時心拍"),
                value: rhr.map { "\($0)" } ?? "—",
                unit: "bpm",
                systemImage: "heart.fill",
                tint: OikomiColor.statRed
            )
            divider
            metricCell(
                title: String(localized: "睡眠"),
                value: sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—",
                unit: "h",
                systemImage: "moon.zzz.fill",
                tint: OikomiColor.statIndigo
            )
        }
    }

    /// コンディションスコアを横長プログレスバーで視覚化する行。
    /// 数値だけでは「良い／悪い」が直感的に伝わらないため、
    /// バンド色のバーでひと目で状態が分かるようにする。
    @ViewBuilder
    private func readinessBar(_ readiness: ReadinessScore) -> some View {
        let progress = min(1.0, max(0.0, Double(readiness.value) / 100.0))
        let tint = bandTint(readiness.band)
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            HStack(spacing: OikomiSpacing.m) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(tint.opacity(0.15))
                        Capsule()
                            .fill(tint)
                            .frame(width: max(0, geo.size.width * progress))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                }
                .frame(height: 10)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(readiness.value)")
                        .font(OikomiFont.statValue)
                        .foregroundStyle(.primary)
                    Text("/ 100")
                        .font(OikomiFont.metricUnit)
                        .foregroundStyle(.secondary)
                }
                .fixedSize()
            }
            if let note = readiness.sourceNote {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(localized: "コンディションスコア \(readiness.value) / 100、\(bandLabel(readiness.band))"))
    }

    /// バーの色。低=赤・ふつう=ブランド・好調=緑の信号機マッピング。
    private func bandTint(_ band: ReadinessScore.Band) -> Color {
        switch band {
        case .low: return OikomiColor.statRed
        case .normal: return OikomiColor.brandSecondary
        case .high: return OikomiColor.statGreen
        }
    }

    private func bandLabel(_ band: ReadinessScore.Band) -> String {
        switch band {
        case .low: return String(localized: "低め")
        case .normal: return String(localized: "ふつう")
        case .high: return String(localized: "好調")
        }
    }

    @ViewBuilder
    private func metricCell(
        title: String,
        value: String,
        unit: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(OikomiFont.statValueCompact)
                    Text(unit)
                        .font(OikomiFont.metricUnit)
                        .foregroundStyle(.secondary)
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(OikomiColor.separator)
            .frame(width: 1)
            .padding(.vertical, OikomiSpacing.xs)
    }
}

#Preview("Light") {
    TodayConditionCard()
        .padding()
        .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    TodayConditionCard()
        .padding()
        .background(OikomiColor.appBackground)
        .preferredColorScheme(.dark)
}

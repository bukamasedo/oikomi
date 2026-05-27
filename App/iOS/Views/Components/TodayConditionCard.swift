import OikomiKit
import SwiftUI

/// ホーム画面に置く「今日のコンディション」カード。
///
/// HRV / 安静時心拍 / 睡眠時間を 3 セル横並びで表示する。
/// Pro 未契約時は `ProLockTile` 風の lock 表示に切り替え。
/// 自立カード（Section に依存しない）として ScrollView 内に直接配置できる。
struct TodayConditionCard: View {

    @State private var hrv: Double?
    @State private var rhr: Int?
    @State private var sleepHours: Double?
    @State private var lastFetchedAt: Date?

    private var isPro: Bool { ProGate.canReadHealthData }

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            header
            if isPro {
                proContent
            } else {
                lockedContent
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
        .task(id: isPro) {
            await refresh()
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Label("今日のコンディション", systemImage: "heart.text.square.fill")
                .font(.subheadline.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.primary)
            Spacer()
            if isPro, let fetched = lastFetchedAt {
                Text(fetched, style: .time)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var proContent: some View {
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
                title: "安静時心拍",
                value: rhr.map { "\($0)" } ?? "—",
                unit: "bpm",
                systemImage: "heart.fill",
                tint: OikomiColor.statRed
            )
            divider
            metricCell(
                title: "睡眠",
                value: sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—",
                unit: "h",
                systemImage: "moon.zzz.fill",
                tint: OikomiColor.statIndigo
            )
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
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(OikomiFont.statValueCompact)
                Text(unit)
                    .font(OikomiFont.metricUnit)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.caption.weight(.medium))
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

    @ViewBuilder
    private var lockedContent: some View {
        HStack(alignment: .top, spacing: OikomiSpacing.m) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(OikomiColor.proAccent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pro 限定")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OikomiColor.proAccent)
                Text("HRV・安静時心拍・睡眠時間は Pro プランで表示できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func refresh() async {
        guard isPro else {
            hrv = nil
            rhr = nil
            sleepHours = nil
            lastFetchedAt = nil
            return
        }
        async let hrvTask = HealthStore.shared.todayValue(for: .hrv)
        async let rhrTask = HealthStore.shared.todayValue(for: .restingHeartRate)
        async let sleepTask = HealthStore.shared.todayValue(for: .sleepHours)
        let (hrvValue, rhrValue, sleepValue) = await (hrvTask, rhrTask, sleepTask)
        hrv = hrvValue
        rhr = rhrValue.map { Int($0.rounded()) }
        sleepHours = sleepValue
        lastFetchedAt = Date()
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

import Charts
import OikomiKit
import SwiftUI

/// 分析タブ「コンディション」セグメント。
///
/// HRV / 安静時心拍 / 睡眠時間の推移をカード化。VStack で AnalysisTabView の ScrollView に直接置ける。
struct ConditionAnalysisSection: View {

    @State private var hrvSeries: [HealthTrendPoint] = []
    @State private var rhrSeries: [HealthTrendPoint] = []
    @State private var sleepSeries: [HealthTrendPoint] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: OikomiSpacing.l) {
            chartCard(
                title: "HRV（心拍変動）",
                subtitle: "直近 30 日",
                unit: "ms",
                series: hrvSeries,
                tint: OikomiColor.statPink,
                systemImage: "waveform.path.ecg"
            )
            chartCard(
                title: "安静時心拍",
                subtitle: "直近 30 日",
                unit: "bpm",
                series: rhrSeries,
                tint: OikomiColor.statRed,
                systemImage: "heart.fill"
            )
            chartCard(
                title: "睡眠時間",
                subtitle: "直近 14 日",
                unit: "h",
                series: sleepSeries,
                tint: OikomiColor.statIndigo,
                systemImage: "moon.zzz.fill"
            )
            noteCard
        }
        .task {
            await refresh()
        }
    }

    @ViewBuilder
    private func chartCard(
        title: String,
        subtitle: String,
        unit: String,
        series: [HealthTrendPoint],
        tint: Color,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(tint)
                Spacer()
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OikomiSpacing.xl)
            } else if series.isEmpty {
                emptyChartBody(systemImage: systemImage, title: title)
            } else {
                latestRow(series: series, unit: unit, tint: tint)
                Chart(series) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value(unit, point.value)
                    )
                    .foregroundStyle(tint)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日付", point.date),
                        y: .value(unit, point.value)
                    )
                    .foregroundStyle(tint)
                }
                .frame(height: 180)
            }
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func emptyChartBody(systemImage: String, title: String) -> some View {
        HStack(spacing: OikomiSpacing.s) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("「ヘルスケア」アプリで\(title)を記録すると、ここに推移が表示されます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, OikomiSpacing.m)
    }

    @ViewBuilder
    private func latestRow(series: [HealthTrendPoint], unit: String, tint: Color) -> some View {
        if let latest = series.last {
            HStack {
                Text("最新値")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formattedValue(latest.value, unit: unit))
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(tint)
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(latest.date, format: .dateTime.month().day())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func formattedValue(_ value: Double, unit: String) -> String {
        switch unit {
        case "bpm", "ms":
            return "\(Int(value.rounded()))"
        default:
            return String(format: "%.1f", value)
        }
    }

    @ViewBuilder
    private var noteCard: some View {
        Text("日々の変動に一喜一憂しないでください。1〜2 週間の傾向で判断するのがおすすめです。")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func refresh() async {
        isLoading = true
        async let hrv = HealthStore.shared.dailySeries(for: .hrv, days: 30)
        async let rhr = HealthStore.shared.dailySeries(for: .restingHeartRate, days: 30)
        async let sleep = HealthStore.shared.dailySeries(for: .sleepHours, days: 14)
        let (h, r, s) = await (hrv, rhr, sleep)
        hrvSeries = h
        rhrSeries = r
        sleepSeries = s
        isLoading = false
    }
}

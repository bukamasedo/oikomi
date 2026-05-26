import Charts
import OikomiKit
import SwiftUI

/// 分析タブ「ボディ」セグメント。
struct BodyAnalysisSection: View {

    @State private var weightSeries: [HealthTrendPoint] = []
    @State private var fatSeries: [HealthTrendPoint] = []
    @State private var lbmSeries: [HealthTrendPoint] = []
    @State private var isLoading = true

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    private let days = 90

    var body: some View {
        let convertedWeight = weightSeries.map {
            HealthTrendPoint(date: $0.date, value: weightUnit.fromKilograms($0.value))
        }
        let convertedLBM = lbmSeries.map {
            HealthTrendPoint(date: $0.date, value: weightUnit.fromKilograms($0.value))
        }
        VStack(spacing: OikomiSpacing.l) {
            metricCard(
                title: "体重",
                subtitle: "直近 90 日",
                unit: weightUnit.symbol,
                series: convertedWeight,
                tint: OikomiColor.textSecondary,
                systemImage: "scalemass.fill"
            )
            metricCard(
                title: "体脂肪率",
                subtitle: "直近 90 日",
                unit: "%",
                series: fatSeries.map { HealthTrendPoint(date: $0.date, value: $0.value * 100) },
                tint: OikomiColor.statOrange,
                systemImage: "percent"
            )
            metricCard(
                title: "除脂肪体重 (LBM)",
                subtitle: "直近 90 日",
                unit: weightUnit.symbol,
                series: convertedLBM,
                tint: OikomiColor.statGreen,
                systemImage: "figure.strengthtraining.traditional"
            )
            healthAppLinkCard
        }
        .task {
            await refresh()
        }
    }

    @ViewBuilder
    private func metricCard(
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
                HStack(spacing: OikomiSpacing.s) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("「ヘルスケア」アプリで\(title)を記録すると、ここに推移が表示されます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, OikomiSpacing.m)
            } else {
                summaryRow(series: series, unit: unit, tint: tint)
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
    private func summaryRow(series: [HealthTrendPoint], unit: String, tint: Color) -> some View {
        if let latest = series.last, let first = series.first {
            let delta = latest.value - first.value
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("最新値")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", latest.value))
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(tint)
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("90 日変化")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(delta >= 0 ? OikomiColor.statBlue : OikomiColor.statGreen)
                        Text("\(delta >= 0 ? "+" : "")\(String(format: "%.1f", delta))")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(delta >= 0 ? OikomiColor.statBlue : OikomiColor.statGreen)
                        Text(unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var healthAppLinkCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            Link(destination: URL(string: "x-apple-health://")!) {
                HStack {
                    Label("ヘルスケアで値を編集", systemImage: "arrow.up.right.square.fill")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .padding(OikomiSpacing.l)
                .background(
                    OikomiColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
            }
            Text("体重・体脂肪率・LBM は HealthKit が一次データです。体組成計や手入力の値はヘルスケアアプリで管理してください。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func refresh() async {
        isLoading = true
        async let weight = HealthStore.shared.dailySeries(for: .bodyMass, days: days)
        async let fat = HealthStore.shared.dailySeries(for: .bodyFatPercentage, days: days)
        async let lbm = HealthStore.shared.dailySeries(for: .leanBodyMass, days: days)
        let (w, f, l) = await (weight, fat, lbm)
        weightSeries = w
        fatSeries = f
        lbmSeries = l
        isLoading = false
    }
}

import Charts
import OikomiKit
import SwiftUI

/// 分析タブ「部位別」セグメント。
struct MuscleGroupAnalysisSection: View {

    let sets: [SetRecord]

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    private var report: [MuscleSetCountRow] {
        Analytics.weeklySetCountReport(sets: sets)
    }

    private var volumeByMuscle: [(muscle: MuscleGroup, total: Double)] {
        let range = Analytics.currentWeekRange()
        return Analytics.volumeByMuscleGroup(sets: sets, in: range)
            .sorted { $0.value > $1.value }
            .map { (muscle: $0.key, total: $0.value) }
    }

    var body: some View {
        VStack(spacing: OikomiSpacing.l) {
            setsCard
            volumeCard
            legendCard
        }
    }

    // MARK: - Sets per muscle

    @ViewBuilder
    private var setsCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label("今週のセット数（部位別）", systemImage: "rectangle.split.3x1.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            VStack(spacing: OikomiSpacing.s) {
                ForEach(report) { row in
                    HStack(spacing: OikomiSpacing.m) {
                        Text(row.muscle.displayName)
                            .font(.callout)
                            .frame(width: 70, alignment: .leading)
                        countBar(for: row)
                        Text("\(row.count)")
                            .font(.callout.monospacedDigit().weight(.semibold))
                            .frame(width: 28, alignment: .trailing)
                        statusChip(for: row)
                    }
                }
            }

            Text("レンジは MEV（最低有効ボリューム）〜 MAV（適応上限）の目安です。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func countBar(for row: MuscleSetCountRow) -> some View {
        let upperRange = max(row.target.mav, row.count) + 4
        let upper = Double(upperRange)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(OikomiColor.elevatedBackground)
                let mevX = CGFloat(Double(row.target.mev) / upper) * geo.size.width
                let mavX = CGFloat(Double(row.target.mav) / upper) * geo.size.width
                Capsule()
                    .fill(OikomiColor.statGreen.opacity(0.18))
                    .frame(width: max(0, mavX - mevX))
                    .offset(x: mevX)
                Capsule()
                    .fill(barColor(for: row.status))
                    .frame(width: max(0, CGFloat(Double(row.count) / upper) * geo.size.width))
            }
        }
        .frame(height: 10)
    }

    @ViewBuilder
    private func statusChip(for row: MuscleSetCountRow) -> some View {
        Text(statusText(for: row.status))
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(barColor(for: row.status).opacity(0.15), in: Capsule())
            .foregroundStyle(barColor(for: row.status))
    }

    private func statusText(for status: MuscleSetCountRow.Status) -> String {
        switch status {
        case .insufficient: return "不足"
        case .optimal: return "適正"
        case .excessive: return "過多"
        }
    }

    private func barColor(for status: MuscleSetCountRow.Status) -> Color {
        switch status {
        case .insufficient: return OikomiColor.statOrange
        case .optimal: return OikomiColor.statGreen
        case .excessive: return OikomiColor.statRed
        }
    }

    // MARK: - Volume kg per muscle

    @ViewBuilder
    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label("今週のボリューム \(weightUnit.symbol)（部位別）", systemImage: "scalemass.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            if volumeByMuscle.isEmpty {
                Text("今週はまだボリューム記録がありません")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: OikomiSpacing.s) {
                    ForEach(volumeByMuscle, id: \.muscle) { entry in
                        HStack {
                            Text(entry.muscle.displayName)
                                .font(.callout)
                            Spacer()
                            Text(
                                WeightFormatter.numberOnly(
                                    kilograms: entry.total, in: weightUnit, fractionDigits: 0...0)
                            )
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.primary)
                            Text(weightUnit.symbol)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("セット数と \(weightUnit.symbol) の違い")
                .font(.caption.weight(.semibold))
            Text("セット数は「刺激の頻度」、\(weightUnit.symbol) は「強度の総量」を表します。両方を合わせて見ると、追い込めているか・効率的かを判断できます。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }
}

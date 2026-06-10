import Charts
import OikomiKit
import SwiftData
import SwiftUI

/// 種目別の詳細画面。
/// Hero header + 推移グラフカード + StatTile + 直近セット feed。
struct ExerciseDetailView: View {

    @Environment(\.modelContext) private var modelContext

    let exercise: Exercise

    @State private var editingRest = false
    @State private var pendingRestSeconds: Int? = nil
    @State private var restErrorMessage: String?

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var completedSessions: [WorkoutSession]

    @Query private var allPRs: [PersonalRecord]

    private var allSetsForExercise: [SetRecord] {
        let id = exercise.id
        return
            completedSessions
            .flatMap { $0.sets ?? [] }
            .filter { $0.exercise?.id == id }
    }

    private var workingSets: [SetRecord] {
        allSetsForExercise.filter { !$0.isWarmup }
    }

    private var pr: PersonalRecord? {
        let id = exercise.id
        return allPRs.first { $0.exercise?.id == id }
    }

    private var totalSessions: Int {
        let id = exercise.id
        return
            completedSessions
            .filter { session in (session.sets ?? []).contains { $0.exercise?.id == id } }
            .count
    }

    private var totalVolume: Double {
        workingSets.reduce(into: 0) { acc, set in
            guard let weight = set.weight, let reps = set.reps else { return }
            acc += weight * Double(reps)
        }
    }

    private var weightTrend: [DateWeightPoint] {
        Analytics.maxWeightSeries(sets: allSetsForExercise, forExerciseId: exercise.id)
    }

    private var recentSets: [SetRecord] {
        Array(allSetsForExercise.sorted { $0.completedAt > $1.completedAt }.prefix(20))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: OikomiSpacing.l) {
                metaCard

                defaultRestEditorCard

                if let pr {
                    prCard(pr)
                }

                statsTiles

                trendCard

                recentSetsCard
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.bottom, OikomiSpacing.xxl)
        }
        .background(OikomiColor.appBackground)
        .navigationTitle(exercise.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editingRest, onDismiss: saveRest) {
            RestSecondsPickerSheet(
                seconds: Binding(
                    get: { pendingRestSeconds },
                    set: { pendingRestSeconds = $0 }
                ),
                allowsDefault: false,
                title: String(localized: "デフォルトレスト")
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .alert("エラー", isPresented: .constant(restErrorMessage != nil)) {
            Button("OK") { restErrorMessage = nil }
        } message: {
            Text(restErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var defaultRestEditorCard: some View {
        Button {
            pendingRestSeconds = exercise.defaultRestSeconds
            editingRest = true
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                        .fill(OikomiColor.brandPrimary.opacity(0.14))
                    Image(systemName: "timer")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("デフォルトレスト")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(RestSecondsPickerSheet.formatLabel(exercise.defaultRestSeconds))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(OikomiSpacing.l)
            .background(
                OikomiColor.cardBackground,
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func saveRest() {
        guard let newValue = pendingRestSeconds, newValue != exercise.defaultRestSeconds else { return }
        let repo = ExerciseRepository(context: modelContext)
        do {
            try repo.updateDefaultRestSeconds(exercise, to: newValue)
        } catch {
            restErrorMessage = String(localized: "保存に失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - Meta

    @ViewBuilder
    private var metaCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            if !exercise.nameEn.isEmpty {
                Text(exercise.nameEn)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                ForEach(exercise.muscleGroups, id: \.self) { group in
                    Text(group.displayName)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, OikomiSpacing.s)
                        .padding(.vertical, 4)
                        .background(OikomiColor.brandPrimary.opacity(0.14), in: Capsule())
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    // MARK: - PR

    @ViewBuilder
    private func prCard(_ pr: PersonalRecord) -> some View {
        HStack(alignment: .top, spacing: OikomiSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                    .fill(OikomiColor.brandSecondary.opacity(0.18))
                Image(systemName: "trophy.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandSecondary)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("自己ベスト")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(WeightFormatter.string(kilograms: pr.weight, in: weightUnit)) × \(pr.reps)")
                    .font(.title2.weight(.semibold).monospacedDigit())
                Text(
                    "推定1RM \(WeightFormatter.oneRM(kilograms: pr.estimated1RM, in: weightUnit))・\(pr.achievedAt.formatted(.dateTime.month(.abbreviated).day()))"
                )
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    // MARK: - Stats Tiles

    @ViewBuilder
    private var statsTiles: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(title: String(localized: "累計"))
            HStack(spacing: OikomiSpacing.m) {
                StatTile(
                    title: String(localized: "セッション"),
                    value: "\(totalSessions)",
                    unit: String(localized: "回"),
                    systemImage: "figure.strengthtraining.traditional",
                    tint: OikomiColor.brandPrimary
                )
                StatTile(
                    title: String(localized: "ワーキングセット"),
                    value: "\(workingSets.count)",
                    unit: "",
                    systemImage: "list.bullet",
                    tint: OikomiColor.statBlue
                )
            }
            StatTile(
                title: String(localized: "総ボリューム"),
                value: WeightFormatter.numberOnly(
                    kilograms: totalVolume, in: weightUnit, fractionDigits: 0...0),
                unit: weightUnit.symbol,
                systemImage: "scalemass.fill",
                tint: OikomiColor.statIndigo
            )
        }
    }

    // MARK: - Trend

    @ViewBuilder
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(
                title: String(localized: "最大重量の推移"),
                subtitle: weightTrend.isEmpty ? nil : String(localized: "ワーキングセットの最大値"))

            if weightTrend.count < 2 {
                Text("推移を表示するには 2 回以上の記録が必要です")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(OikomiSpacing.l)
                    .background(
                        OikomiColor.cardBackground,
                        in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
            } else {
                Chart(weightTrend) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("重量 (\(weightUnit.symbol))", weightUnit.fromKilograms(point.weight))
                    )
                    .foregroundStyle(OikomiColor.brandPrimary)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("重量 (\(weightUnit.symbol))", weightUnit.fromKilograms(point.weight))
                    )
                    .foregroundStyle(OikomiColor.brandPrimary)
                }
                .frame(height: 200)
                .padding(OikomiSpacing.l)
                .background(
                    OikomiColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
            }
        }
    }

    // MARK: - Recent sets

    @ViewBuilder
    private var recentSetsCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(title: String(localized: "直近の記録"))

            if recentSets.isEmpty {
                Text("まだ記録がありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(OikomiSpacing.l)
                    .background(
                        OikomiColor.cardBackground,
                        in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentSets.enumerated()), id: \.element.id) { idx, set in
                        recentSetRow(set)
                            .padding(.horizontal, OikomiSpacing.l)
                            .padding(.vertical, OikomiSpacing.s)
                        if idx < recentSets.count - 1 {
                            Divider().padding(.horizontal, OikomiSpacing.l)
                        }
                    }
                }
                .background(
                    OikomiColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func recentSetRow(_ set: SetRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(set.completedAt, format: .dateTime.month(.abbreviated).day().year())
                    .font(.subheadline)
                if set.isWarmup {
                    Text("ウォームアップ")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if let weight = set.weight, let reps = set.reps {
                Text("\(WeightFormatter.string(kilograms: weight, in: weightUnit)) × \(reps)")
                    .font(.body.monospacedDigit())
            } else if let reps = set.reps {
                Text(String(localized: "\(reps) レップ"))
                    .font(.body.monospacedDigit())
            }
        }
    }
}

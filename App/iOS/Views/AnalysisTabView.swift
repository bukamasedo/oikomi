import Charts
import OikomiKit
import SwiftData
import SwiftUI

/// 分析タブ。Apple ヘルスケアの Browse + Highlights 風。
/// 4 カテゴリ (推移 / コンディション / ボディ / 部位別) を segmented picker で切り替える。
struct AnalysisTabView: View {

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var completedSessions: [WorkoutSession]

    @Query(sort: \PersonalRecord.estimated1RM, order: .reverse)
    private var personalRecords: [PersonalRecord]

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var selectedExercise: Exercise?
    @State private var showingExercisePicker = false
    @State private var category: Category = .trend

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    enum Category: String, CaseIterable, Identifiable {
        case trend, condition, body, muscle

        var id: String { rawValue }
        var title: String {
            switch self {
            case .trend: return "推移"
            case .condition: return "コンディション"
            case .body: return "ボディ"
            case .muscle: return "部位別"
            }
        }
    }

    private var allSets: [SetRecord] {
        completedSessions.flatMap { $0.sets ?? [] }
    }

    private var weeklySeries: [WeeklyVolumePoint] {
        Analytics.weeklyVolumeSeries(sets: allSets, weeks: 8)
    }

    private var hasAnyData: Bool {
        !completedSessions.isEmpty || !personalRecords.isEmpty
    }

    private var selectedExerciseSeries: [DateWeightPoint] {
        guard let id = selectedExercise?.id else { return [] }
        return Analytics.maxWeightSeries(sets: allSets, forExerciseId: id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: OikomiSpacing.l) {
                    categoryPicker

                    Group {
                        switch category {
                        case .trend:
                            trendContent
                        case .condition:
                            conditionContent
                        case .body:
                            bodyContent
                        case .muscle:
                            muscleContent
                        }
                    }
                }
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.bottom, OikomiSpacing.xxl)
            }
            .background(OikomiColor.appBackground)
            .navigationTitle("分析")
            .toolbar {
                if ProGate.canUseAICoaching {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            MonthlySummaryHistoryView()
                        } label: {
                            Image(systemName: "sparkles.rectangle.stack")
                        }
                        .accessibilityLabel("振り返り履歴")
                    }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerSheet { picked in
                    selectedExercise = picked
                }
            }
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }

    @ViewBuilder
    private var categoryPicker: some View {
        Picker("カテゴリ", selection: $category) {
            ForEach(Category.allCases) { c in
                Text(c.title).tag(c)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - .trend

    @ViewBuilder
    private var trendContent: some View {
        if !hasAnyData {
            OikomiEmptyState(
                title: "分析データがありません",
                message: "ワークアウトを完了すると、ここに推移が表示されます。",
                systemImage: "chart.bar.xaxis",
                tint: OikomiColor.brandPrimary
            )
            .frame(minHeight: 320)
        } else {
            if ProGate.canSeeAdvancedAnalytics {
                weeklyVolumeCard
                exerciseTrendCard
            } else {
                ProLockTile(
                    title: "詳細な推移グラフ",
                    message: "週次総ボリュームと種目別の最大重量推移は Pro プランで閲覧できます。"
                )
            }
            prsCard
        }
    }

    // MARK: - .condition

    @ViewBuilder
    private var conditionContent: some View {
        if ProGate.canReadHealthData {
            ConditionAnalysisSection()
        } else {
            ProLockTile(
                title: "コンディション分析",
                message: "HRV・安静時心拍・睡眠時間の推移は Pro プランで閲覧できます。",
                systemImage: "heart.text.square.fill"
            )
        }
    }

    // MARK: - .body

    @ViewBuilder
    private var bodyContent: some View {
        if ProGate.canReadHealthData {
            BodyAnalysisSection(records: personalRecords)
        } else {
            ProLockTile(
                title: "ボディ分析",
                message: "体重・体脂肪率・除脂肪体重の推移は Pro プランで閲覧できます。",
                systemImage: "scalemass.fill"
            )
        }
    }

    // MARK: - .muscle

    @ViewBuilder
    private var muscleContent: some View {
        if ProGate.canSeeAdvancedAnalytics {
            MuscleGroupAnalysisSection(sets: allSets)
        } else {
            ProLockTile(
                title: "部位別分析",
                message: "週セット数と週ボリューム \(weightUnit.symbol) を部位別に可視化します。",
                systemImage: "rectangle.split.3x1.fill"
            )
        }
    }

    // MARK: - Weekly Volume

    @ViewBuilder
    private var weeklyVolumeCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label("週次総ボリューム", systemImage: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("直近 8 週")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            let nonZero = weeklySeries.filter { $0.total > 0 }
            if nonZero.isEmpty {
                Text("まだ記録がありません")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, OikomiSpacing.s)
            } else {
                Chart(weeklySeries) { point in
                    BarMark(
                        x: .value("週", point.weekStart, unit: .weekOfYear),
                        y: .value(
                            "総ボリューム (\(weightUnit.symbol))",
                            weightUnit.fromKilograms(point.total))
                    )
                    .foregroundStyle(OikomiColor.brandPrimary)
                    .clipShape(.rect(cornerRadius: 4))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine()
                        AxisValueLabel(
                            format: Date.VerbatimFormatStyle(
                                format: "\(month: .defaultDigits)/\(day: .defaultDigits)",
                                timeZone: .current,
                                calendar: .current
                            ),
                            centered: true
                        )
                    }
                }
            }
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    // MARK: - Exercise Trend

    @ViewBuilder
    private var exerciseTrendCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label("種目別の最大重量推移", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            Button {
                showingExercisePicker = true
            } label: {
                HStack {
                    Text(selectedExercise?.name ?? "種目を選択")
                        .foregroundStyle(selectedExercise == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(OikomiSpacing.m)
                .background(
                    OikomiColor.elevatedBackground,
                    in: RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous))
            }
            .buttonStyle(.plain)

            if selectedExercise != nil {
                let series = selectedExerciseSeries
                if series.isEmpty {
                    Text("この種目の記録がまだありません")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    Chart(series) { point in
                        LineMark(
                            x: .value("日付", point.date),
                            y: .value(
                                "重量 (\(weightUnit.symbol))",
                                weightUnit.fromKilograms(point.weight))
                        )
                        .foregroundStyle(OikomiColor.brandPrimary)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日付", point.date),
                            y: .value(
                                "重量 (\(weightUnit.symbol))",
                                weightUnit.fromKilograms(point.weight))
                        )
                        .foregroundStyle(OikomiColor.brandPrimary)
                    }
                    .frame(height: 200)
                }
            }
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    // MARK: - PRs

    @ViewBuilder
    private var prsCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(title: "自己ベスト一覧")
            if personalRecords.isEmpty {
                Text("まだ PR がありません")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(OikomiSpacing.l)
                    .background(
                        OikomiColor.cardBackground,
                        in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(personalRecords.enumerated()), id: \.element.id) { idx, pr in
                        prRow(pr)
                        if idx < personalRecords.count - 1 {
                            Divider().padding(.leading, OikomiSpacing.l)
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
    private func prRow(_ pr: PersonalRecord) -> some View {
        let content = HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exercise?.name ?? "（種目不明）")
                    .font(.body)
                Text(pr.achievedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(WeightFormatter.string(kilograms: pr.weight, in: weightUnit)) × \(pr.reps)")
                    .font(.body.monospacedDigit())
                Text("推定1RM \(WeightFormatter.oneRM(kilograms: pr.estimated1RM, in: weightUnit))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            if pr.exercise != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, OikomiSpacing.l)
        .padding(.vertical, OikomiSpacing.m)
        .contentShape(Rectangle())

        if let exercise = pr.exercise {
            NavigationLink(value: exercise) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

#Preview("Light") {
    AnalysisTabView()
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, Exercise.self, Routine.self,
                RoutineExercise.self, PersonalRecord.self, HealthSnapshot.self,
                MonthlySummary.self,
            ], inMemory: true)
}

#Preview("Dark") {
    AnalysisTabView()
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, Exercise.self, Routine.self,
                RoutineExercise.self, PersonalRecord.self, HealthSnapshot.self,
                MonthlySummary.self,
            ], inMemory: true
        )
        .preferredColorScheme(.dark)
}

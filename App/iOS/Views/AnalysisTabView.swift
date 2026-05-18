import Charts
import SwiftData
import SwiftUI
import OikomiKit

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
    @State private var showingProSheet = false

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
            Group {
                if !hasAnyData {
                    ContentUnavailableView(
                        "分析データなし",
                        systemImage: "chart.bar.xaxis",
                        description: Text("ワークアウトを完了すると、ここに推移が表示されます。")
                    )
                } else {
                    List {
                        if ProGate.canSeeAdvancedAnalytics {
                            weeklyVolumeSection
                            exerciseTrendSection
                        } else {
                            advancedAnalyticsLockedSection
                        }
                        prsSection
                    }
                }
            }
            .navigationTitle("分析")
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

    // MARK: - Pro Lock

    @ViewBuilder
    private var advancedAnalyticsLockedSection: some View {
        Section("詳細分析") {
            VStack(alignment: .leading, spacing: 8) {
                Label("Pro 限定", systemImage: "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                Text("週次総ボリュームと種目別の最大重量推移は Pro プランで閲覧できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Weekly Volume

    @ViewBuilder
    private var weeklyVolumeSection: some View {
        Section("週次総ボリューム（直近8週）") {
            let nonZero = weeklySeries.filter { $0.total > 0 }
            if nonZero.isEmpty {
                Text("まだ記録なし")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                Chart(weeklySeries) { point in
                    BarMark(
                        x: .value("週", point.weekStart, unit: .weekOfYear),
                        y: .value("総ボリューム (kg)", point.total)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Exercise Trend

    @ViewBuilder
    private var exerciseTrendSection: some View {
        Section("種目別の最大重量推移") {
            Button {
                showingExercisePicker = true
            } label: {
                HStack {
                    Text(selectedExercise?.name ?? "種目を選択")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            if let _ = selectedExercise {
                let series = selectedExerciseSeries
                if series.isEmpty {
                    Text("この種目の記録がまだありません")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    Chart(series) { point in
                        LineMark(
                            x: .value("日付", point.date),
                            y: .value("重量 (kg)", point.weight)
                        )
                        .foregroundStyle(Color.accentColor)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日付", point.date),
                            y: .value("重量 (kg)", point.weight)
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                    .frame(height: 200)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - PRs

    @ViewBuilder
    private var prsSection: some View {
        Section("自己ベスト一覧") {
            if personalRecords.isEmpty {
                Text("まだ PR がありません")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(personalRecords) { pr in
                    if let exercise = pr.exercise {
                        NavigationLink(value: exercise) {
                            prRow(pr)
                        }
                    } else {
                        prRow(pr)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func prRow(_ pr: PersonalRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exercise?.name ?? "（種目不明）")
                    .font(.body)
                Text(pr.achievedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(pr.weight.formatted())kg × \(pr.reps)")
                    .font(.body.monospacedDigit())
                Text("推定1RM \(pr.estimated1RM.formatted(.number.precision(.fractionLength(1))))kg")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    AnalysisTabView()
}

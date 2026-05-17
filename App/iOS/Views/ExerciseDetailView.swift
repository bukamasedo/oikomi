import Charts
import SwiftData
import SwiftUI
import OikomiKit

struct ExerciseDetailView: View {

    let exercise: Exercise

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var completedSessions: [WorkoutSession]

    @Query private var allPRs: [PersonalRecord]

    private var allSetsForExercise: [SetRecord] {
        let id = exercise.id
        return completedSessions
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
        return completedSessions
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
        List {
            metaSection
            prSection
            trendSection
            statsSection
            recentSetsSection
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var metaSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                if !exercise.nameEn.isEmpty {
                    Text(exercise.nameEn)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    ForEach(exercise.muscleGroups, id: \.self) { group in
                        Text(group.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var prSection: some View {
        Section("自己ベスト") {
            if let pr {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(pr.weight.formatted())kg × \(pr.reps)")
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                        Text(pr.achievedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("推定1RM")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(pr.estimated1RM.formatted(.number.precision(.fractionLength(1))))kg")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.tint)
                    }
                }
            } else {
                Text("まだ PR がありません")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }

    @ViewBuilder
    private var trendSection: some View {
        Section("最大重量の推移") {
            if weightTrend.count < 2 {
                Text("推移を表示するには 2 回以上の記録が必要です")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                Chart(weightTrend) { point in
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

    @ViewBuilder
    private var statsSection: some View {
        Section("累計") {
            LabeledContent("セッション数", value: "\(totalSessions)")
            LabeledContent("ワーキングセット数", value: "\(workingSets.count)")
            LabeledContent("総ボリューム (kg)", value: totalVolume.formatted(.number.precision(.fractionLength(0))))
        }
    }

    @ViewBuilder
    private var recentSetsSection: some View {
        Section("直近の記録") {
            if recentSets.isEmpty {
                Text("まだ記録なし")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(recentSets) { set in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.completedAt, style: .date)
                                .font(.subheadline)
                            if set.isWarmup {
                                Text("ウォームアップ")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if let weight = set.weight, let reps = set.reps {
                            Text("\(weight.formatted())kg × \(reps)")
                                .font(.body.monospacedDigit())
                        } else if let reps = set.reps {
                            Text("\(reps)レップ")
                                .font(.body.monospacedDigit())
                        }
                    }
                }
            }
        }
    }
}

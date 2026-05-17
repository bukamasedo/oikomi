import SwiftData
import SwiftUI
import OikomiKit

struct HomeView: View {

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var completedSessions: [WorkoutSession]

    @Query(sort: \PersonalRecord.achievedAt, order: .reverse)
    private var personalRecords: [PersonalRecord]

    private var streakDays: Int {
        Analytics.streakDays(sessions: completedSessions)
    }

    private var weeklyVolume: [(muscle: MuscleGroup, total: Double)] {
        let range = Analytics.currentWeekRange()
        let allSets = completedSessions.flatMap { $0.sets ?? [] }
        let byGroup = Analytics.volumeByMuscleGroup(sets: allSets, in: range)
        return byGroup
            .sorted { $0.value > $1.value }
            .map { (muscle: $0.key, total: $0.value) }
    }

    private var recentPRs: [PersonalRecord] {
        Array(personalRecords.prefix(5))
    }

    var body: some View {
        NavigationStack {
            List {
                if let active = activeSessions.first {
                    activeSection(active)
                }

                summarySection

                weeklyVolumeSection

                recentPRSection
            }
            .navigationTitle("ホーム")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func activeSection(_ session: WorkoutSession) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("進行中のワークアウト", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(session.sets?.count ?? 0) セット記録済み")
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(session.startedAt, style: .relative)
                    Text("前に開始")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        Section("今の状態") {
            LabeledContent("連続記録日数") {
                HStack(spacing: 4) {
                    if streakDays > 0 {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                    Text("\(streakDays) 日")
                        .font(.body.monospacedDigit())
                }
            }
            LabeledContent("総セッション数") {
                Text("\(completedSessions.count)")
                    .font(.body.monospacedDigit())
            }
            LabeledContent("総セット数") {
                let total = completedSessions.reduce(0) { $0 + ($1.sets?.count ?? 0) }
                Text("\(total)")
                    .font(.body.monospacedDigit())
            }
        }
    }

    @ViewBuilder
    private var weeklyVolumeSection: some View {
        Section("今週のボリューム（kg・部位別）") {
            if weeklyVolume.isEmpty {
                Text("今週はまだ記録なし")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(weeklyVolume.prefix(6), id: \.muscle) { entry in
                    HStack {
                        Text(entry.muscle.displayName)
                            .font(.body)
                        Spacer()
                        Text(entry.total.formatted(.number.precision(.fractionLength(0))))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentPRSection: some View {
        Section("直近の自己ベスト") {
            if recentPRs.isEmpty {
                Text("まだ PR がありません")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(recentPRs) { pr in
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
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

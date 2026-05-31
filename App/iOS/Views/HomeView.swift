import Charts
import OikomiKit
import SwiftData
import SwiftUI

/// Apple Fitness Summary + Health Summary に着想を得たホーム画面。
/// ScrollView ベースで自立カードを縦に積み、純正の "List + Section" 感を脱する。
struct HomeView: View {

    /// 進行中ワークアウトカードのタップでトレーニングタブへ切替えるための Binding。
    @Binding var selectedTab: ContentView.Tab

    /// フォアグラウンド復帰時にレディネスを取り直すためのシーンフェーズ監視。
    @Environment(\.scenePhase) private var scenePhase

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

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    @AppStorage(TrainingProfilePreference.experienceKey) private var experienceLevelRaw: String =
        TrainingProfile.default.experience.rawValue
    @AppStorage(TrainingProfilePreference.goalKey) private var trainingGoalRaw: String =
        TrainingProfile.default.goal.rawValue
    private var trainingProfile: TrainingProfile {
        TrainingProfile(
            experience: ExperienceLevel(rawValue: experienceLevelRaw) ?? .intermediate,
            goal: TrainingGoal(rawValue: trainingGoalRaw) ?? .hypertrophy)
    }

    @AppStorage(WeeklyTrainingTarget.storageKey) private var weeklyTargetDays: Int =
        WeeklyTrainingTarget.defaultDays

    /// HealthStore から算出した今日のレディネス。Pro 未契約や HealthKit 未認可では nil のまま。
    /// 値が入ると `coachingAdvice` のレディネス判定が動作し、TodayConditionCard にも表示される。
    @State private var readiness: ReadinessScore?

    @State private var bodyPhase: BodyPhaseResult?

    private var weeklyVolumeRange: ClosedRange<Date> { Analytics.currentWeekRange() }

    private var weekSessionDays: Int {
        Analytics.weeklySessionDays(sessions: completedSessions, in: weeklyVolumeRange)
    }

    private var consecutiveWeeks: Int {
        Analytics.consecutiveActiveWeeks(sessions: completedSessions)
    }

    private var weeklyVolumeByMuscle: [(muscle: MuscleGroup, total: Double)] {
        let allSets = completedSessions.flatMap { $0.sets ?? [] }
        let byGroup = Analytics.volumeByMuscleGroup(sets: allSets, in: weeklyVolumeRange)
        return
            byGroup
            .sorted { $0.value > $1.value }
            .map { (muscle: $0.key, total: $0.value) }
    }

    private var weeklyVolumeTotal: Double {
        weeklyVolumeByMuscle.reduce(0) { $0 + $1.total }
    }

    private var weeklySessionCount: Int {
        completedSessions.count(where: { weeklyVolumeRange.contains($0.startedAt) })
    }

    private var recentPRs: [PersonalRecord] {
        Array(personalRecords.prefix(5))
    }

    /// コーチング助言の全件（severity → impact 順）。ホームは先頭3件のみ表示し、
    /// 残りは見出しの「すべて見る」から `CoachingListView` で確認する。
    private var allCoaching: [CoachingAdvice] {
        guard ProGate.canUseAICoaching else { return [] }
        let allSets = completedSessions.flatMap { $0.sets ?? [] }
        return Analytics.combinedCoachingAdvice(
            sessions: completedSessions,
            sets: allSets,
            records: personalRecords,
            readiness: readiness,
            limit: .max,
            weightUnit: weightUnit,
            profile: trainingProfile,
            bodyPhase: bodyPhase
        )
    }

    private var activeSession: WorkoutSession? { activeSessions.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: OikomiSpacing.xl) {
                    if let active = activeSession {
                        resumeCard(active)
                    }

                    heroBlock

                    TodayConditionCard(readiness: readiness)

                    if !allCoaching.isEmpty {
                        coachingSection
                    }

                    if !recentPRs.isEmpty {
                        prHighlightsSection
                    }

                    weeklyVolumeSection
                }
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.bottom, OikomiSpacing.xxl)
            }
            .scrollContentBackground(.hidden)
            .background(OikomiColor.appBackground)
            .navigationTitle("ホーム")
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .task(id: ProGate.isProActive) {
                await refreshHealthSignals()
            }
            // 「今日のコンディション」が陳腐化しないよう、フォアグラウンド復帰時に取り直す。
            .task(id: scenePhase) {
                if scenePhase == .active {
                    await refreshHealthSignals()
                }
            }
        }
    }

    /// HealthStore から今日のレディネスを取り直す。Pro/権限がなければ nil。
    @MainActor
    private func refreshHealthSignals() async {
        guard ProGate.canReadHealthData else {
            readiness = nil
            bodyPhase = nil
            return
        }
        readiness = await HealthStore.shared.readinessSnapshot()
        bodyPhase = await HealthStore.shared.bodyPhase()
    }

    // MARK: - Resume card

    @ViewBuilder
    private func resumeCard(_ session: WorkoutSession) -> some View {
        Button {
            selectedTab = .workout
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                        .fill(OikomiColor.brandPrimary.opacity(0.18))
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("進行中のワークアウト")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(session.routine?.name ?? "ルーティンなし")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: OikomiSpacing.s) {
                        Label("\(session.sets?.count ?? 0) セット", systemImage: "list.bullet")
                        Label("\(session.startedAt, style: .timer)", systemImage: "timer")
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: OikomiSpacing.s)

                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(OikomiColor.brandPrimary, in: Circle())
            }
            .padding(OikomiSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .fill(OikomiColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .stroke(OikomiColor.brandPrimary.opacity(0.25), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("進行中のワークアウトを開く")
    }

    // MARK: - Hero block (WeeklyTargetRing + StatTile 2)

    @ViewBuilder
    private var heroBlock: some View {
        VStack(spacing: OikomiSpacing.l) {
            WeeklyTargetRing(
                daysThisWeek: weekSessionDays,
                target: weeklyTargetDays,
                consecutiveWeeks: consecutiveWeeks
            )
            .padding(.top, OikomiSpacing.s)

            HStack(spacing: OikomiSpacing.m) {
                StatTile(
                    title: "今週のセッション",
                    value: "\(weeklySessionCount)",
                    unit: "回",
                    caption: weeklySessionCount > 0 ? nil : "まだなし",
                    systemImage: "figure.strengthtraining.traditional",
                    tint: OikomiColor.brandPrimary
                )
                StatTile(
                    title: "今週のボリューム",
                    value: WeightFormatter.numberOnly(
                        kilograms: weeklyVolumeTotal, in: weightUnit, fractionDigits: 0...0),
                    unit: weightUnit.symbol,
                    systemImage: "scalemass.fill",
                    tint: OikomiColor.statBlue
                )
            }
        }
    }

    // MARK: - Coaching

    @ViewBuilder
    private var coachingSection: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(title: "コーチング") {
                if allCoaching.count > 3 {
                    NavigationLink {
                        CoachingListView(advice: allCoaching)
                    } label: {
                        Text("すべて見る")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: OikomiSpacing.m) {
                    ForEach(Array(allCoaching.prefix(3))) { advice in
                        CoachingChip(advice: advice)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    // MARK: - Recent PRs

    @ViewBuilder
    private var prHighlightsSection: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(title: "直近の自己ベスト")
            VStack(spacing: OikomiSpacing.m) {
                ForEach(recentPRs) { pr in
                    prCard(pr)
                }
            }
        }
    }

    @ViewBuilder
    private func prCard(_ pr: PersonalRecord) -> some View {
        Group {
            if let exercise = pr.exercise {
                NavigationLink(value: exercise) {
                    prCardContent(pr)
                }
                .buttonStyle(.plain)
            } else {
                prCardContent(pr)
            }
        }
    }

    @ViewBuilder
    private func prCardContent(_ pr: PersonalRecord) -> some View {
        HighlightCard(
            title: pr.exercise?.name ?? "（種目不明）",
            subtitle:
                "推定1RM \(WeightFormatter.oneRM(kilograms: pr.estimated1RM, in: weightUnit))・\(pr.achievedAt.formatted(.dateTime.month(.abbreviated).day()))",
            systemImage: "trophy.fill",
            iconTint: OikomiColor.brandSecondary
        ) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(WeightFormatter.string(kilograms: pr.weight, in: weightUnit))
                    .font(.headline.monospacedDigit())
                Text("× \(pr.reps)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weekly volume chart

    @ViewBuilder
    private var weeklyVolumeSection: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(title: "今週のボリューム", subtitle: "部位別合計 \(weightUnit.symbol)")

            if weeklyVolumeByMuscle.isEmpty {
                VStack(spacing: OikomiSpacing.s) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("今週はまだ記録なし")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(OikomiSpacing.xl)
                .background(
                    OikomiColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
            } else {
                volumeChart
            }
        }
    }

    @ViewBuilder
    private var volumeChart: some View {
        let topGroups = Array(weeklyVolumeByMuscle.prefix(6))
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            Chart(topGroups, id: \.muscle) { entry in
                BarMark(
                    x: .value("ボリューム", entry.total),
                    y: .value("部位", entry.muscle.displayName)
                )
                .foregroundStyle(by: .value("部位", entry.muscle.displayName))
                .annotation(position: .trailing, alignment: .leading) {
                    Text(entry.total.formatted(.number.precision(.fractionLength(0))))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .frame(height: CGFloat(topGroups.count) * 32 + 16)
        }
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }
}

#Preview("Light") {
    HomeView(selectedTab: .constant(.home))
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, PersonalRecord.self, Exercise.self,
                Routine.self, RoutineExercise.self, HealthSnapshot.self,
            ], inMemory: true)
}

#Preview("Dark") {
    HomeView(selectedTab: .constant(.home))
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, PersonalRecord.self, Exercise.self,
                Routine.self, RoutineExercise.self, HealthSnapshot.self,
            ], inMemory: true
        )
        .preferredColorScheme(.dark)
}

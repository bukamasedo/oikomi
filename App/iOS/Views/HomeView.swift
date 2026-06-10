import OikomiKit
import SwiftData
import SwiftUI
import WidgetKit

/// Apple Fitness Summary + Health Summary に着想を得たホーム画面。
/// ScrollView ベースで自立カードを縦に積み、純正の "List + Section" 感を脱する。
struct HomeView: View {

    /// 進行中ワークアウトカードのタップでトレーニングタブへ切替えるための Binding。
    @Binding var selectedTab: ContentView.Tab

    /// フォアグラウンド復帰時にレディネスを取り直すためのシーンフェーズ監視。
    @Environment(\.scenePhase) private var scenePhase

    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

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

    @Query(
        sort: [SortDescriptor(\Routine.lastUsedAt, order: .reverse), SortDescriptor(\Routine.createdAt)]
    )
    private var routines: [Routine]

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

    /// HealthStore から算出した今日のレディネス。Pro 未契約や HealthKit 未認可では nil のまま。
    /// 値が入ると `coachingAdvice` のレディネス判定が動作し、TodayConditionCard にも表示される。
    @State private var readiness: ReadinessScore?

    @State private var bodyPhase: BodyPhaseResult?

    /// 今日の HealthKit 値。TodayConditionCard の表示と、ウィジェット用スナップショット保存の
    /// 両方で使うため HomeView に集約する（card 側の二重 fetch を避ける）。
    @State private var todayHRV: Double?
    @State private var todayRHR: Double?
    @State private var todaySleepHours: Double?

    /// ルーティン開始に失敗したときのアラート文言。
    @State private var startError: String?

    /// 今日（曜日）に予定されているルーティン。`scheduledWeekdays` 未設定のものは含めない。
    private var todayRoutines: [Routine] {
        routines.filter { $0.isScheduled(on: Date()) }
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
                VStack(spacing: OikomiSpacing.l) {
                    TodayConditionCard(
                        readiness: readiness,
                        hrv: todayHRV,
                        rhr: todayRHR.map { Int($0.rounded()) },
                        sleepHours: todaySleepHours
                    )

                    if let active = activeSession {
                        resumeCard(active)
                    } else {
                        todayRoutineSection
                    }

                    if !recentPRs.isEmpty {
                        prHighlightsSection
                    }

                    if !allCoaching.isEmpty {
                        coachingSection
                    }
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
            .alert(
                "開始に失敗しました",
                isPresented: Binding(get: { startError != nil }, set: { if !$0 { startError = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if let startError { Text(startError) }
            }
            .task(id: ProGate.isProActive) {
                await refreshHealthSignals()
            }
            // 「今日のコンディション」が陳腐化しないよう、フォアグラウンド復帰時に取り直す。
            .task(id: scenePhase) {
                if scenePhase == .active {
                    await refreshHealthSignals()
                    maybeRequestReview()
                }
            }
        }
    }

    /// 完了セッション数が節目に達した「ポジティブな瞬間」に、控えめに App Store レビュー依頼を出す。
    ///
    /// 出すか／節目はすべて `ReviewRequestGate`（OikomiKit・テスト済み）が判定し、最終的な表示可否は
    /// OS（年3回まで）に委ねる。Watch で完了したワークアウトも同期済みデータから数えられる。
    @MainActor
    private func maybeRequestReview() {
        let repo = WorkoutSessionRepository(context: modelContext)
        guard let count = try? repo.completedSessionCount() else { return }
        guard let milestone = ReviewRequestGate.milestoneDue(completedSessionCount: count) else { return }
        requestReview()
        ReviewRequestGate.markRequested(milestone: milestone)
    }

    /// HealthStore から今日のレディネスを取り直す。Pro/権限がなければ nil。
    @MainActor
    private func refreshHealthSignals() async {
        guard ProGate.canReadHealthData else {
            readiness = nil
            bodyPhase = nil
            todayHRV = nil
            todayRHR = nil
            todaySleepHours = nil
            // 解約・権限喪失時にウィジェットへ古いコンディションを残さない。
            ConditionSnapshotStore.clear()
            WidgetCenter.shared.reloadTimelines(ofKind: "OikomiStatsWidget")
            return
        }
        // レディネスと今日値を並行取得し、card 表示とウィジェット保存の両方に使う。
        async let readinessTask = HealthStore.shared.readinessSnapshot()
        async let hrvTask = HealthStore.shared.todayValue(for: .hrv)
        async let rhrTask = HealthStore.shared.todayValue(for: .restingHeartRate)
        async let sleepTask = HealthStore.shared.todayValue(for: .sleepHours)
        async let bodyPhaseTask = HealthStore.shared.bodyPhase()

        let readinessValue = await readinessTask
        readiness = readinessValue
        todayHRV = await hrvTask
        todayRHR = await rhrTask
        todaySleepHours = await sleepTask
        bodyPhase = await bodyPhaseTask

        // ウィジェット（横長 = 今日のコンディション）へ最新値を共有。
        if let readinessValue {
            ConditionSnapshotStore.save(
                ConditionSnapshot(
                    readiness: readinessValue,
                    hrv: todayHRV,
                    restingHeartRate: todayRHR,
                    sleepHours: todaySleepHours
                )
            )
        } else {
            ConditionSnapshotStore.clear()
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "OikomiStatsWidget")
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
                    Text(session.routine?.name ?? String(localized: "ルーティンなし"))
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

    // MARK: - Today's routine

    /// 「今日のコンディション」カードに合わせ、見出しは出さずカード内にラベルを置く。
    /// 複数ルーティンがある場合は 1 枚のカードに区切り線で積む。
    @ViewBuilder
    private var todayRoutineSection: some View {
        if todayRoutines.isEmpty {
            emptyRoutineCard
        } else {
            VStack(alignment: .leading, spacing: OikomiSpacing.m) {
                Label("今日のルーティン", systemImage: "figure.strengthtraining.traditional")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.primary)

                VStack(spacing: 0) {
                    ForEach(Array(todayRoutines.enumerated()), id: \.element.id) { index, routine in
                        if index > 0 {
                            Divider()
                                .padding(.vertical, OikomiSpacing.m)
                        }
                        todayRoutineRow(routine)
                    }
                }
            }
            .padding(OikomiSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .fill(OikomiColor.cardBackground)
            )
        }
    }

    @ViewBuilder
    private func todayRoutineRow(_ routine: Routine) -> some View {
        HStack(spacing: OikomiSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                    .fill(OikomiColor.brandPrimary.opacity(0.18))
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandPrimary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(routineSummary(routine))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: OikomiSpacing.s)

            Button {
                startRoutine(routine)
            } label: {
                Label("開始", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, OikomiSpacing.m)
                    .padding(.vertical, OikomiSpacing.s)
                    .background(OikomiColor.brandPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "\(routine.name) を開始"))
        }
    }

    /// 「N 種目 · M セット」の要約。M は想定セット数の合計。
    private func routineSummary(_ routine: Routine) -> String {
        let exercises = routine.orderedExercises
        let sets = exercises.reduce(0) { $0 + $1.plannedSets }
        return String(localized: "\(exercises.count) 種目 · \(sets) セット")
    }

    /// 今日のスケジュールが無い日は、トレーニングタブでルーティンを選ぶ導線を出す。
    @ViewBuilder
    private var emptyRoutineCard: some View {
        Button {
            selectedTab = .workout
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title3)
                    .foregroundStyle(OikomiColor.brandPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日のルーティンは未設定")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("ルーティンを選んで始める")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(OikomiSpacing.l)
            .frame(maxWidth: .infinity)
            .background(
                OikomiColor.cardBackground,
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// ホームからルーティンを開始し、トレーニングタブへ遷移する。
    private func startRoutine(_ routine: Routine) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.startSession(routine: routine)
            selectedTab = .workout
        } catch {
            startError = error.localizedDescription
        }
    }

    // MARK: - Coaching

    /// 見出しはカード外ではなくカード内（アイコン付き）に置く。直近の自己ベスト・今日のルーティンと同じイディオム。
    /// 同種の助言（ボリューム不足・PR 更新など）は `groupedCoaching` でまとめ、対象を簡潔な行で並べる。
    @ViewBuilder
    private var coachingSection: some View {
        let groups = Analytics.groupedCoaching(allCoaching)
        let shownGroups = Array(groups.prefix(3))
        let homeItemCap = 3
        let hasMore =
            groups.count > shownGroups.count
            || shownGroups.contains { $0.items.count > homeItemCap }

        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Label("コーチング", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.primary)
                Spacer(minLength: OikomiSpacing.s)
                if hasMore {
                    NavigationLink {
                        CoachingListView(advice: allCoaching, weightUnit: weightUnit)
                    } label: {
                        Text("すべて見る")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }

            CoachingGroupedView(
                groups: shownGroups, maxItemsPerGroup: homeItemCap, weightUnit: weightUnit)
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }

    // MARK: - Recent PRs

    @ViewBuilder
    private var prHighlightsSection: some View {
        // 全完了セットは 1 回だけ平坦化し、各行のスパークライン算出に使い回す。
        let allSets = completedSessions.flatMap { $0.sets ?? [] }
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            // 見出しはカード外ではなくカード内に置く。
            Label("直近の自己ベスト", systemImage: "trophy.fill")
                .font(.subheadline.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.primary)
            ForEach(Array(recentPRs.enumerated()), id: \.element.id) { index, pr in
                if index > 0 {
                    Divider()
                }
                prRow(pr, allSets: allSets)
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }

    @ViewBuilder
    private func prRow(_ pr: PersonalRecord, allSets: [SetRecord]) -> some View {
        if let exercise = pr.exercise {
            NavigationLink(value: exercise) {
                prRowContent(pr, allSets: allSets)
            }
            .buttonStyle(.plain)
        } else {
            prRowContent(pr, allSets: allSets)
        }
    }

    private func prRowContent(_ pr: PersonalRecord, allSets: [SetRecord]) -> some View {
        // 推定 1RM 推移（表示単位に変換）。種目不明や記録 1 件なら空配列でグラフ非表示。
        let series: [Double] = {
            guard let id = pr.exercise?.id else { return [] }
            return Analytics.estimatedOneRMSeries(sets: allSets, forExerciseId: id)
                .map { weightUnit.fromKilograms($0.weight) }
        }()
        return PRHighlightRow(
            title: pr.exercise?.localizedName ?? String(localized: "（種目不明）"),
            subtitle: String(
                localized:
                    "推定1RM \(WeightFormatter.oneRM(kilograms: pr.estimated1RM, in: weightUnit))・\(pr.achievedAt.formatted(.dateTime.month(.abbreviated).day()))"
            ),
            weightText: WeightFormatter.string(kilograms: pr.weight, in: weightUnit),
            repsText: "× \(pr.reps)",
            series: series
        )
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

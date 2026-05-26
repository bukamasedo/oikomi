import OikomiKit
import SwiftData
import SwiftUI

/// ワークアウトタブ。開始前 / 進行中の 2 状態を扱う。
struct WorkoutTabView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @Query(sort: [SortDescriptor(\Routine.lastUsedAt, order: .reverse), SortDescriptor(\Routine.createdAt)])
    private var routines: [Routine]

    @State private var showingAddSetSheet = false
    @State private var preselectedExercise: Exercise?
    @State private var editingSetIntent: EditSetIntent?
    @State private var showingNewRoutine = false
    @State private var editingRoutine: Routine?
    @State private var errorMessage: String?
    @State private var confirmingFinish = false
    @State private var pendingExerciseDeletion: PendingExerciseDeletion?

    /// レストタイマー表示は `ContentView` の safeAreaInset で行うため、ここで観察するのは
    /// レイアウト調整 (scroll bottom padding) のためのみ。
    @State private var restStore = RestTimerStore.shared

    private var activeSession: WorkoutSession? { activeSessions.first }

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSession {
                    activeSessionView(session)
                } else {
                    startView
                }
            }
            .background(OikomiColor.appBackground)
            .navigationTitle(activeSession?.routine?.name ?? "トレーニング")
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingNewRoutine) {
                RoutineEditorView(existingRoutine: nil)
            }
            .sheet(item: $editingRoutine) { routine in
                RoutineEditorView(existingRoutine: routine)
            }
        }
    }

    // MARK: - 開始画面

    @ViewBuilder
    private var startView: some View {
        ScrollView {
            VStack(spacing: OikomiSpacing.xl) {
                quickStartButton

                if routines.isEmpty {
                    OikomiEmptyState(
                        title: "ルーティンがありません",
                        message: "よく使うトレーニングをルーティンとして保存しておくと、ワンタップで始められます。",
                        systemImage: "list.bullet.clipboard",
                        tint: OikomiColor.brandPrimary
                    ) {
                        Button {
                            showingNewRoutine = true
                        } label: {
                            Label("ルーティンを作成", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(OikomiColor.brandPrimary)
                    }
                    .frame(minHeight: 280)
                } else {
                    routineGrid
                }
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.bottom, OikomiSpacing.xxl)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewRoutine = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }

    @ViewBuilder
    private var quickStartButton: some View {
        Button {
            startSession(from: nil)
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                    Image(systemName: "play.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("クイック開始")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("ルーティンなしで今すぐスタート")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.subheadline.weight(.semibold))
            }
            .padding(OikomiSpacing.l)
            .background(
                LinearGradient(
                    colors: [OikomiColor.brandPrimary, OikomiColor.brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var routineGrid: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            SectionHeader(title: "ルーティン")
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: OikomiSpacing.m),
                    GridItem(.flexible(), spacing: OikomiSpacing.m),
                ],
                spacing: OikomiSpacing.m
            ) {
                ForEach(routines) { routine in
                    RoutineCard(routine: routine) {
                        startSession(from: routine)
                    }
                    .contextMenu {
                        Button {
                            editingRoutine = routine
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteRoutine(routine)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - 進行中画面

    @ViewBuilder
    private func activeSessionView(_ session: WorkoutSession) -> some View {
        ScrollView {
            VStack(spacing: OikomiSpacing.l) {
                sessionHero(session)

                ForEach(groupedExercises(session), id: \.0.id) { exercise, sets in
                    ExerciseInSessionCard(
                        exercise: exercise,
                        sets: sets,
                        onToggleSet: { set in
                            if set.isCompleted {
                                uncompleteSet(set)
                            } else {
                                completePlannedSet(set)
                            }
                        },
                        onAddSet: {
                            preselectedExercise = exercise
                            showingAddSetSheet = true
                        },
                        onDeleteSet: { set in
                            deleteSet(set)
                        },
                        onEditSet: { set in
                            editingSetIntent = EditSetIntent(set)
                        },
                        onDeleteExercise: {
                            pendingExerciseDeletion = PendingExerciseDeletion(
                                exercise: exercise, setCount: sets.count)
                        }
                    )
                }

                addExerciseCard
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.bottom, OikomiSpacing.xxl)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    confirmingFinish = true
                } label: {
                    Text("終了")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("ワークアウトを終了しますか？", isPresented: $confirmingFinish) {
            Button("終了する", role: .destructive) { finishSession(session) }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在のセッションを完了します。")
        }
        .alert(
            "種目を削除しますか？",
            isPresented: Binding(
                get: { pendingExerciseDeletion != nil },
                set: { if !$0 { pendingExerciseDeletion = nil } }
            ),
            presenting: pendingExerciseDeletion
        ) { pending in
            Button("削除する", role: .destructive) {
                deleteExerciseInSession(pending.exercise, in: session)
                pendingExerciseDeletion = nil
            }
            Button("キャンセル", role: .cancel) {
                pendingExerciseDeletion = nil
            }
        } message: { pending in
            Text(
                "「\(pending.exercise.name)」とこのセッション内の \(pending.setCount) 件のセットを削除します。"
            )
        }
        .sheet(isPresented: $showingAddSetSheet) {
            AddSetSheet(
                session: session,
                preselectedExercise: preselectedExercise,
                planMode: true,
                onSaved: { _ in }
            )
        }
        .sheet(item: $editingSetIntent) { intent in
            AddSetSheet(
                session: session,
                planMode: true,
                editingSet: intent.set,
                onSaved: { _ in }
            )
        }
    }

    /// `.sheet(item:)` 用ラッパ。SetRecord は @Model だが Identifiable 非準拠のため、
    /// 表示単位を Identifiable にして編集シートのプレゼンテーションを駆動する。
    private struct EditSetIntent: Identifiable {
        let id: UUID
        let set: SetRecord
        init(_ set: SetRecord) {
            self.id = set.id
            self.set = set
        }
    }

    /// 種目削除の確認ダイアログ駆動用ラッパ。
    private struct PendingExerciseDeletion: Identifiable {
        let id = UUID()
        let exercise: Exercise
        let setCount: Int
    }

    @ViewBuilder
    private func sessionHero(_ session: WorkoutSession) -> some View {
        let totalSets = session.sets?.count ?? 0
        let completedSets = session.sets?.filter(\.isCompleted).count ?? 0

        HStack(spacing: OikomiSpacing.l) {
            VStack(alignment: .leading, spacing: 4) {
                Text("経過時間")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(session.startedAt, style: .timer)
                    .font(OikomiFont.statValue)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)

            Divider().frame(height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("完了 / 計画")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(completedSets) / \(totalSets)")
                    .font(OikomiFont.statValue)
                    .lineLimit(1)
                    .foregroundStyle(
                        completedSets >= totalSets && totalSets > 0 ? Color.green : .primary
                    )
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer()
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }

    @ViewBuilder
    private var addExerciseCard: some View {
        Button {
            // 種目を明示的にクリアし、AddSetSheet 内でピッカー → 重量/レップ調整 → 保存の流れに統一
            preselectedExercise = nil
            showingAddSetSheet = true
        } label: {
            HStack(spacing: OikomiSpacing.s) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(OikomiColor.brandPrimary)
                Text("種目を追加")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(OikomiSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .strokeBorder(OikomiColor.brandPrimary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func groupedExercises(_ session: WorkoutSession) -> [(Exercise, [SetRecord])] {
        var firstAppearance: [UUID: Int] = [:]
        var byExercise: [UUID: (Exercise, [SetRecord])] = [:]
        for set in session.orderedSets {
            guard let ex = set.exercise else { continue }
            if firstAppearance[ex.id] == nil {
                firstAppearance[ex.id] = set.order
                byExercise[ex.id] = (ex, [])
            }
            byExercise[ex.id]?.1.append(set)
        }
        return byExercise.values.sorted { lhs, rhs in
            (firstAppearance[lhs.0.id] ?? 0) < (firstAppearance[rhs.0.id] ?? 0)
        }
    }

    private func completePlannedSet(_ set: SetRecord) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            let endAt = try repo.markSetCompleted(set)
            if let endAt {
                let total = set.restSeconds ?? set.exercise?.defaultRestSeconds ?? 60
                restStore.start(
                    endAt: endAt,
                    totalSeconds: total,
                    completedWeightKg: set.weight,
                    completedReps: set.reps
                )
                RestTimerNotifier.scheduleRestEnd(at: endAt)
            }
        } catch {
            errorMessage = "完了に失敗: \(error.localizedDescription)"
        }
    }

    /// 完了済みセットを未完了に戻す。間違ってチェックを入れた場合の取消。
    /// レストタイマーが起動中なら一緒にキャンセル。
    private func uncompleteSet(_ set: SetRecord) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.uncompleteSet(set)
            if restStore.endAt != nil {
                restStore.cancel()
                RestTimerNotifier.cancel()
            }
        } catch {
            errorMessage = "戻すのに失敗: \(error.localizedDescription)"
        }
    }

    private func deleteSet(_ set: SetRecord) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.deleteSet(set)
        } catch {
            errorMessage = "削除に失敗: \(error.localizedDescription)"
        }
    }

    private func deleteExerciseInSession(_ exercise: Exercise, in session: WorkoutSession) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.deleteExercise(exercise, from: session)
        } catch {
            errorMessage = "削除に失敗: \(error.localizedDescription)"
        }
    }

    private func startSession(from routine: Routine?) {
        let sessionRepo = WorkoutSessionRepository(context: modelContext)
        do {
            try sessionRepo.startSession(routine: routine)
        } catch {
            errorMessage = "開始に失敗: \(error.localizedDescription)"
        }
    }

    private func finishSession(_ session: WorkoutSession) {
        let repo = WorkoutSessionRepository(context: modelContext)
        Task { @MainActor in
            do {
                try await repo.finishSession(session)
                restStore.cancel()
            } catch {
                errorMessage = "終了に失敗: \(error.localizedDescription)"
            }
        }
    }

    private func deleteRoutine(_ routine: Routine) {
        let repo = RoutineRepository(context: modelContext)
        do {
            try repo.deleteRoutine(routine)
        } catch {
            errorMessage = "削除に失敗: \(error.localizedDescription)"
        }
    }
}

#Preview("Light") {
    WorkoutTabView()
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, Exercise.self, Routine.self,
                RoutineExercise.self, PersonalRecord.self, HealthSnapshot.self,
            ], inMemory: true)
}

#Preview("Dark") {
    WorkoutTabView()
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, Exercise.self, Routine.self,
                RoutineExercise.self, PersonalRecord.self, HealthSnapshot.self,
            ], inMemory: true
        )
        .preferredColorScheme(.dark)
}

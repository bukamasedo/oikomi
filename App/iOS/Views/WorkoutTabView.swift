import SwiftData
import SwiftUI
import OikomiKit

struct WorkoutTabView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @Query(sort: [SortDescriptor(\Routine.lastUsedAt, order: .reverse), SortDescriptor(\Routine.createdAt)])
    private var routines: [Routine]

    @State private var showingAddSetSheet = false
    @State private var preselectedExercise: Exercise?
    @State private var showingExercisePicker = false
    @State private var showingNewRoutine = false
    @State private var editingRoutine: Routine?
    @State private var errorMessage: String?
    @State private var restEndAt: Date?
    @State private var confirmingFinish = false

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
        List {
            Section("ルーティンから始める") {
                if routines.isEmpty {
                    Text("まだルーティンがありません")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(routines) { routine in
                        Button {
                            startSession(from: routine)
                        } label: {
                            routineRow(routine)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteRoutine(routine)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                            Button {
                                editingRoutine = routine
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }

                Button {
                    showingNewRoutine = true
                } label: {
                    Label("ルーティンを作成", systemImage: "plus.circle")
                }
            }

            Section {
                Button {
                    startSession(from: nil)
                } label: {
                    Label("ルーティンなしで開始", systemImage: "play")
                }
            }
        }
    }

    @ViewBuilder
    private func routineRow(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "play.fill")
                    .foregroundStyle(.tint)
                    .font(.caption)
            }
            let exerciseNames = routine.orderedExercises
                .compactMap(\.exercise?.name)
                .joined(separator: " / ")
            if !exerciseNames.isEmpty {
                Text(exerciseNames)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - 進行中画面

    @ViewBuilder
    private func activeSessionView(_ session: WorkoutSession) -> some View {
        List {
            ForEach(groupedExercises(session), id: \.0.id) { exercise, sets in
                exerciseSection(exercise: exercise, sets: sets)
            }

            Section {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("種目を追加", systemImage: "plus.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let endAt = restEndAt {
                RestTimerBanner(endAt: endAt) {
                    restEndAt = nil
                    RestTimerNotifier.cancel()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(uiColor: .systemGroupedBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: restEndAt)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text(session.startedAt, style: .timer)
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("終了") {
                    confirmingFinish = true
                }
                .foregroundStyle(.red)
            }
        }
        .confirmationDialog("ワークアウトを終了しますか？", isPresented: $confirmingFinish, titleVisibility: .visible) {
            Button("終了する", role: .destructive) { finishSession(session) }
            Button("キャンセル", role: .cancel) {}
        }
        .sheet(isPresented: $showingAddSetSheet) {
            AddSetSheet(
                session: session,
                preselectedExercise: preselectedExercise,
                planMode: true,
                onSaved: { _ in }
            )
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerSheet { picked in
                addExerciseToSession(picked, session: session)
            }
        }
    }

    /// セッション内のセットを種目別にグループ化（初出順）
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

    @ViewBuilder
    private func exerciseSection(exercise: Exercise, sets: [SetRecord]) -> some View {
        let completed = sets.filter(\.isCompleted).count
        Section {
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                setRow(set, indexInGroup: index + 1)
            }

            Button {
                preselectedExercise = exercise
                showingAddSetSheet = true
            } label: {
                Label("セット", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        } header: {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .textCase(nil)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(completed) / \(sets.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(completed >= sets.count && sets.count > 0 ? .green : .secondary)
            }
        }
    }

    @ViewBuilder
    private func setRow(_ set: SetRecord, indexInGroup: Int) -> some View {
        Button {
            if !set.isCompleted {
                completePlannedSet(set)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
                    .font(.title3)
                Text("\(indexInGroup)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 18, alignment: .leading)
                if let weight = set.weight, let reps = set.reps {
                    Text("\(weight.formatted())kg × \(reps)")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                } else if let reps = set.reps {
                    Text("\(reps)レップ（自重）")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                }
                Spacer()
                if set.isCompleted, let rm = set.estimated1RM {
                    Text("1RM \(rm.formatted(.number.precision(.fractionLength(0))))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteSet(set)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    /// セット保存後にレストタイマーを起動する（addSet パスのレガシー）。
    private func handleSetSaved(_ set: SetRecord) {
        guard let rest = set.exercise?.defaultRestSeconds, rest > 0 else {
            restEndAt = nil
            return
        }
        let endAt = Date().addingTimeInterval(TimeInterval(rest))
        restEndAt = endAt
        RestTimerNotifier.scheduleRestEnd(at: endAt)
    }

    private func completePlannedSet(_ set: SetRecord) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            let endAt = try repo.markSetCompleted(set)
            if let endAt {
                restEndAt = endAt
                RestTimerNotifier.scheduleRestEnd(at: endAt)
            }
        } catch {
            errorMessage = "完了に失敗: \(error.localizedDescription)"
        }
    }

    private func deleteSet(_ set: SetRecord) {
        modelContext.delete(set)
        try? modelContext.save()
    }

    private func addExerciseToSession(_ exercise: Exercise, session: WorkoutSession) {
        // 直近の同種目セットから weight/reps を補完
        let lastForExercise = session.orderedSets.last { $0.exercise?.id == exercise.id }
        let useBodyweight = exercise.measurementType == .bodyweightReps
        let weight = useBodyweight ? nil : (lastForExercise?.weight ?? 20)
        let reps = lastForExercise?.reps ?? 8
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            _ = try repo.addPlannedSet(to: session, exercise: exercise, weight: weight, reps: reps)
        } catch {
            errorMessage = "種目追加に失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - Actions

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
                restEndAt = nil
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

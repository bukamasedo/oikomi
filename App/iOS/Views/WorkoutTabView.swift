import SwiftData
import SwiftUI
import OikomiKit

struct WorkoutTabView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @Query(sort: [SortDescriptor(\Routine.lastUsedAt, order: .reverse), SortDescriptor(\Routine.createdAt)])
    private var routines: [Routine]

    @State private var showingAddSet = false
    @State private var preselectedExercise: Exercise?
    @State private var showingNewRoutine = false
    @State private var editingRoutine: Routine?
    @State private var errorMessage: String?
    @State private var restEndAt: Date?

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
            .navigationTitle("トレーニング")
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
        VStack(spacing: 0) {
            List {
                Section {
                    HStack {
                        Text("開始")
                        Spacer()
                        Text(session.startedAt, style: .time)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("経過")
                        Spacer()
                        Text(session.startedAt, style: .timer)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                // ルーティンの種目をクイック選択肢として表示（進捗バー付き）
                if let routine = session.routine {
                    Section("ルーティン: \(routine.name)") {
                        ForEach(routine.orderedExercises) { entry in
                            routineEntryRow(entry: entry, in: session)
                        }
                    }
                }

                Section("記録済みセット") {
                    let sets = session.orderedSets
                    if sets.isEmpty {
                        Text("まだ記録なし")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sets) { set in
                            setRow(set)
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                if let endAt = restEndAt {
                    RestTimerBanner(endAt: endAt) {
                        restEndAt = nil
                    }
                }

                Button {
                    preselectedExercise = nil
                    showingAddSet = true
                } label: {
                    Label("セットを記録", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    finishSession(session)
                } label: {
                    Label("ワークアウトを終了", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingAddSet) {
            AddSetSheet(
                session: session,
                preselectedExercise: preselectedExercise,
                onSaved: handleSetSaved
            )
        }
    }

    /// セット保存後にレストタイマーを起動する。
    private func handleSetSaved(_ set: SetRecord) {
        guard let rest = set.exercise?.defaultRestSeconds, rest > 0 else {
            restEndAt = nil
            return
        }
        restEndAt = Date().addingTimeInterval(TimeInterval(rest))
    }

    @ViewBuilder
    private func setRow(_ set: SetRecord) -> some View {
        HStack {
            Text("\(set.order + 1)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(set.exercise?.name ?? "（種目不明）")
                    .font(.body)
                if let weight = set.weight, let reps = set.reps {
                    Text("\(weight.formatted())kg × \(reps)レップ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let reps = set.reps {
                    Text("\(reps)レップ（自重）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let rm = set.estimated1RM {
                Text("推定1RM \(rm.formatted(.number.precision(.fractionLength(1))))kg")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
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

    /// ルーティン進捗行: 種目名 + 完了/想定セット数 + クイック追加ボタン
    @ViewBuilder
    private func routineEntryRow(entry: RoutineExercise, in session: WorkoutSession) -> some View {
        let completedCount = (session.sets ?? []).filter {
            !$0.isWarmup && $0.exercise?.id == entry.exercise?.id
        }.count
        let planned = entry.plannedSets
        let isComplete = completedCount >= planned

        Button {
            if let exercise = entry.exercise {
                preselectedExercise = exercise
                showingAddSet = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isComplete ? .green : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.exercise?.name ?? "（種目なし）")
                        .foregroundStyle(.primary)
                    Text("\(completedCount) / \(planned) セット")
                        .font(.caption)
                        .foregroundStyle(isComplete ? .green : .secondary)
                        .monospacedDigit()
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
    }
}

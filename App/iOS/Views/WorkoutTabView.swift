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

                // ルーティンの種目をクイック選択肢として表示
                let routineExercises = currentRoutineExercises(for: session)
                if !routineExercises.isEmpty {
                    Section("クイック追加") {
                        ForEach(routineExercises) { exercise in
                            Button {
                                preselectedExercise = exercise
                                showingAddSet = true
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
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
            AddSetSheet(session: session, preselectedExercise: preselectedExercise)
        }
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
        let routineRepo = RoutineRepository(context: modelContext)
        do {
            try sessionRepo.startSession()
            if let routine {
                try routineRepo.markUsed(routine)
            }
        } catch {
            errorMessage = "開始に失敗: \(error.localizedDescription)"
        }
    }

    private func finishSession(_ session: WorkoutSession) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.finishSession(session)
        } catch {
            errorMessage = "終了に失敗: \(error.localizedDescription)"
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

    /// 進行中セッションで使うルーティンの種目を推定する。
    ///
    /// 現状はシンプルに「直近で markUsed されたルーティン」（先頭）の種目を返す。
    /// より厳密にはセッションにルーティン参照を持たせるべきだが、v0.1 ではこれで十分。
    private func currentRoutineExercises(for session: WorkoutSession) -> [Exercise] {
        guard let lastUsedRoutine = routines.first(where: { $0.lastUsedAt != nil }),
            let lastUsedAt = lastUsedRoutine.lastUsedAt,
            // セッション開始の±10秒以内 = このセッション用のルーティン
            abs(lastUsedAt.timeIntervalSince(session.startedAt)) < 10
        else {
            return []
        }
        return lastUsedRoutine.orderedExercises.compactMap(\.exercise)
    }
}

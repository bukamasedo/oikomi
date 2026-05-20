import SwiftData
import SwiftUI
import OikomiKit

struct WatchActiveSessionView: View {

    @Environment(\.modelContext) private var modelContext

    let session: WorkoutSession

    @State private var showingAddSet = false
    @State private var showingExercisePicker = false
    @State private var preselectedExercise: Exercise?
    @State private var editingPlannedSet: SetRecord?
    @State private var errorMessage: String?
    @State private var restEndAt: Date?
    @State private var confirmingFinish = false
    @State private var healthSession = WatchHealthSession()

    var body: some View {
        List {
            if let endAt = restEndAt {
                Section {
                    WatchRestTimerView(endAt: endAt) {
                        restEndAt = nil
                        RestTimerNotifier.cancel()
                    }
                }
                .listRowBackground(Color.clear)
            }

            ForEach(groupedExercises(session), id: \.0.id) { exercise, sets in
                exerciseSection(exercise: exercise, sets: sets)
            }

            Button {
                showingExercisePicker = true
            } label: {
                Label("種目を追加", systemImage: "plus.circle")
                    .font(.caption)
            }
        }
        .navigationTitle(session.routine?.name ?? "進行中")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    confirmingFinish = true
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showingAddSet) {
            WatchAddSetView(session: session, preselectedExercise: preselectedExercise)
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                WatchExercisePicker { picked in
                    addExerciseToSession(picked)
                }
            }
        }
        .sheet(item: $editingPlannedSet) { plannedSet in
            WatchAddSetView(session: session, editingPlannedSet: plannedSet) { restEnd in
                restEndAt = restEnd
            }
        }
        .confirmationDialog("ワークアウトを終了しますか？", isPresented: $confirmingFinish, titleVisibility: .visible) {
            Button("終了する", role: .destructive) { finishSession() }
            Button("キャンセル", role: .cancel) {}
        }
        .task {
            await healthSession.start()
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
            ForEach(sets) { set in
                setRow(set)
            }
            Button {
                preselectedExercise = exercise
                showingAddSet = true
            } label: {
                Label("セット", systemImage: "plus.circle")
                    .font(.caption2)
            }
        } header: {
            HStack {
                Text(exercise.name)
                    .font(.caption.weight(.semibold))
                    .textCase(nil)
                Spacer()
                Text("\(completed)/\(sets.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(completed >= sets.count && sets.count > 0 ? .green : .secondary)
            }
        }
    }

    @ViewBuilder
    private func setRow(_ set: SetRecord) -> some View {
        Button {
            if !set.isCompleted {
                completePlanned(set)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
                if let w = set.weight, let r = set.reps {
                    Text("\(w.formatted())kg × \(r)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                } else if let r = set.reps {
                    Text("\(r)レップ")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                }
                Spacer()
                if !set.isCompleted {
                    Button {
                        editingPlannedSet = set
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func completePlanned(_ set: SetRecord) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            let endAt = try repo.markSetCompleted(set)
            if let endAt {
                restEndAt = endAt
                RestTimerNotifier.scheduleRestEnd(at: endAt)
            }
        } catch {
            errorMessage = "完了失敗: \(error.localizedDescription)"
        }
    }

    private func addExerciseToSession(_ exercise: Exercise) {
        let lastForExercise = session.orderedSets.last { $0.exercise?.id == exercise.id }
        let useBodyweight = exercise.measurementType == .bodyweightReps
        let weight = useBodyweight ? nil : (lastForExercise?.weight ?? 20)
        let reps = lastForExercise?.reps ?? 8
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            _ = try repo.addPlannedSet(to: session, exercise: exercise, weight: weight, reps: reps)
        } catch {
            errorMessage = "種目追加失敗: \(error.localizedDescription)"
        }
    }

    private func finishSession() {
        let repo = WorkoutSessionRepository(context: modelContext)
        Task { @MainActor in
            // 順序が重要: HKWorkoutSession.end() を呼ぶと watchOS がアプリの
            // foreground 特権を解除し、後続の WC 送信がサスペンドで失敗する恐れがある。
            // 先にローカル save + WC 送信 + Live Activity end を完了させる。
            // HK 書き込みは下の healthSession.end() の builder.finishWorkout に
            // 一任して二重書き込みを避ける（HealthStore.saveWorkout は使わない）。
            do {
                try await repo.finishSession(session, writeToHealthKit: false)
            } catch {
                errorMessage = "終了失敗: \(error.localizedDescription)"
            }
            // HKWorkoutSession を終了してリング貢献。失敗しても同期は既に完了済み。
            await healthSession.end()
        }
    }
}

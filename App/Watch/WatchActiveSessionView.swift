import SwiftData
import SwiftUI
import OikomiKit

struct WatchActiveSessionView: View {

    @Environment(\.modelContext) private var modelContext

    let session: WorkoutSession

    @State private var showingAddSet = false
    @State private var preselectedExercise: Exercise?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "timer")
                    Text(session.startedAt, style: .timer)
                        .monospacedDigit()
                }
                .font(.subheadline)
            }

            // ルーティン種目をクイック追加
            if let routine = session.routine {
                Section("ルーティン") {
                    ForEach(routine.orderedExercises) { entry in
                        Button {
                            preselectedExercise = entry.exercise
                            showingAddSet = true
                        } label: {
                            entryRow(entry)
                        }
                    }
                }
            }

            Section("セット") {
                let sets = session.orderedSets
                if sets.isEmpty {
                    Text("まだ記録なし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sets) { set in
                        setRow(set)
                    }
                }
            }

            Section {
                Button {
                    preselectedExercise = nil
                    showingAddSet = true
                } label: {
                    Label("セット追加", systemImage: "plus.circle.fill")
                }
                Button(role: .destructive) {
                    finishSession()
                } label: {
                    Label("終了", systemImage: "stop.fill")
                }
            }
        }
        .navigationTitle("進行中")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSet) {
            WatchAddSetView(session: session, preselectedExercise: preselectedExercise)
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: RoutineExercise) -> some View {
        let completed = (session.sets ?? []).filter {
            !$0.isWarmup && $0.exercise?.id == entry.exercise?.id
        }.count
        let isComplete = completed >= entry.plannedSets

        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? .green : .secondary)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.exercise?.name ?? "—")
                    .font(.caption)
                Text("\(completed)/\(entry.plannedSets)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private func setRow(_ set: SetRecord) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(set.exercise?.name ?? "—")
                .font(.caption)
            HStack(spacing: 4) {
                if let weight = set.weight, let reps = set.reps {
                    Text("\(weight.formatted())kg × \(reps)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else if let reps = set.reps {
                    Text("\(reps)レップ")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func finishSession() {
        let repo = WorkoutSessionRepository(context: modelContext)
        Task { @MainActor in
            do {
                try await repo.finishSession(session)
            } catch {
                errorMessage = "終了失敗: \(error.localizedDescription)"
            }
        }
    }
}

import SwiftData
import SwiftUI
import OikomiKit

struct WorkoutTabView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @State private var showingAddSet = false
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
        }
    }

    @ViewBuilder
    private var startView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("ワークアウトを始める")
                .font(.title2.weight(.semibold))

            Button {
                startSession()
            } label: {
                Label("開始", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
    }

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
            AddSetSheet(session: session)
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

    private func startSession() {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.startSession()
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
}

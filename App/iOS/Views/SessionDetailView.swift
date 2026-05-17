import SwiftData
import SwiftUI
import OikomiKit

struct SessionDetailView: View {

    @Environment(\.modelContext) private var modelContext

    let session: WorkoutSession

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @State private var showingCopyConfirmation = false
    @State private var showingActiveBlockedAlert = false
    @State private var errorMessage: String?

    private var setsByExercise: [(exerciseName: String, sets: [SetRecord])] {
        let grouped = Dictionary(grouping: session.orderedSets) { set in
            set.exercise?.name ?? "（種目不明）"
        }
        return grouped
            .map { (exerciseName: $0.key, sets: $0.value.sorted { $0.order < $1.order }) }
            .sorted { $0.sets.first?.order ?? 0 < $1.sets.first?.order ?? 0 }
    }

    var body: some View {
        List {
            Section("セッション") {
                LabeledContent("日付") {
                    Text(session.startedAt, style: .date)
                }
                LabeledContent("開始") {
                    Text(session.startedAt, style: .time)
                }
                if let endedAt = session.endedAt {
                    LabeledContent("終了") {
                        Text(endedAt, style: .time)
                    }
                }
                if let duration = session.durationSeconds {
                    LabeledContent("所要時間") {
                        Text(formatDuration(duration))
                    }
                }
                LabeledContent("総セット数") {
                    Text("\(session.sets?.count ?? 0)")
                }
                if let routine = session.routine {
                    LabeledContent("ルーティン") {
                        Text(routine.name)
                    }
                }
            }

            ForEach(setsByExercise, id: \.exerciseName) { group in
                Section(group.exerciseName) {
                    ForEach(group.sets) { set in
                        HStack {
                            Text("セット \(set.order + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let weight = set.weight, let reps = set.reps {
                                Text("\(weight.formatted())kg × \(reps)")
                                    .font(.body.monospacedDigit())
                            } else if let reps = set.reps {
                                Text("\(reps)レップ")
                                    .font(.body.monospacedDigit())
                            }
                            if let rm = set.estimated1RM {
                                Text("1RM \(rm.formatted(.number.precision(.fractionLength(1))))kg")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if activeSessions.isEmpty {
                        showingCopyConfirmation = true
                    } else {
                        showingActiveBlockedAlert = true
                    }
                } label: {
                    Label("コピーして開始", systemImage: "doc.on.doc")
                }
                .disabled(session.endedAt == nil)
            }
        }
        .confirmationDialog(
            "このセッションをコピーして開始しますか？",
            isPresented: $showingCopyConfirmation,
            titleVisibility: .visible
        ) {
            Button("コピーして開始") { copySession() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(session.sets?.count ?? 0) セットを複製して新しいワークアウトを開始します。")
        }
        .alert("進行中のセッションがあります", isPresented: $showingActiveBlockedAlert) {
            Button("OK") {}
        } message: {
            Text("先に進行中のワークアウトを終了してください。")
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func copySession() {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.startSessionByCopying(session)
            // トレーニングタブで続けてもらう（タブ遷移は呼び出し側が把握）
        } catch {
            errorMessage = "コピーに失敗: \(error.localizedDescription)"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes)分"
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return "\(hours)時間\(remaining)分"
    }
}

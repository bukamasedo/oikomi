import SwiftData
import SwiftUI
import OikomiKit

struct WatchHomeView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Routine.lastUsedAt, order: .reverse), SortDescriptor(\Routine.createdAt)])
    private var routines: [Routine]

    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Button {
                    startSession(from: nil)
                } label: {
                    Label("ワークアウト開始", systemImage: "play.fill")
                        .font(.body.weight(.semibold))
                }
            }

            if !routines.isEmpty {
                Section("ルーティン") {
                    ForEach(routines) { routine in
                        Button {
                            startSession(from: routine)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.name)
                                    .font(.body)
                                Text("\(routine.orderedExercises.count) 種目")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Oikomi")
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func startSession(from routine: Routine?) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.startSession(routine: routine)
        } catch {
            errorMessage = "開始失敗: \(error.localizedDescription)"
        }
    }
}

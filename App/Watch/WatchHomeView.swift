import OikomiKit
import SwiftData
import SwiftUI

/// watchOS のホーム。ルーティン一覧のみ表示し、選択でセッション開始。
///
/// 計画系操作（ルーティン作成・種目追加）は iPhone 専任。Watch ではあらかじめ
/// 用意されたルーティンを実行するだけに絞る。
struct WatchHomeView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: [
            SortDescriptor(\Routine.lastUsedAt, order: .reverse),
            SortDescriptor(\Routine.createdAt),
        ]
    )
    private var routines: [Routine]

    @State private var errorMessage: String?

    var body: some View {
        Group {
            if routines.isEmpty {
                emptyState
            } else {
                routineList
            }
        }
        .navigationTitle("Oikomi")
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var routineList: some View {
        List {
            Section("ルーティン") {
                ForEach(routines) { routine in
                    Button {
                        startSession(from: routine)
                    } label: {
                        routineRow(routine)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView(
            "ルーティンがありません",
            systemImage: "iphone.gen3",
            description: Text("iPhone で最初のルーティンを作成してください")
        )
    }

    @ViewBuilder
    private func routineRow(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: WatchSpacing.s) {
                Text(routine.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(WatchColor.brand)
            }
            HStack(spacing: WatchSpacing.s) {
                Text("\(routine.orderedExercises.count) 種目")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let last = routine.lastUsedAt {
                    Text("・")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(last, format: .relative(presentation: .numeric))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Actions

    private func startSession(from routine: Routine) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.startSession(routine: routine)
        } catch {
            errorMessage = "開始失敗: \(error.localizedDescription)"
        }
    }
}

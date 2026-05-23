import OikomiKit
import SwiftData
import SwiftUI

/// watchOS のホーム。ルーティン選択 + クイック開始。
///
/// iPhone の WorkoutTabView 開始前画面と同じ思想 (上にクイック開始 hero、下にルーティン)、
/// ただし Watch の画面制約に合わせて List ベース + 各行は1〜2行に収める。
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
        List {
            Section {
                quickStartButton
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            if !routines.isEmpty {
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
        .navigationTitle("Oikomi")
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var quickStartButton: some View {
        Button {
            startSession(from: nil)
        } label: {
            HStack(spacing: WatchSpacing.m) {
                ZStack {
                    Circle().fill(.white.opacity(0.22))
                    Image(systemName: "play.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text("クイック開始")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("ルーティンなし")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, WatchSpacing.m)
            .padding(.vertical, WatchSpacing.m)
            .background(
                LinearGradient(
                    colors: [WatchColor.brand, WatchColor.brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
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

    private func startSession(from routine: Routine?) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.startSession(routine: routine)
        } catch {
            errorMessage = "開始失敗: \(error.localizedDescription)"
        }
    }
}

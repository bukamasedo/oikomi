import SwiftData
import SwiftUI
import OikomiKit

/// 検索 + 部位フィルタつきの種目選択シート。
///
/// `AddSetSheet` と `RoutineEditorView` の両方から呼ばれる共通ピッカー。
/// 単一選択モードで動作し、選択された Exercise を `onPick` で返す。
struct ExercisePickerSheet: View {

    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    /// 結果から除外する種目（ルーティン編集時の重複防止に使う）
    let excluding: [Exercise]

    /// 確定時のコールバック
    let onPick: (Exercise) -> Void

    @State private var searchText: String = ""
    @State private var selectedFilter: MuscleGroup?

    init(excluding: [Exercise] = [], onPick: @escaping (Exercise) -> Void) {
        self.excluding = excluding
        self.onPick = onPick
    }

    private var filtered: [Exercise] {
        let excludedIds = Set(excluding.map(\.id))
        return allExercises.filter { exercise in
            if excludedIds.contains(exercise.id) { return false }
            if let filter = selectedFilter, !exercise.muscleGroups.contains(filter) { return false }
            if searchText.isEmpty { return true }
            let query = searchText.lowercased()
            return exercise.name.lowercased().contains(query)
                || exercise.nameEn.lowercased().contains(query)
        }
    }

    private var availableMuscleFilters: [MuscleGroup] {
        // データに存在する部位のみを表示
        let all = Set(allExercises.flatMap(\.muscleGroups))
        return MuscleGroup.allCases.filter { all.contains($0) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemBackground))

                List {
                    if filtered.isEmpty {
                        ContentUnavailableView(
                            "種目が見つかりません",
                            systemImage: "magnifyingglass",
                            description: Text("検索ワードやフィルタを調整してください")
                        )
                    } else {
                        ForEach(filtered) { exercise in
                            Button {
                                onPick(exercise)
                                dismiss()
                            } label: {
                                row(exercise)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("種目を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "種目名で検索")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "すべて", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(availableMuscleFilters, id: \.self) { group in
                    chip(label: group.displayName, isSelected: selectedFilter == group) {
                        selectedFilter = selectedFilter == group ? nil : group
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func row(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .foregroundStyle(.primary)
                .font(.body)
            HStack(spacing: 8) {
                let groups = exercise.muscleGroups.prefix(3).map(\.displayName).joined(separator: " / ")
                if !groups.isEmpty {
                    Text(groups)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(equipmentLabel(exercise.equipment))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func equipmentLabel(_ equipment: Equipment) -> String {
        switch equipment {
        case .barbell: return "バーベル"
        case .dumbbell: return "ダンベル"
        case .machine: return "マシン"
        case .cable: return "ケーブル"
        case .bodyweight: return "自重"
        case .kettlebell: return "ケトルベル"
        case .band: return "バンド"
        case .other: return "その他"
        }
    }
}

import OikomiKit
import SwiftData
import SwiftUI

/// 検索 + 部位フィルタつきの種目選択シート。
///
/// `AddSetSheet` と `RoutineEditorView` の両方から呼ばれる共通ピッカー。
/// 単一選択モードで動作し、選択された Exercise を `onPick` で返す。
struct ExercisePickerSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    /// 結果から除外する種目（ルーティン編集時の重複防止に使う）
    let excluding: [Exercise]

    /// 確定時のコールバック
    let onPick: (Exercise) -> Void

    @State private var searchText: String = ""
    @State private var selectedFilter: MuscleGroup?
    @State private var favoritesOnly: Bool = false
    @State private var showingCreateForm: Bool = false

    init(excluding: [Exercise] = [], onPick: @escaping (Exercise) -> Void) {
        self.excluding = excluding
        self.onPick = onPick
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 873 種をキー入力ごとに 3 重に走査していた箇所をワンパス化して入力遅延を解消する。
    /// `muscleGroups` getter は内部で compactMap が走るので、フィルタ時は raw value で比較する。
    private var filterResult: (favorites: [Exercise], others: [Exercise]) {
        let excludedIds = Set(excluding.map(\.id))
        let query = trimmedSearch
        let hasQuery = !query.isEmpty
        let filterRaw = selectedFilter?.rawValue

        var favorites: [Exercise] = []
        var others: [Exercise] = []
        favorites.reserveCapacity(32)
        others.reserveCapacity(allExercises.count)

        for exercise in allExercises {
            if excludedIds.contains(exercise.id) { continue }
            if favoritesOnly && !exercise.isFavorite { continue }
            if let filterRaw, !exercise.muscleGroupRawValues.contains(filterRaw) { continue }
            if hasQuery {
                if !exercise.name.localizedCaseInsensitiveContains(query)
                    && !exercise.nameEn.localizedCaseInsensitiveContains(query)
                {
                    continue
                }
            }
            if exercise.isFavorite {
                favorites.append(exercise)
            } else {
                others.append(exercise)
            }
        }
        return (favorites, others)
    }

    /// データに存在する部位のみを表示。allExercises 変更時にだけ更新し、毎キー走査を避ける。
    @State private var availableMuscleFilters: [MuscleGroup] = []

    var body: some View {
        let result = filterResult
        let isEmpty = result.favorites.isEmpty && result.others.isEmpty

        return NavigationStack {
            VStack(spacing: 0) {
                filterChips
                    .padding(.vertical, 8)
                    .background(.background)

                Group {
                    if isEmpty {
                        OikomiEmptyState(
                            title: String(localized: "種目が見つかりません"),
                            message: trimmedSearch.isEmpty
                                ? String(localized: "検索ワードやフィルタを調整してください")
                                : String(
                                    localized:
                                        "「\(trimmedSearch)」はライブラリにありません。カスタム種目として作成できます。"),
                            systemImage: "magnifyingglass",
                            tint: OikomiColor.brandPrimary
                        ) {
                            if !trimmedSearch.isEmpty {
                                Button {
                                    showingCreateForm = true
                                } label: {
                                    Label("「\(trimmedSearch)」を新規作成", systemImage: "plus.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(OikomiColor.brandPrimary)
                            }
                        }
                    } else {
                        List {
                            if !result.favorites.isEmpty {
                                Section("お気に入り") {
                                    ForEach(result.favorites) { exercise in
                                        exerciseRowButton(exercise)
                                    }
                                }
                            }
                            Section(result.favorites.isEmpty ? "" : String(localized: "すべての種目")) {
                                ForEach(result.others) { exercise in
                                    exerciseRowButton(exercise)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("種目を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "種目名で検索")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateForm = true
                    } label: {
                        Label("新規作成", systemImage: "plus")
                    }
                }
            }
            .onAppear { refreshAvailableMuscleFilters() }
            .onChange(of: allExercises.count) { _, _ in refreshAvailableMuscleFilters() }
            .sheet(isPresented: $showingCreateForm) {
                CustomExerciseFormSheet(initialName: trimmedSearch) { created in
                    // 作成済み Exercise を呼び出し元に返し、ピッカー自身も閉じる
                    onPick(created)
                    dismiss()
                }
            }
        }
    }

    private func refreshAvailableMuscleFilters() {
        var seen: Set<String> = []
        for exercise in allExercises {
            for raw in exercise.muscleGroupRawValues {
                seen.insert(raw)
            }
        }
        availableMuscleFilters = MuscleGroup.allCases.filter { seen.contains($0.rawValue) }
    }

    @ViewBuilder
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: String(localized: "すべて"), isSelected: selectedFilter == nil && !favoritesOnly) {
                    selectedFilter = nil
                    favoritesOnly = false
                }
                chip(label: String(localized: "★ お気に入り"), isSelected: favoritesOnly) {
                    favoritesOnly.toggle()
                    if favoritesOnly { selectedFilter = nil }
                }
                ForEach(availableMuscleFilters, id: \.self) { group in
                    chip(label: group.displayName, isSelected: selectedFilter == group) {
                        selectedFilter = selectedFilter == group ? nil : group
                        if selectedFilter != nil { favoritesOnly = false }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func exerciseRowButton(_ exercise: Exercise) -> some View {
        HStack(spacing: 8) {
            Button {
                onPick(exercise)
                dismiss()
            } label: {
                row(exercise)
            }
            .buttonStyle(.plain)

            Button {
                toggleFavorite(exercise)
            } label: {
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(exercise.isFavorite ? .yellow : .secondary)
                    .font(.title3)
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleFavorite(_ exercise: Exercise) {
        let repo = ExerciseRepository(context: modelContext)
        try? repo.toggleFavorite(exercise)
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
            Text(exercise.localizedName)
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
        case .barbell: return String(localized: "バーベル")
        case .dumbbell: return String(localized: "ダンベル")
        case .machine: return String(localized: "マシン")
        case .cable: return String(localized: "ケーブル")
        case .bodyweight: return String(localized: "自重")
        case .kettlebell: return String(localized: "ケトルベル")
        case .band: return String(localized: "バンド")
        case .other: return String(localized: "その他")
        }
    }
}

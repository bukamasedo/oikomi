import SwiftData
import SwiftUI
import OikomiKit

struct RoutineEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 編集対象（nil なら新規作成）
    let existingRoutine: Routine?

    @State private var name: String = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var showingPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("ルーティン名") {
                    TextField("例: プッシュデー", text: $name)
                        .textInputAutocapitalization(.never)
                }

                Section("種目") {
                    if selectedExercises.isEmpty {
                        Text("種目を追加してください")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(selectedExercises) { exercise in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.tertiary)
                                Text(exercise.name)
                            }
                        }
                        .onMove { from, to in
                            selectedExercises.move(fromOffsets: from, toOffset: to)
                        }
                        .onDelete { offsets in
                            selectedExercises.remove(atOffsets: offsets)
                        }
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("種目を追加", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(existingRoutine == nil ? "新規ルーティン" : "ルーティン編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !selectedExercises.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExerciseListPicker(excluding: selectedExercises) { picked in
                    selectedExercises.append(picked)
                }
            }
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear(perform: loadExisting)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedExercises.isEmpty
    }

    private func loadExisting() {
        guard let routine = existingRoutine else { return }
        name = routine.name
        selectedExercises = routine.orderedExercises.compactMap(\.exercise)
    }

    private func save() {
        let repo = RoutineRepository(context: modelContext)
        do {
            if let routine = existingRoutine {
                try repo.renameRoutine(routine, to: name)
                // 種目を一度全削除して再構築（順序維持の簡単な方法）
                for entry in routine.orderedExercises {
                    try repo.removeExercise(entry)
                }
                for exercise in selectedExercises {
                    try repo.addExercise(to: routine, exercise: exercise)
                }
            } else {
                try repo.createRoutine(name: name, exercises: selectedExercises)
            }
            dismiss()
        } catch {
            errorMessage = "保存に失敗: \(error.localizedDescription)"
        }
    }
}

/// シート用の種目ピッカー。既に選択済みの種目は除外する。
struct ExerciseListPicker: View {

    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let excluding: [Exercise]
    let onPick: (Exercise) -> Void

    private var available: [Exercise] {
        let excludedIds = Set(excluding.map(\.id))
        return allExercises.filter { !excludedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                if available.isEmpty {
                    Text("追加できる種目がありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(available) { exercise in
                        Button {
                            onPick(exercise)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .foregroundStyle(.primary)
                                let groups = exercise.muscleGroups.map(\.displayName).joined(separator: " / ")
                                if !groups.isEmpty {
                                    Text(groups)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("種目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

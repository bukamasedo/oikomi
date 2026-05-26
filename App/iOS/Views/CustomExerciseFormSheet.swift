import OikomiKit
import SwiftData
import SwiftUI

/// カスタム種目を新規作成するフォーム。
///
/// `ExercisePickerSheet` から右上 + ボタンまたは検索空 CTA で起動される。
/// 作成成功時は `onCreated(exercise)` で呼び出し元に通知し、自身を閉じる。
/// 呼び出し側は受け取った Exercise を即 `onPick` に流し込む想定。
struct CustomExerciseFormSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// フォームに事前入力する名前（検索ワード CTA から呼び出された時に使う）
    let initialName: String

    /// 作成成功時に呼び出される
    let onCreated: (Exercise) -> Void

    @State private var name: String
    @State private var selectedMuscleGroups: Set<MuscleGroup>
    @State private var equipment: Equipment = .barbell
    @State private var defaultRestSeconds: Int = 90
    @State private var editingRest = false
    @State private var pendingRestSeconds: Int? = 90
    @State private var alertMessage: String?

    init(
        initialName: String = "",
        onCreated: @escaping (Exercise) -> Void
    ) {
        self.initialName = initialName
        self.onCreated = onCreated
        _name = State(initialValue: initialName)
        _selectedMuscleGroups = State(initialValue: [])
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名前") {
                    TextField("例: ブルガリアンスクワット", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        Toggle(group.displayName, isOn: binding(for: group))
                    }
                } header: {
                    Text("部位（複数選択可）")
                } footer: {
                    Text("選択した部位で種目を絞り込めるようになります。")
                }

                Section("器具") {
                    Picker("器具", selection: $equipment) {
                        ForEach(Equipment.allCases, id: \.self) { eq in
                            Text(equipmentLabel(eq)).tag(eq)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("レスト") {
                    Button {
                        pendingRestSeconds = defaultRestSeconds
                        editingRest = true
                    } label: {
                        HStack {
                            Text("デフォルトレスト")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(RestSecondsPickerSheet.formatLabel(defaultRestSeconds))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("種目を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(
                isPresented: $editingRest,
                onDismiss: {
                    if let v = pendingRestSeconds { defaultRestSeconds = v }
                }
            ) {
                RestSecondsPickerSheet(
                    seconds: Binding(
                        get: { pendingRestSeconds },
                        set: { pendingRestSeconds = $0 }
                    ),
                    allowsDefault: false,
                    title: "デフォルトレスト"
                )
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            }
            .alert("作成できません", isPresented: .constant(alertMessage != nil)) {
                Button("OK") { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - Helpers

    private func binding(for group: MuscleGroup) -> Binding<Bool> {
        Binding(
            get: { selectedMuscleGroups.contains(group) },
            set: { isOn in
                if isOn {
                    selectedMuscleGroups.insert(group)
                } else {
                    selectedMuscleGroups.remove(group)
                }
            }
        )
    }

    private func save() {
        let repo = ExerciseRepository(context: modelContext)
        do {
            let exercise = try repo.addCustomExercise(
                name: trimmedName,
                muscleGroups: MuscleGroup.allCases.filter(selectedMuscleGroups.contains),
                equipment: equipment,
                defaultRestSeconds: defaultRestSeconds
            )
            onCreated(exercise)
            dismiss()
        } catch let error as ProGateError {
            alertMessage = (error.errorDescription ?? "") + "\n\n設定 > Pro にアップグレードから加入できます。"
        } catch {
            alertMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
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

import SwiftData
import SwiftUI
import OikomiKit

struct AddSetSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    /// 開く前に選択しておきたい種目（クイック追加から渡す）
    var preselectedExercise: Exercise? = nil
    /// 「計画として追加」モード。true なら addPlannedSet を使い未完了セットを生成する。
    var planMode: Bool = false
    /// 保存成功時に呼ばれる。レストタイマー起動などに使う。
    var onSaved: ((SetRecord) -> Void)? = nil

    @State private var selectedExercise: Exercise?
    @State private var weight: Double = 20
    @State private var reps: Int = 8
    @State private var errorMessage: String?
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("種目") {
                    Button {
                        showingPicker = true
                    } label: {
                        HStack {
                            if let selected = selectedExercise {
                                Text(selected.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("選択してください")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                if let selected = selectedExercise {
                    if selected.measurementType != .bodyweightReps {
                        Section("重量 (kg)") {
                            Stepper(value: $weight, in: 0...500, step: 2.5) {
                                Text(weight.formatted(.number.precision(.fractionLength(1))))
                                    .font(.title2.monospacedDigit())
                            }
                        }
                    }

                    Section("レップ数") {
                        Stepper(value: $reps, in: 1...100, step: 1) {
                            Text("\(reps)")
                                .font(.title2.monospacedDigit())
                        }
                    }
                }
            }
            .navigationTitle("セット追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveSet() }
                        .disabled(selectedExercise == nil)
                }
            }
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerSheet { picked in
                    selectedExercise = picked
                    prefillFromLastUse(of: picked)
                }
            }
        }
        .onAppear {
            // 1. クイック追加から渡された種目を最優先
            if selectedExercise == nil, let preselected = preselectedExercise {
                selectedExercise = preselected
                prefillFromLastUse(of: preselected)
                return
            }
            // 2. 直前に記録した種目を自動選択
            if selectedExercise == nil,
                let lastSetExercise = session.orderedSets.last?.exercise
            {
                selectedExercise = lastSetExercise
                if let lastWeight = session.orderedSets.last?.weight {
                    weight = lastWeight
                }
                if let lastReps = session.orderedSets.last?.reps {
                    reps = lastReps
                }
            }
        }
    }

    /// 同セッション内で同じ種目の直近セット値を埋める
    private func prefillFromLastUse(of exercise: Exercise) {
        let lastForExercise = session.orderedSets
            .last { $0.exercise?.id == exercise.id }
        if let lastWeight = lastForExercise?.weight {
            weight = lastWeight
        }
        if let lastReps = lastForExercise?.reps {
            reps = lastReps
        }
    }

    private func saveSet() {
        guard let exercise = selectedExercise else { return }
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            let useBodyweight = exercise.measurementType == .bodyweightReps
            let saved: SetRecord
            if planMode {
                saved = try repo.addPlannedSet(
                    to: session,
                    exercise: exercise,
                    weight: useBodyweight ? nil : weight,
                    reps: reps
                )
            } else {
                saved = try repo.addSet(
                    to: session,
                    exercise: exercise,
                    weight: useBodyweight ? nil : weight,
                    reps: reps
                )
            }
            onSaved?(saved)
            dismiss()
        } catch {
            errorMessage = "保存に失敗: \(error.localizedDescription)"
        }
    }
}

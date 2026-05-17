import SwiftData
import SwiftUI
import OikomiKit

struct AddSetSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedExercise: Exercise?
    @State private var weight: Double = 20
    @State private var reps: Int = 8
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("種目") {
                    Picker("種目", selection: $selectedExercise) {
                        Text("選択してください").tag(Exercise?.none)
                        ForEach(exercises) { exercise in
                            Text(exercise.name).tag(Optional(exercise))
                        }
                    }
                    .pickerStyle(.menu)
                }

                if let selected = selectedExercise {
                    if selected.measurementType != .bodyweightReps {
                        Section("重量 (kg)") {
                            HStack {
                                Stepper(value: $weight, in: 0...500, step: 2.5) {
                                    Text(weight.formatted(.number.precision(.fractionLength(1))))
                                        .font(.title2.monospacedDigit())
                                }
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
            .navigationTitle("セットを記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSet()
                    }
                    .disabled(selectedExercise == nil)
                }
            }
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            // 直前に記録した種目を自動選択
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

    private func saveSet() {
        guard let exercise = selectedExercise else { return }
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            let useBodyweight = exercise.measurementType == .bodyweightReps
            try repo.addSet(
                to: session,
                exercise: exercise,
                weight: useBodyweight ? nil : weight,
                reps: reps
            )
            dismiss()
        } catch {
            errorMessage = "保存に失敗: \(error.localizedDescription)"
        }
    }
}

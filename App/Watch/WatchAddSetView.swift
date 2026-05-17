import SwiftData
import SwiftUI
import OikomiKit

struct WatchAddSetView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    var preselectedExercise: Exercise?

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedExercise: Exercise?
    @State private var weight: Double = 20
    @State private var reps: Int = 8
    @State private var crownReps: Double = 8
    @State private var crownWeight: Double = 20
    @State private var errorMessage: String?

    private var useBodyweight: Bool {
        selectedExercise?.measurementType == .bodyweightReps
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    exercisePickerSection
                    if selectedExercise != nil {
                        if !useBodyweight {
                            weightSection
                        }
                        repsSection
                        saveButton
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear(perform: setupInitial)
    }

    @ViewBuilder
    private var exercisePickerSection: some View {
        NavigationLink {
            WatchExercisePicker { picked in
                selectedExercise = picked
                prefillFromLastUse(of: picked)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("種目")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(selectedExercise?.name ?? "選択")
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var weightSection: some View {
        VStack(spacing: 4) {
            Text("重量")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(weight.formatted(.number.precision(.fractionLength(1)))) kg")
                .font(.title2.monospacedDigit().weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focusable()
                .digitalCrownRotation(
                    $crownWeight,
                    from: 0,
                    through: 500,
                    by: 2.5,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: crownWeight) { _, new in
                    weight = (new / 2.5).rounded() * 2.5
                }
        }
    }

    @ViewBuilder
    private var repsSection: some View {
        VStack(spacing: 4) {
            Text("レップ数")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(reps)")
                .font(.title2.monospacedDigit().weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focusable()
                .digitalCrownRotation(
                    $crownReps,
                    from: 1,
                    through: 100,
                    by: 1,
                    sensitivity: .high,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: crownReps) { _, new in
                    reps = Int(new.rounded())
                }
        }
    }

    @ViewBuilder
    private var saveButton: some View {
        Button {
            saveSet()
        } label: {
            Label("保存", systemImage: "checkmark")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedExercise == nil)
    }

    private func setupInitial() {
        if let preselected = preselectedExercise, selectedExercise == nil {
            selectedExercise = preselected
            prefillFromLastUse(of: preselected)
        }
    }

    private func prefillFromLastUse(of exercise: Exercise) {
        let lastForExercise = session.orderedSets
            .last { $0.exercise?.id == exercise.id }
        if let lastWeight = lastForExercise?.weight {
            weight = lastWeight
            crownWeight = lastWeight
        }
        if let lastReps = lastForExercise?.reps {
            reps = lastReps
            crownReps = Double(lastReps)
        }
    }

    private func saveSet() {
        guard let exercise = selectedExercise else { return }
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.addSet(
                to: session,
                exercise: exercise,
                weight: useBodyweight ? nil : weight,
                reps: reps
            )
            dismiss()
        } catch {
            errorMessage = "保存失敗: \(error.localizedDescription)"
        }
    }
}

/// Watch 用の簡素な種目選択ピッカー。検索 UI はせず、種目名でグルーピング表示。
struct WatchExercisePicker: View {

    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    let onPick: (Exercise) -> Void

    var body: some View {
        List(exercises) { exercise in
            Button {
                onPick(exercise)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text(exercise.name)
                        .font(.body)
                    let groups = exercise.muscleGroups.prefix(2).map(\.displayName).joined(separator: " / ")
                    if !groups.isEmpty {
                        Text(groups)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("種目")
        .navigationBarTitleDisplayMode(.inline)
    }
}

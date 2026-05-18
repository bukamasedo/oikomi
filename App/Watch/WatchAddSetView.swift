import SwiftData
import SwiftUI
import OikomiKit

struct WatchAddSetView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    var preselectedExercise: Exercise?
    /// 計画セットの「調整」フローで渡される。設定されている場合、保存時は markSetCompleted を呼ぶ。
    var editingPlannedSet: SetRecord?
    /// 編集モードで完了化したときレストタイマー endAt を親に返すコールバック。
    var onCompleted: ((Date?) -> Void)?

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
            .navigationTitle(editingPlannedSet != nil ? "調整" : "記録")
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
        // 計画セットの「調整」モード: 計画値をプリフィル
        if let planned = editingPlannedSet, selectedExercise == nil {
            selectedExercise = planned.exercise
            if let w = planned.weight {
                weight = w
                crownWeight = w
            }
            if let r = planned.reps {
                reps = r
                crownReps = Double(r)
            }
            return
        }
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
            if let plannedSet = editingPlannedSet {
                // 計画セット → 実績化（調整した値で markSetCompleted）
                let endAt = try repo.markSetCompleted(
                    plannedSet,
                    actualWeight: useBodyweight ? nil : weight,
                    actualReps: reps
                )
                if let endAt {
                    RestTimerNotifier.scheduleRestEnd(at: endAt)
                }
                onCompleted?(endAt)
            } else {
                // iPhone と同様、新規セットは「計画」状態で保存し、後でタップして完了化する。
                _ = try repo.addPlannedSet(
                    to: session,
                    exercise: exercise,
                    weight: useBodyweight ? nil : weight,
                    reps: reps
                )
            }
            dismiss()
        } catch {
            errorMessage = "保存失敗: \(error.localizedDescription)"
        }
    }
}

/// Watch 用の簡素な種目選択ピッカー。お気に入り種目を上部に固定表示。
struct WatchExercisePicker: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    let onPick: (Exercise) -> Void

    private var favorites: [Exercise] { exercises.filter { $0.isFavorite } }
    private var nonFavorites: [Exercise] { exercises.filter { !$0.isFavorite } }

    var body: some View {
        List {
            if !favorites.isEmpty {
                Section("お気に入り") {
                    ForEach(favorites) { exercise in
                        pickerRow(exercise)
                    }
                }
            }
            Section(favorites.isEmpty ? "" : "すべて") {
                ForEach(nonFavorites) { exercise in
                    pickerRow(exercise)
                }
            }
        }
        .navigationTitle("種目")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func pickerRow(_ exercise: Exercise) -> some View {
        Button {
            onPick(exercise)
            dismiss()
        } label: {
            HStack(spacing: 6) {
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
                Spacer()
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(exercise.isFavorite ? .yellow : .secondary.opacity(0.5))
                    .font(.caption)
                    .onTapGesture {
                        let repo = ExerciseRepository(context: modelContext)
                        try? repo.toggleFavorite(exercise)
                    }
            }
        }
    }
}

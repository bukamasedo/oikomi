import OikomiKit
import SwiftData
import SwiftUI

/// watchOS のセット記録 / 調整シート。
///
/// Digital Crown による重量・レップ入力を最優先。
/// `digitalCrownRotation` の sensitivity/step は触らない（Phase A プランの境界）。
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
                VStack(spacing: WatchSpacing.m) {
                    exercisePickerSection
                    if selectedExercise != nil {
                        if !useBodyweight {
                            weightSection
                        }
                        repsSection
                        saveButton
                    }
                }
                .padding(.horizontal, WatchSpacing.s)
                .padding(.vertical, WatchSpacing.s)
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
        .tint(WatchColor.brand)
        .onAppear(perform: setupInitial)
    }

    // MARK: - Sections

    @ViewBuilder
    private var exercisePickerSection: some View {
        NavigationLink {
            WatchExercisePicker { picked in
                selectedExercise = picked
                prefillFromLastUse(of: picked)
            }
        } label: {
            HStack(spacing: WatchSpacing.s) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WatchColor.brand)
                VStack(alignment: .leading, spacing: 0) {
                    Text("種目")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(selectedExercise?.name ?? "選択")
                        .font(.body)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(WatchSpacing.m)
            .background(
                WatchColor.cardBackground,
                in: RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var weightSection: some View {
        valueCard(label: "重量", value: "\(weight.formatted(.number.precision(.fractionLength(1)))) kg")
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

    @ViewBuilder
    private var repsSection: some View {
        valueCard(label: "レップ", value: "\(reps)")
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

    /// 値カードの共通スタイル。Digital Crown は呼び出し側でアタッチする。
    @ViewBuilder
    private func valueCard(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WatchSpacing.l)
        .background(
            WatchColor.brand.opacity(0.16),
            in: RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous)
                .strokeBorder(WatchColor.brand.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var saveButton: some View {
        Button(action: saveSet) {
            Label(editingPlannedSet != nil ? "完了" : "保存", systemImage: "checkmark")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, WatchSpacing.s)
        }
        .buttonStyle(.borderedProminent)
        .tint(WatchColor.brand)
        .disabled(selectedExercise == nil)
    }

    // MARK: - Lifecycle

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

    // MARK: - Save

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
            HStack(spacing: WatchSpacing.s) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(exercise.name)
                        .font(.body)
                        .lineLimit(1)
                    let groups = exercise.muscleGroups.prefix(2).map(\.displayName).joined(
                        separator: " / ")
                    if !groups.isEmpty {
                        Text(groups)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(
                        exercise.isFavorite ? .yellow : .secondary.opacity(0.5)
                    )
                    .font(.caption)
                    .onTapGesture {
                        let repo = ExerciseRepository(context: modelContext)
                        try? repo.toggleFavorite(exercise)
                    }
            }
        }
    }
}

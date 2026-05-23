import OikomiKit
import SwiftData
import SwiftUI

/// セット追加シート。
///
/// 片手入力を最優先するため wheel picker を廃止し、`NumericStepperField` で
/// ±ボタン + 長押し連続増減 + 直前差分バッジを提供する。
/// 保存ボタンは画面下端の safeAreaInset に固定して親指範囲で押せるようにする。
struct AddSetSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    var preselectedExercise: Exercise? = nil
    var planMode: Bool = false
    /// 既存セットを編集する場合に渡す。non-nil で編集モードに切り替わり、
    /// 種目選択は固定 (タップ不可)、保存時は updateSet が呼ばれる。
    var editingSet: SetRecord? = nil
    var onSaved: ((SetRecord) -> Void)? = nil

    private var isEditing: Bool { editingSet != nil }

    @State private var selectedExercise: Exercise?
    @State private var weight: Double = 20
    @State private var reps: Int = 8
    @State private var previousWeight: Double? = nil
    @State private var previousReps: Int? = nil
    @State private var errorMessage: String?
    @State private var showingPicker = false

    private var useBodyweight: Bool {
        selectedExercise?.measurementType == .bodyweightReps
    }

    private var navTitle: String {
        if isEditing { return "セット編集" }
        return planMode ? "計画セット" : "セット追加"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: OikomiSpacing.l) {
                    exerciseCard
                    if selectedExercise != nil {
                        if !useBodyweight {
                            NumericStepperField(
                                title: "重量",
                                value: $weight,
                                range: 0...500,
                                step: 2.5,
                                formatter: { $0.formatted(.number.precision(.fractionLength(0...1))) },
                                unit: "kg",
                                delta: previousWeight.map { weight - $0 }
                            )
                        }
                        NumericStepperField(
                            title: "レップ",
                            value: Binding(
                                get: { Double(reps) },
                                set: { reps = Int($0) }
                            ),
                            range: 1...100,
                            step: 1,
                            formatter: { "\(Int($0))" },
                            unit: "回",
                            delta: previousReps.map { Double(reps - $0) }
                        )
                    }
                }
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.top, OikomiSpacing.l)
                .padding(.bottom, OikomiSpacing.xxl)
            }
            .background(OikomiColor.appBackground)
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
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
        .onAppear(perform: handleAppear)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var exerciseCard: some View {
        // 編集モードでは種目を変更できない (種目変更=別のセット)
        Button {
            if !isEditing {
                showingPicker = true
            }
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                        .fill(OikomiColor.brandPrimary.opacity(0.14))
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("種目")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(selectedExercise?.name ?? "選択してください")
                        .font(.headline)
                        .foregroundStyle(selectedExercise == nil ? .secondary : .primary)
                }

                Spacer(minLength: OikomiSpacing.s)

                if !isEditing {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(OikomiSpacing.l)
            .background(
                OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isEditing)
    }

    @ViewBuilder
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                saveSet()
            } label: {
                Text("保存")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OikomiSpacing.m + 2)
            }
            .buttonStyle(.borderedProminent)
            .tint(OikomiColor.brandPrimary)
            .disabled(selectedExercise == nil)
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.top, OikomiSpacing.m)
            .padding(.bottom, OikomiSpacing.s)
        }
        .background(.regularMaterial)
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        // 既に選択済みなら何もしない（シート再表示時の不要な上書きを防ぐ）
        guard selectedExercise == nil else { return }

        // 編集モード: 既存セットの値で初期化、ピッカーは出さない
        if let editing = editingSet, let exercise = editing.exercise {
            selectedExercise = exercise
            if let w = editing.weight {
                weight = quantize(w)
            }
            if let r = editing.reps {
                reps = r
            }
            // 編集モードでは「前回比較」は意味が薄いので delta バッジ非表示
            previousWeight = nil
            previousReps = nil
            return
        }

        if let preselected = preselectedExercise {
            selectedExercise = preselected
            prefillFromLastUse(of: preselected)
            return
        }

        // 種目が指定されずに開かれた場合は、即座にピッカーを起動して種目選択を促す。
        // セッション内の最後の種目を勝手に流用しない（「新しい種目を追加したい」意図のため）。
        showingPicker = true
    }

    private func prefillFromLastUse(of exercise: Exercise) {
        let lastForExercise = session.orderedSets
            .last { $0.exercise?.id == exercise.id }
        if let lastWeight = lastForExercise?.weight {
            weight = quantize(lastWeight)
            previousWeight = quantize(lastWeight)
        } else {
            previousWeight = nil
        }
        if let lastReps = lastForExercise?.reps {
            reps = lastReps
            previousReps = lastReps
        } else {
            previousReps = nil
        }
    }

    private func quantize(_ v: Double) -> Double {
        (v / 2.5).rounded() * 2.5
    }

    // MARK: - Save

    private func saveSet() {
        guard let exercise = selectedExercise else { return }
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            let saved: SetRecord
            if let editing = editingSet {
                // 編集モード: 既存セットの値を上書き (1RM 再計算 + PR 再評価は Repository 内で処理)
                saved = try repo.updateSet(
                    editing,
                    weight: useBodyweight ? nil : weight,
                    reps: reps
                )
            } else if planMode {
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

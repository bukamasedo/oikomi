import OikomiKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// ルーティン作成・編集画面。
///
/// 進行中セッション (`WorkoutTabView.activeSessionView`) と同じ
/// カードベースのデザイン言語に合わせ、ScrollView に種目カードを縦に積む。
/// 各カード内に「重量 / レップ / セット数」の値行を持ち、タップで NumericStepperField シートが開く。
struct RoutineEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 編集対象（nil なら新規作成）
    let existingRoutine: Routine?

    @State private var name: String = ""
    @State private var drafts: [RoutineExerciseDraft] = []
    @State private var scheduledWeekdays: Set<Int> = []
    @State private var showingPicker = false
    @State private var editingField: EditingField?
    @State private var draggedID: UUID?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: OikomiSpacing.l) {
                    nameCard
                    scheduleCard

                    if drafts.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach($drafts) { $draft in
                            RoutineExerciseDraftCard(
                                draft: $draft,
                                draggedID: $draggedID,
                                allDrafts: $drafts,
                                onEditField: { field in
                                    editingField = EditingField(
                                        draftId: draft.id, field: field)
                                },
                                onDelete: {
                                    drafts.removeAll { $0.id == draft.id }
                                }
                            )
                        }
                    }

                    addExerciseCard
                }
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.top, OikomiSpacing.s)
                .padding(.bottom, OikomiSpacing.xxl)
            }
            .background(OikomiColor.appBackground)
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
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerSheet(excluding: drafts.map(\.exercise)) { picked in
                    appendDraft(for: picked)
                }
            }
            .sheet(item: $editingField) { field in
                if let idx = drafts.firstIndex(where: { $0.id == field.draftId }) {
                    SingleValueSheet(draft: $drafts[idx], field: field.field)
                        .presentationDetents([.height(360)])
                        .presentationDragIndicator(.visible)
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

    // MARK: - Cards

    @ViewBuilder
    private var nameCard: some View {
        HStack(spacing: OikomiSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                    .fill(OikomiColor.brandPrimary.opacity(0.14))
                Image(systemName: "list.bullet.clipboard")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandPrimary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("ルーティン名")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("例: プッシュデー", text: $name)
                    .font(.headline)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground,
            in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private var emptyStateCard: some View {
        VStack(spacing: OikomiSpacing.s) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("種目がまだありません")
                .font(.subheadline.weight(.semibold))
            Text("下の「種目を追加」から種目を選んで構成しましょう")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(OikomiSpacing.xl)
        .background(
            OikomiColor.cardBackground,
            in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private var addExerciseCard: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: OikomiSpacing.s) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(OikomiColor.brandPrimary)
                Text("種目を追加")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(OikomiSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .strokeBorder(
                        OikomiColor.brandPrimary.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !drafts.isEmpty
    }

    @ViewBuilder
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                        .fill(OikomiColor.brandPrimary.opacity(0.14))
                    Image(systemName: "calendar")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("実施曜日")
                        .font(.subheadline.weight(.semibold))
                    Text("PR 予測通知の対象になります。未選択でも保存できます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: OikomiSpacing.xs) {
                ForEach(weekdayOptions, id: \.weekday) { option in
                    weekdayChip(for: option)
                }
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }

    /// 1=日, 2=月, ... 7=土
    private var weekdayOptions: [(weekday: Int, label: String)] {
        [
            (1, "日"), (2, "月"), (3, "火"), (4, "水"), (5, "木"), (6, "金"), (7, "土"),
        ]
    }

    @ViewBuilder
    private func weekdayChip(for option: (weekday: Int, label: String)) -> some View {
        let isSelected = scheduledWeekdays.contains(option.weekday)
        Button {
            if isSelected {
                scheduledWeekdays.remove(option.weekday)
            } else {
                scheduledWeekdays.insert(option.weekday)
            }
        } label: {
            Text(option.label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            isSelected
                                ? OikomiColor.brandPrimary
                                : OikomiColor.brandPrimary.opacity(0.10))
                )
                .foregroundStyle(isSelected ? Color.white : OikomiColor.brandPrimary)
        }
        .buttonStyle(.plain)
    }

    private func loadExisting() {
        guard let routine = existingRoutine else { return }
        // 既存値があるなら一度だけロード (シート再表示で上書きしない)
        if !name.isEmpty || !drafts.isEmpty { return }
        name = routine.name
        scheduledWeekdays = Set(routine.scheduledWeekdays)
        drafts = routine.orderedExercises.compactMap { entry in
            guard let exercise = entry.exercise else { return nil }
            return RoutineExerciseDraft(
                id: UUID(),
                exercise: exercise,
                plannedSets: entry.plannedSets,
                plannedReps: entry.plannedReps,
                plannedWeight: entry.plannedWeight,
                plannedRestSeconds: entry.plannedRestSeconds
            )
        }
    }

    private func appendDraft(for exercise: Exercise) {
        let repo = WorkoutSessionRepository(context: modelContext)
        let lastSet = try? repo.lastCompletedSet(for: exercise)
        drafts.append(
            RoutineExerciseDraft(
                id: UUID(),
                exercise: exercise,
                plannedSets: 3,
                plannedReps: lastSet?.reps ?? 8,
                plannedWeight: exercise.usesWeight
                    ? (lastSet?.weight ?? UnitPreference.current().defaultInitialKilograms) : nil,
                plannedRestSeconds: nil
            )
        )
    }

    private func save() {
        let repo = RoutineRepository(context: modelContext)
        do {
            let routine: Routine
            if let existing = existingRoutine {
                try repo.renameRoutine(existing, to: name)
                // 既存パターン: 全削除 → 再構築で順序を簡単に維持
                for entry in existing.orderedExercises {
                    try repo.removeExercise(entry)
                }
                routine = existing
            } else {
                routine = try repo.createRoutine(name: name, exercises: [])
            }
            for draft in drafts {
                try repo.addExercise(
                    to: routine,
                    exercise: draft.exercise,
                    plannedSets: draft.plannedSets,
                    plannedReps: draft.plannedReps,
                    plannedWeight: draft.exercise.usesWeight ? draft.plannedWeight : nil,
                    plannedRestSeconds: draft.plannedRestSeconds
                )
            }
            try repo.setScheduledWeekdays(Array(scheduledWeekdays), for: routine)
            dismiss()
        } catch {
            errorMessage = "保存に失敗: \(error.localizedDescription)"
        }
    }
}

// MARK: - Routine Exercise Draft Card

/// 進行中セッションの ExerciseInSessionCard と同じデザイン言語の、ルーティン編集中種目カード。
/// 行内編集スタイル (タップで SingleValueSheet) と長押しメニュー削除を持つ。
private struct RoutineExerciseDraftCard: View {

    @Binding var draft: RoutineExerciseDraft
    @Binding var draggedID: UUID?
    @Binding var allDrafts: [RoutineExerciseDraft]
    var onEditField: (ValueField) -> Void
    var onDelete: () -> Void

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    private var showsWeight: Bool {
        draft.exercise.usesWeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.top, OikomiSpacing.l)
                .padding(.bottom, OikomiSpacing.s)

            Divider().padding(.horizontal, OikomiSpacing.l)

            if showsWeight {
                valueRow(
                    label: "重量",
                    valueText: WeightFormatter.string(
                        kilograms: draft.plannedWeight ?? weightUnit.defaultInitialKilograms,
                        in: weightUnit)
                ) { onEditField(.weight) }
                Divider().padding(.leading, OikomiSpacing.l * 2)
            }

            valueRow(
                label: "レップ",
                valueText: "\(draft.plannedReps) 回"
            ) { onEditField(.reps) }
            Divider().padding(.leading, OikomiSpacing.l * 2)

            valueRow(
                label: "セット数",
                valueText: "\(draft.plannedSets) セット"
            ) { onEditField(.sets) }
            Divider().padding(.leading, OikomiSpacing.l * 2)

            valueRow(
                label: "レスト",
                valueText: restValueLabel()
            ) { onEditField(.rest) }
        }
        .background(
            OikomiColor.cardBackground,
            in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
        // カード全体を長押しドラッグで並べ替え対象にする。ハンドルアイコンは省略。
        .onDrag {
            draggedID = draft.id
            return NSItemProvider(object: draft.id.uuidString as NSString)
        }
        .onDrop(
            of: [UTType.text],
            delegate: ReorderDropDelegate(
                destinationID: draft.id,
                drafts: $allDrafts,
                draggedID: $draggedID
            )
        )
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: OikomiSpacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.exercise.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                let effectiveRest = draft.plannedRestSeconds ?? draft.exercise.defaultRestSeconds
                if effectiveRest > 0 {
                    Text(
                        draft.plannedRestSeconds != nil
                            ? "レスト \(RestSecondsPickerSheet.formatLabel(effectiveRest))（上書き）"
                            : "レスト \(RestSecondsPickerSheet.formatLabel(effectiveRest))"
                    )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: OikomiSpacing.s)

            Text("\(draft.plannedSets) セット")
                .font(.caption.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, OikomiSpacing.s)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.14), in: Capsule())
                .foregroundStyle(.secondary)
        }
    }

    private func restValueLabel() -> String {
        if let override = draft.plannedRestSeconds {
            return RestSecondsPickerSheet.formatLabel(override)
        }
        return "デフォルト (\(RestSecondsPickerSheet.formatLabel(draft.exercise.defaultRestSeconds)))"
    }

    @ViewBuilder
    private func valueRow(
        label: String, valueText: String, onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valueText)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.vertical, OikomiSpacing.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers (unchanged)

/// `.sheet(item:)` 用。タップごとに新 UUID を発行してシート再提示を確実にする。
private struct EditingField: Identifiable {
    let id = UUID()
    let draftId: UUID
    let field: ValueField
}

/// 種目行の並べ替え用ドロップ delegate。
/// ドラッグ中の `draggedID` を見て、ホバーした行が異なる種目なら入れ替える（ライブ並べ替え）。
private struct ReorderDropDelegate: DropDelegate {
    let destinationID: UUID
    @Binding var drafts: [RoutineExerciseDraft]
    @Binding var draggedID: UUID?

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedID,
            dragged != destinationID,
            let fromIdx = drafts.firstIndex(where: { $0.id == dragged }),
            let toIdx = drafts.firstIndex(where: { $0.id == destinationID })
        else { return }
        if drafts[toIdx].id != dragged {
            withAnimation {
                let item = drafts.remove(at: fromIdx)
                drafts.insert(item, at: toIdx)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedID = nil
        return true
    }
}

private enum ValueField {
    case weight, reps, sets, rest
    var title: String {
        switch self {
        case .weight: "重量"
        case .reps: "レップ"
        case .sets: "セット"
        case .rest: "レスト"
        }
    }
}

/// ルーティン編集時の一時的な編集状態。
/// SwiftData @Model ではなく Identifiable な struct として、保存タイミングまで context.insert を遅延させる。
private struct RoutineExerciseDraft: Identifiable {
    let id: UUID
    let exercise: Exercise
    var plannedSets: Int
    var plannedReps: Int
    var plannedWeight: Double?
    /// nil の場合は exercise.defaultRestSeconds を採用（上書き無し）。
    var plannedRestSeconds: Int?
}

/// 1 つの値だけを ±入力で編集する bottom sheet。`NumericStepperField` で一貫性確保。
private struct SingleValueSheet: View {
    @Binding var draft: RoutineExerciseDraft
    let field: ValueField
    @Environment(\.dismiss) private var dismiss

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: OikomiSpacing.l) {
                Text(draft.exercise.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, OikomiSpacing.s)

                stepperView

                Spacer(minLength: 0)
            }
            .padding(.horizontal, OikomiSpacing.l)
            .background(OikomiColor.appBackground)
            .navigationTitle(field.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var stepperView: some View {
        switch field {
        case .weight:
            WeightStepperField(
                title: "重量",
                kilograms: Binding(
                    get: { draft.plannedWeight ?? weightUnit.defaultInitialKilograms },
                    set: { draft.plannedWeight = $0 }
                ),
                unit: weightUnit
            )
        case .reps:
            NumericStepperField(
                title: "レップ",
                value: Binding(
                    get: { Double(draft.plannedReps) },
                    set: { draft.plannedReps = Int($0) }
                ),
                range: 1...100,
                step: 1,
                formatter: { "\(Int($0))" },
                unit: "回"
            )
        case .sets:
            NumericStepperField(
                title: "セット",
                value: Binding(
                    get: { Double(draft.plannedSets) },
                    set: { draft.plannedSets = Int($0) }
                ),
                range: 1...20,
                step: 1,
                formatter: { "\(Int($0))" },
                unit: "セット"
            )
        case .rest:
            // 表示値: 上書きがあればそれを、無ければ種目デフォルトを採用。
            // +/- がタップされた瞬間に plannedRestSeconds が確定し、override 扱いになる。
            let displayed = draft.plannedRestSeconds ?? draft.exercise.defaultRestSeconds
            VStack(alignment: .leading, spacing: OikomiSpacing.xs) {
                NumericStepperField(
                    title: "レスト",
                    value: Binding(
                        get: { Double(displayed) },
                        set: { draft.plannedRestSeconds = max(0, Int($0)) }
                    ),
                    range: 0...600,
                    step: 15,
                    formatter: { Int($0) == 0 ? "なし" : "\(Int($0))" },
                    unit: Int(displayed) == 0 ? "" : "秒"
                )
                if draft.plannedRestSeconds != nil,
                    draft.plannedRestSeconds != draft.exercise.defaultRestSeconds
                {
                    Button {
                        draft.plannedRestSeconds = nil
                    } label: {
                        Text("デフォルト (\(draft.exercise.defaultRestSeconds) 秒) に戻す")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(OikomiColor.brandPrimary)
                    }
                    .padding(.leading, OikomiSpacing.s)
                }
            }
        }
    }
}

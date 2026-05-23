import OikomiKit
import SwiftData
import SwiftUI

struct WatchActiveSessionView: View {

    @Environment(\.modelContext) private var modelContext

    let session: WorkoutSession

    @State private var showingAddSet = false
    @State private var showingExercisePicker = false
    @State private var preselectedExercise: Exercise?
    @State private var editingPlannedSet: SetRecord?
    @State private var errorMessage: String?
    @State private var restEndAt: Date?
    @State private var restTotalSeconds: Int = 60
    @State private var confirmingFinish = false
    @State private var healthSession = WatchHealthSession()

    var body: some View {
        List {
            Section { sessionHero }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 4, trailing: 0))

            if let endAt = restEndAt {
                Section {
                    WatchRestTimerView(endAt: endAt, totalSeconds: restTotalSeconds) {
                        restEndAt = nil
                        RestTimerNotifier.cancel()
                        // iPhone 側のローカル通知 / Live Activity restEndAt も同時にクリア
                        WCSyncBridge.shared.sendRestTimerCancel()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
            }

            ForEach(groupedExercises(session), id: \.0.id) { exercise, sets in
                exerciseSection(exercise: exercise, sets: sets)
            }

            Section {
                addExerciseRow
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(session.routine?.name ?? "進行中")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    confirmingFinish = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.black)
                        .frame(width: 26, height: 26)
                        .background(WatchColor.brand, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ワークアウトを終了")
            }
        }
        .sheet(isPresented: $showingAddSet) {
            WatchAddSetView(session: session, preselectedExercise: preselectedExercise)
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                WatchExercisePicker { picked in
                    addExerciseToSession(picked)
                }
            }
        }
        .sheet(item: $editingPlannedSet) { plannedSet in
            WatchAddSetView(session: session, editingPlannedSet: plannedSet) { restEnd in
                restEndAt = restEnd
                restTotalSeconds = plannedSet.exercise?.defaultRestSeconds ?? 60
            }
        }
        .confirmationDialog(
            "ワークアウトを終了しますか？", isPresented: $confirmingFinish, titleVisibility: .visible
        ) {
            Button("終了する", role: .destructive) { finishSession() }
            Button("キャンセル", role: .cancel) {}
        }
        .task {
            await healthSession.start()
        }
        .onReceive(NotificationCenter.default.publisher(for: WCSyncBridge.dataDidChangeNotification)) { note in
            guard let kind = note.userInfo?["kind"] as? String else { return }
            if kind == SyncEnvelope.Kind.restTimerCancel.rawValue {
                // iPhone でレストをスキップ / 完了取消 → Watch 側の UI タイマーも消す
                restEndAt = nil
            } else if kind == SyncEnvelope.Kind.restTimerStart.rawValue,
                let endAt = note.userInfo?["endAt"] as? Date,
                endAt > Date()
            {
                // iPhone でセット完了 → Watch 側のレストタイマーも起動
                restEndAt = endAt
                if let total = note.userInfo?["totalSeconds"] as? Int, total > 0 {
                    restTotalSeconds = total
                }
            }
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var sessionHero: some View {
        let totalSets = session.sets?.count ?? 0
        let completedSets = session.sets?.filter(\.isCompleted).count ?? 0
        let allDone = completedSets >= totalSets && totalSets > 0

        HStack(spacing: WatchSpacing.m) {
            VStack(alignment: .leading, spacing: 1) {
                Text("経過")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(session.startedAt, style: .timer)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: WatchSpacing.s)

            VStack(alignment: .trailing, spacing: 1) {
                Text("セット")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(completedSets) / \(totalSets)")
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(allDone ? Color.green : .primary)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, WatchSpacing.l)
        .padding(.vertical, WatchSpacing.m)
        .background(WatchColor.cardBackground, in: RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous))
    }

    // MARK: - Exercise section

    @ViewBuilder
    private func exerciseSection(exercise: Exercise, sets: [SetRecord]) -> some View {
        let completed = sets.filter(\.isCompleted).count
        let allDone = completed >= sets.count && sets.count > 0
        Section {
            ForEach(sets) { set in
                setRow(set)
            }
            Button {
                preselectedExercise = exercise
                showingAddSet = true
            } label: {
                Label("セット", systemImage: "plus.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WatchColor.brand)
            }
            .buttonStyle(.plain)
        } header: {
            HStack(spacing: WatchSpacing.s) {
                Text(exercise.name)
                    .font(.caption.weight(.semibold))
                    .textCase(nil)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: WatchSpacing.xs)
                HStack(spacing: 2) {
                    if allDone {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                    }
                    Text("\(completed)/\(sets.count)")
                        .font(.caption2.monospacedDigit())
                }
                .fixedSize()
                .foregroundStyle(allDone ? Color.green : .secondary)
            }
        }
    }

    @ViewBuilder
    private func setRow(_ set: SetRecord) -> some View {
        Button {
            if set.isCompleted {
                uncompletePlanned(set)
            } else {
                completePlanned(set)
            }
        } label: {
            HStack(spacing: WatchSpacing.s) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
                if let w = set.weight, let r = set.reps {
                    Text("\(w.formatted())kg × \(r)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                } else if let r = set.reps {
                    Text("\(r)レップ")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                }
                Spacer()
                if !set.isCompleted {
                    Button {
                        editingPlannedSet = set
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption2.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(WatchColor.brand)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add exercise

    @ViewBuilder
    private var addExerciseRow: some View {
        Button {
            showingExercisePicker = true
        } label: {
            HStack(spacing: WatchSpacing.s) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(WatchColor.brand)
                Text("種目を追加")
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, WatchSpacing.m)
            .padding(.vertical, WatchSpacing.m)
            .background(
                RoundedRectangle(cornerRadius: WatchRadius.card, style: .continuous)
                    .strokeBorder(WatchColor.brand.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// セッション内のセットを種目別にグループ化（初出順）
    private func groupedExercises(_ session: WorkoutSession) -> [(Exercise, [SetRecord])] {
        var firstAppearance: [UUID: Int] = [:]
        var byExercise: [UUID: (Exercise, [SetRecord])] = [:]
        for set in session.orderedSets {
            guard let ex = set.exercise else { continue }
            if firstAppearance[ex.id] == nil {
                firstAppearance[ex.id] = set.order
                byExercise[ex.id] = (ex, [])
            }
            byExercise[ex.id]?.1.append(set)
        }
        return byExercise.values.sorted { lhs, rhs in
            (firstAppearance[lhs.0.id] ?? 0) < (firstAppearance[rhs.0.id] ?? 0)
        }
    }

    private func completePlanned(_ set: SetRecord) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            let endAt = try repo.markSetCompleted(set)
            if let endAt {
                restEndAt = endAt
                restTotalSeconds = set.exercise?.defaultRestSeconds ?? 60
                RestTimerNotifier.scheduleRestEnd(at: endAt)
            }
        } catch {
            errorMessage = "完了失敗: \(error.localizedDescription)"
        }
    }

    /// うっかりチェックを入れた場合の取消。iPhone と挙動を統一。
    private func uncompletePlanned(_ set: SetRecord) {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.uncompleteSet(set)
            if restEndAt != nil {
                restEndAt = nil
                RestTimerNotifier.cancel()
            }
        } catch {
            errorMessage = "戻すのに失敗: \(error.localizedDescription)"
        }
    }

    private func addExerciseToSession(_ exercise: Exercise) {
        let lastForExercise = session.orderedSets.last { $0.exercise?.id == exercise.id }
        let useBodyweight = exercise.measurementType == .bodyweightReps
        let weight = useBodyweight ? nil : (lastForExercise?.weight ?? 20)
        let reps = lastForExercise?.reps ?? 8
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            _ = try repo.addPlannedSet(to: session, exercise: exercise, weight: weight, reps: reps)
        } catch {
            errorMessage = "種目追加失敗: \(error.localizedDescription)"
        }
    }

    private func finishSession() {
        let repo = WorkoutSessionRepository(context: modelContext)
        Task { @MainActor in
            // 順序が重要: HKWorkoutSession.end() を呼ぶと watchOS がアプリの
            // foreground 特権を解除し、後続の WC 送信がサスペンドで失敗する恐れがある。
            // 先にローカル save + WC 送信 + Live Activity end を完了させる。
            // HK 書き込みは下の healthSession.end() の builder.finishWorkout に
            // 一任して二重書き込みを避ける（HealthStore.saveWorkout は使わない）。
            do {
                try await repo.finishSession(session, writeToHealthKit: false)
            } catch {
                errorMessage = "終了失敗: \(error.localizedDescription)"
            }
            // HKWorkoutSession を終了してリング貢献。失敗しても同期は既に完了済み。
            await healthSession.end()
        }
    }
}

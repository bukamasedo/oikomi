import OikomiKit
import SwiftData
import SwiftUI
import WatchKit

struct WatchActiveSessionView: View {

    @Environment(\.modelContext) private var modelContext

    let session: WorkoutSession

    @State private var errorMessage: String?
    @State private var restEndAt: Date?
    @State private var restTotalSeconds: Int = 60
    /// レストタイマー hero に出す「次セットの目安」用。直前に完了したセットの重量 (kg) と
    /// レップ数を保持し、`WatchRestTimerView` の下段に "次: 60 kg × 10" として渡す。
    @State private var nextSetWeightHint: Double?
    @State private var nextSetRepsHint: Int?
    @State private var confirmingFinish = false
    @State private var healthSession = WatchHealthSession()

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    /// `@AppStorage` の KVO が WC 受信後に再描画を起こさない事象（iOS 26 で観測）に備えた
    /// 明示フォールバック。`.onReceive(unitPreferenceUpdate)` で `UnitPreference.current()` を
    /// 書き込み、`weightUnit` 計算で AppStorage より優先する。
    @State private var weightUnitOverride: WeightUnit?
    private var weightUnit: WeightUnit {
        if let weightUnitOverride { return weightUnitOverride }
        return WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    var body: some View {
        List {
            // 経過時間 + セット数。レスト中も視認できるよう常に最上段に残す。
            Section { sessionHero }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))

            // レストタイマー hero。restEndAt が立っている間だけ sessionHero の直下に挿入し、
            // 「あと何秒で次のセット」を一目で取れるようにする。
            if let endAt = restEndAt {
                Section {
                    WatchRestTimerView(
                        endAt: endAt,
                        totalSeconds: restTotalSeconds,
                        nextSetHint: nextSetHintText
                    ) {
                        clearRestTimer()
                        // iPhone 側のローカル通知 / Live Activity restEndAt も同時にクリア
                        WCSyncBridge.shared.sendRestTimerCancel()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 0))
            }

            ForEach(groupedExercises(session), id: \.0.id) { exercise, sets in
                exerciseSection(exercise: exercise, sets: sets)
            }
        }
        .listSectionSpacing(.compact)
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
                clearRestTimer()
            } else if kind == SyncEnvelope.Kind.restTimerStart.rawValue,
                let endAt = note.userInfo?["endAt"] as? Date,
                endAt > Date()
            {
                // iPhone でセット完了したケースの remote 起動経路。
                // Watch 自身で完了させたときは completePlanned 内で直接 State を更新するため
                // ここには来ない（WCSyncBridge.sendRestTimerStart は WCSession 経由送信のみで
                // 自分の NotificationCenter には post しない仕様）。
                restEndAt = endAt
                if let total = note.userInfo?["totalSeconds"] as? Int, total > 0 {
                    restTotalSeconds = total
                }
                nextSetWeightHint = note.userInfo?["completedWeightKg"] as? Double
                nextSetRepsHint = note.userInfo?["completedReps"] as? Int
            } else if kind == SyncEnvelope.Kind.unitPreferenceUpdate.rawValue {
                // iPhone で kg/lb 切替を受信。@AppStorage の KVO が再描画を起こさない経路の
                // フォールバックとして、明示的に App Group UserDefaults から再読込し、
                // computed `weightUnit` で AppStorage より優先表示させる。
                weightUnitOverride = UnitPreference.current()
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
        // 完了セットは実績スナップショット (restSeconds) を、未完了は予定値を優先解決する。
        // 0 のときは表示しない（自重種目で defaultRestSeconds=0 の運用想定）。
        let rest: Int = {
            if set.isCompleted, let snapshot = set.restSeconds { return snapshot }
            return set.resolveRestSeconds()
        }()

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
                    Text("\(WeightFormatter.string(kilograms: w, in: weightUnit)) × \(r)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                } else if let r = set.reps {
                    Text("\(r)レップ")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)
                }
                Spacer(minLength: WatchSpacing.xs)
                if rest > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "timer")
                        Text("\(rest)秒")
                            .monospacedDigit()
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize()
                }
            }
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
            // Watch で完了させたケースは、自分の NotificationCenter には何も post されない
            // （WCSyncBridge.sendRestTimerStart は WCSession 経由でのみ送る）。
            // よってローカル State はここで直接更新する。iPhone でのケースは onReceive 側で扱う。
            if let endAt = try repo.markSetCompleted(set) {
                let total = set.restSeconds ?? set.exercise?.defaultRestSeconds ?? 60
                restEndAt = endAt
                restTotalSeconds = total
                nextSetWeightHint = set.weight
                nextSetRepsHint = set.reps
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
                clearRestTimer()
            }
        } catch {
            errorMessage = "戻すのに失敗: \(error.localizedDescription)"
        }
    }

    private func clearRestTimer() {
        restEndAt = nil
        nextSetWeightHint = nil
        nextSetRepsHint = nil
        RestTimerNotifier.cancel()
    }

    /// レストタイマー hero 下段の「次: 60 kg × 10」テキスト。直前完了セットの値を `weightUnit`
    /// で整形する。重量未入力ならレップ数のみ、両方無ければ nil（行を非表示）。
    private var nextSetHintText: String? {
        if let w = nextSetWeightHint, let r = nextSetRepsHint {
            return "\(WeightFormatter.string(kilograms: w, in: weightUnit)) × \(r)"
        }
        if let r = nextSetRepsHint {
            return "\(r) レップ"
        }
        return nil
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

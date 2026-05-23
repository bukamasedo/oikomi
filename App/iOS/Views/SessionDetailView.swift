import OikomiKit
import SwiftData
import SwiftUI

/// 完了済みセッションの詳細画面。Hero header + 種目カード + コピー CTA。
struct SessionDetailView: View {

    @Environment(\.modelContext) private var modelContext

    let session: WorkoutSession

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @State private var showingCopyConfirmation = false
    @State private var showingActiveBlockedAlert = false
    @State private var errorMessage: String?

    private var setsByExercise: [(exercise: Exercise, sets: [SetRecord])] {
        var seen = Set<UUID>()
        var ordered: [(Exercise, [SetRecord])] = []
        for set in session.orderedSets {
            guard let ex = set.exercise else { continue }
            if seen.insert(ex.id).inserted {
                ordered.append((ex, []))
            }
            if let idx = ordered.firstIndex(where: { $0.0.id == ex.id }) {
                ordered[idx].1.append(set)
            }
        }
        return ordered.map { (exercise: $0.0, sets: $0.1) }
    }

    private var totalVolume: Double {
        session.orderedSets
            .filter(\.isCompleted)
            .reduce(0) { acc, s in
                guard let w = s.weight, let r = s.reps else { return acc }
                return acc + w * Double(r)
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: OikomiSpacing.l) {
                heroCard

                ForEach(setsByExercise, id: \.exercise.id) { group in
                    ExerciseInSessionCard(
                        exercise: group.exercise,
                        sets: group.sets,
                        readOnly: true
                    )
                }

                copyButton
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.vertical, OikomiSpacing.l)
        }
        .background(OikomiColor.appBackground)
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "このセッションをコピーして開始しますか？",
            isPresented: $showingCopyConfirmation,
            titleVisibility: .visible
        ) {
            Button("コピーして開始") { copySession() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(session.sets?.count ?? 0) セットを複製して新しいワークアウトを開始します。")
        }
        .alert("進行中のセッションがあります", isPresented: $showingActiveBlockedAlert) {
            Button("OK") {}
        } message: {
            Text("先に進行中のワークアウトを終了してください。")
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var heroCard: some View {
        let setCount = session.sets?.count ?? 0
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.startedAt, style: .date)
                        .font(.headline)
                    Text(session.startedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let routine = session.routine {
                    Label(routine.name, systemImage: "list.bullet.clipboard")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, OikomiSpacing.s)
                        .padding(.vertical, 4)
                        .background(OikomiColor.elevatedBackground, in: Capsule())
                }
            }

            Divider()

            HStack(spacing: OikomiSpacing.l) {
                heroMetric(
                    title: "所要時間",
                    value: session.durationSeconds.map(formatDuration) ?? "—"
                )
                divider
                heroMetric(title: "総セット", value: "\(setCount)")
                divider
                heroMetric(
                    title: "ボリューム",
                    value: totalVolume.formatted(.number.precision(.fractionLength(0))) + " kg"
                )
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(OikomiColor.separator)
            .frame(width: 1, height: 28)
    }

    @ViewBuilder
    private var copyButton: some View {
        Button {
            if activeSessions.isEmpty {
                showingCopyConfirmation = true
            } else {
                showingActiveBlockedAlert = true
            }
        } label: {
            Label("もう一度実行（コピー）", systemImage: "doc.on.doc.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, OikomiSpacing.m + 2)
        }
        .buttonStyle(.borderedProminent)
        .tint(OikomiColor.brandPrimary)
        .disabled(session.endedAt == nil)
    }

    private func copySession() {
        let repo = WorkoutSessionRepository(context: modelContext)
        do {
            try repo.startSessionByCopying(session)
        } catch {
            errorMessage = "コピーに失敗: \(error.localizedDescription)"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes) 分"
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return "\(hours)時間\(remaining)分"
    }
}

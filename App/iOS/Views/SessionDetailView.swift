import SwiftData
import SwiftUI
import OikomiKit

struct SessionDetailView: View {

    let session: WorkoutSession

    private var setsByExercise: [(exerciseName: String, sets: [SetRecord])] {
        let grouped = Dictionary(grouping: session.orderedSets) { set in
            set.exercise?.name ?? "（種目不明）"
        }
        return grouped
            .map { (exerciseName: $0.key, sets: $0.value.sorted { $0.order < $1.order }) }
            .sorted { $0.sets.first?.order ?? 0 < $1.sets.first?.order ?? 0 }
    }

    var body: some View {
        List {
            Section("セッション") {
                LabeledContent("日付") {
                    Text(session.startedAt, style: .date)
                }
                LabeledContent("開始") {
                    Text(session.startedAt, style: .time)
                }
                if let endedAt = session.endedAt {
                    LabeledContent("終了") {
                        Text(endedAt, style: .time)
                    }
                }
                if let duration = session.durationSeconds {
                    LabeledContent("所要時間") {
                        Text(formatDuration(duration))
                    }
                }
                LabeledContent("総セット数") {
                    Text("\(session.sets?.count ?? 0)")
                }
            }

            ForEach(setsByExercise, id: \.exerciseName) { group in
                Section(group.exerciseName) {
                    ForEach(group.sets) { set in
                        HStack {
                            Text("セット \(set.order + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let weight = set.weight, let reps = set.reps {
                                Text("\(weight.formatted())kg × \(reps)")
                                    .font(.body.monospacedDigit())
                            } else if let reps = set.reps {
                                Text("\(reps)レップ")
                                    .font(.body.monospacedDigit())
                            }
                            if let rm = set.estimated1RM {
                                Text("1RM \(rm.formatted(.number.precision(.fractionLength(1))))kg")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes)分"
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return "\(hours)時間\(remaining)分"
    }
}

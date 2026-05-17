import SwiftData
import SwiftUI
import OikomiKit

struct HistoryView: View {

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "履歴がありません",
                        systemImage: "calendar",
                        description: Text("ワークアウトを完了すると、ここに記録が残ります。")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(value: session) {
                                sessionRow(session)
                            }
                        }
                    }
                }
            }
            .navigationTitle("履歴")
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.startedAt, style: .date)
                    .font(.headline)
                Spacer()
                Text(session.startedAt, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(session.sets?.count ?? 0) セット", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let duration = session.durationSeconds {
                    Label(formatDuration(duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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

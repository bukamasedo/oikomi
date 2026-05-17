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

    @State private var selectedDate: Date?

    private let calendar = Calendar.current

    private var activeDates: Set<Date> {
        Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
    }

    private var filteredSessions: [WorkoutSession] {
        guard let selectedDate else { return sessions }
        let day = calendar.startOfDay(for: selectedDate)
        return sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
    }

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
                        Section {
                            HistoryCalendarView(activeDates: activeDates, selectedDate: $selectedDate)
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }

                        Section(sessionsSectionTitle) {
                            if filteredSessions.isEmpty {
                                Text("この日の記録はありません")
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                            } else {
                                ForEach(filteredSessions) { session in
                                    NavigationLink(value: session) {
                                        sessionRow(session)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("履歴")
            .toolbar {
                if selectedDate != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("すべて表示") {
                            selectedDate = nil
                        }
                    }
                }
            }
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var sessionsSectionTitle: String {
        if let selectedDate {
            return selectedDate.formatted(date: .long, time: .omitted) + " のセッション"
        }
        return "全セッション (\(sessions.count))"
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

                if let routine = session.routine {
                    Label(routine.name, systemImage: "list.bullet.clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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

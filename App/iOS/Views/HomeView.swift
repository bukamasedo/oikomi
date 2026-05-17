import SwiftData
import SwiftUI
import OikomiKit

struct HomeView: View {

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var allSessions: [WorkoutSession]

    private var sessionCount: Int { allSessions.count }

    private var totalSets: Int {
        allSessions.reduce(0) { $0 + ($1.sets?.count ?? 0) }
    }

    var body: some View {
        NavigationStack {
            List {
                if let active = activeSessions.first {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("進行中のワークアウト")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(active.sets?.count ?? 0) セット記録済み")
                                .font(.headline)
                            HStack(spacing: 4) {
                                Text(active.startedAt, style: .relative)
                                Text("前に開始")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("これまでの記録") {
                    LabeledContent("セッション数", value: "\(sessionCount)")
                    LabeledContent("合計セット数", value: "\(totalSets)")
                }

                Section {
                    Text("Oikomi v0.1 開発中")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("ホーム")
        }
    }
}

#Preview {
    HomeView()
}

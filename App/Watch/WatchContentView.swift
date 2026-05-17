import SwiftData
import SwiftUI
import OikomiKit

struct WatchContentView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var activeSessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSessions.first {
                    WatchActiveSessionView(session: session)
                } else {
                    WatchHomeView()
                }
            }
        }
        .task {
            // Watch 起動時に iPhone へ「進行中セッション + 全ルーティンを送って」を依頼
            WCSyncBridge.shared.requestFullSync()
        }
    }
}

#Preview {
    WatchContentView()
}

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
        .onReceive(NotificationCenter.default.publisher(for: WCSyncBridge.dataDidChangeNotification)) { _ in
            modelContext.processPendingChanges()
        }
    }
}

#Preview {
    WatchContentView()
}

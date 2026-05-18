import SwiftUI
import SwiftData
import OikomiKit

@main
struct OikomiWatchApp: App {

    let sharedModelContainer: ModelContainer

    init() {
        do {
            let container = try SharedModelContainer.bootstrap()
            sharedModelContainer = container
            WCSyncBridge.shared.activate { container.mainContext }
            // stale active session 掃除（iPhone と対称）
            Task { @MainActor in
                let sessionRepo = WorkoutSessionRepository(context: container.mainContext)
                if let cleaned = try? sessionRepo.cleanupStaleActiveSessions(), cleaned > 0 {
                    print("[Oikomi.sync] Watch cleaned up \(cleaned) stale active sessions on launch")
                }
            }
        } catch {
            fatalError("ModelContainer 初期化失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

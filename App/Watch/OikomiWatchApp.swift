import SwiftUI
import SwiftData
import OikomiKit

@main
struct OikomiWatchApp: App {

    let sharedModelContainer: ModelContainer

    init() {
        do {
            sharedModelContainer = try SharedModelContainer.bootstrap()
            WCSyncBridge.shared.activate()
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

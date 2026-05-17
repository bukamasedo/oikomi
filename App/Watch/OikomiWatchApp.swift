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

import SwiftUI
import SwiftData
import OikomiKit

@main
struct OikomiWatchApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(OikomiKit.schemaModels)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ModelContainer 初期化失敗: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

import SwiftUI
import SwiftData
import OikomiKit

@main
struct OikomiApp: App {

    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema(OikomiKit.schemaModels)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.sharedModelContainer = container

            // 初回起動時にシード種目を投入
            Task { @MainActor in
                let repo = ExerciseRepository(context: container.mainContext)
                do {
                    try repo.seedIfNeeded()
                } catch {
                    print("シード投入失敗: \(error)")
                }
            }
        } catch {
            fatalError("ModelContainer 初期化失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

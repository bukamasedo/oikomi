import SwiftUI
import SwiftData
import OikomiKit

@main
struct OikomiMacApp: App {

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
            MacContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct MacContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Text("ホーム")
                Text("履歴")
                Text("分析")
                Text("設定")
            }
            .navigationTitle("Oikomi")
        } detail: {
            Text("詳細")
        }
    }
}

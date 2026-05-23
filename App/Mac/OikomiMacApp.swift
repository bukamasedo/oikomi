import OikomiKit
import SwiftData
import SwiftUI

@main
struct OikomiMacApp: App {

    let sharedModelContainer: ModelContainer

    init() {
        do {
            sharedModelContainer = try SharedModelContainer.bootstrap()
            Task { @MainActor in
                await AppleAuthManager.shared.verifyCredentialState()
            }
        } catch {
            fatalError("ModelContainer 初期化失敗: \(error)")
        }
    }

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

import SwiftUI
import SwiftData
import OikomiKit

@main
struct OikomiApp: App {

    let sharedModelContainer: ModelContainer

    init() {
        do {
            let container = try SharedModelContainer.bootstrap()
            self.sharedModelContainer = container

            // WatchConnectivity を起動（iPhone ↔ Watch リアルタイム同期）
            WCSyncBridge.shared.activate()

            // 初回起動時にシード種目を投入 + HealthKit 権限を要求
            Task { @MainActor in
                let repo = ExerciseRepository(context: container.mainContext)
                do {
                    try repo.seedIfNeeded()
                } catch {
                    print("シード投入失敗: \(error)")
                }
                do {
                    try await HealthStore.shared.requestWorkoutWriteAuthorization()
                } catch {
                    print("HealthKit 権限取得スキップ: \(error)")
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

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
            // Watch スタンドアロン前提のため、種目シードを Watch 側でも実行（iPhone 同期に依存しない）
            // + stale active session 掃除（iPhone と対称）+ レスト終了通知の許可リクエスト
            Task { @MainActor in
                let exerciseRepo = ExerciseRepository(context: container.mainContext)
                do {
                    try exerciseRepo.ensureSeedExercisesPresent()
                } catch {
                    print("[Oikomi.seed] Watch seed failed: \(error)")
                }
                let sessionRepo = WorkoutSessionRepository(context: container.mainContext)
                if let cleaned = try? sessionRepo.cleanupStaleActiveSessions(), cleaned > 0 {
                    print("[Oikomi.sync] Watch cleaned up \(cleaned) stale active sessions on launch")
                }
                await RestTimerNotifier.requestAuthorization()
                // StoreKit 2 を Watch 側でも独立して起動（同一 Apple ID なら entitlements 共通）
                await SubscriptionManager.shared.start()
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

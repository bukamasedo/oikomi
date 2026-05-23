import OikomiKit
import SwiftData
import SwiftUI

@main
struct OikomiApp: App {

    let sharedModelContainer: ModelContainer

    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let container = try SharedModelContainer.bootstrap()
            self.sharedModelContainer = container

            // WatchConnectivity を起動（iPhone ↔ Watch リアルタイム同期）
            // 受信時の upsert に使う ModelContext を毎回 mainContext から取得
            WCSyncBridge.shared.activate { container.mainContext }

            // 起動時にシード種目を（差分）投入 + HealthKit 権限を要求 + stale session 掃除
            Task { @MainActor in
                let repo = ExerciseRepository(context: container.mainContext)
                do {
                    try repo.migrateToFullLibraryV1IfNeeded()
                    try repo.ensureSeedExercisesPresent()
                } catch {
                    print("シード投入失敗: \(error)")
                }
                // 24h以上前のまま終了されていないセッションを自動終了（UI のアクティブ表示が
                // 消えなくなる症状を防ぐ）
                let sessionRepo = WorkoutSessionRepository(context: container.mainContext)
                if let cleaned = try? sessionRepo.cleanupStaleActiveSessions(), cleaned > 0 {
                    print("[Oikomi.sync] cleaned up \(cleaned) stale active sessions on launch")
                }
                do {
                    try await HealthStore.shared.requestWorkoutWriteAuthorization()
                } catch {
                    print("HealthKit 権限取得スキップ: \(error)")
                }
                // StoreKit 2: products ロード + Transaction listener 開始 + 現在の権利確認
                await SubscriptionManager.shared.start()

                // Sign in with Apple のセッションが revoke / transferred されていないか確認。
                // revoke 検出時は AppleAuthManager 内で signOut される。
                await AppleAuthManager.shared.verifyCredentialState()
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
        .onChange(of: scenePhase) { _, newPhase in
            // foreground 復帰時に Watch へ fullSync を要求する信頼性ネット。
            // 何らかの理由で Watch の終了イベント (sessionUpsert) が iPhone に
            // 届かず active のまま残った場合に、ここで Watch の最新状態を取り直して
            // endedAt を反映できる。
            if newPhase == .active {
                WCSyncBridge.shared.requestFullSync()
            }
        }
    }
}

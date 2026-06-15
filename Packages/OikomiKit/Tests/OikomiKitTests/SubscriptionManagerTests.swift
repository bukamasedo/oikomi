import Foundation
import Testing

@testable import OikomiKit

@Suite("Subscription")
struct SubscriptionManagerTests {

    @Test("ProductIDs.all は月額・年額の 2 件で構成される")
    func productIDsCountAndOrder() {
        #expect(ProductIDs.all.count == 2)
        #expect(ProductIDs.all.contains(ProductIDs.proMonthly))
        #expect(ProductIDs.all.contains(ProductIDs.proYearly))
    }

    @Test("ProductIDs の bundle プレフィックスが一貫している")
    func productIDsBundlePrefix() {
        let prefix = "com.shuhirouchi.oikomi.pro."
        #expect(ProductIDs.proMonthly.hasPrefix(prefix))
        #expect(ProductIDs.proYearly.hasPrefix(prefix))
    }

    @Test("subscriptionGroup 名は仕様通り Oikomi Pro")
    func subscriptionGroupName() {
        #expect(ProductIDs.subscriptionGroup == "Oikomi Pro")
    }

    @Test("SubscriptionManager.shared は単一インスタンス")
    @MainActor
    func sharedSingleton() {
        let a = SubscriptionManager.shared
        let b = SubscriptionManager.shared
        #expect(a === b)
        // 初期状態の確認: 何も購入していない
        #expect(a.isProActive == false)
        #expect(a.purchaseInProgress == false)
        #expect(a.products.isEmpty)
    }

    @Test("LoadState は Equatable で .failed のメッセージも比較できる")
    func loadStateEquality() {
        let idle: SubscriptionManager.LoadState = .idle
        let loading: SubscriptionManager.LoadState = .loading
        let loaded: SubscriptionManager.LoadState = .loaded
        let failedA: SubscriptionManager.LoadState = .failed(message: "ネットワークエラー")
        let failedB: SubscriptionManager.LoadState = .failed(message: "ネットワークエラー")
        let failedC: SubscriptionManager.LoadState = .failed(message: "別エラー")

        #expect(idle == .idle)
        #expect(loading == .loading)
        #expect(loaded == .loaded)
        #expect(failedA == failedB)
        #expect(failedA != failedC)
        #expect(idle != loading)
        #expect(loaded != failedA)
    }

    @Test("ProGate: Free プランの上限定数")
    @MainActor
    func proGateLimits() {
        #expect(ProGate.freeRoutineLimit == 5)
        #expect(ProGate.freeCustomExerciseLimit == 5)
    }

    @Test("ProGate: 未購入時は楔(読み取り/レディネス/Live Activity)が Free・深さは Pro")
    @MainActor
    func proGateOffByDefault() {
        // テスト環境では Transaction.currentEntitlements は空のため isProActive == false
        #expect(ProGate.isProActive == false)
        #expect(ProGate.canCreateUnlimitedRoutines == false)
        #expect(ProGate.canCreateUnlimitedCustomExercises == false)
        // split（SPEC §10）: 楔（読み取り＋今日のレディネス）は Free 開放
        #expect(ProGate.canReadHealthData == true)
        #expect(ProGate.canUseReadinessCoaching == true)
        #expect(ProGate.canUseLiveActivity == true)
        // 深さ（高度コーチング・トレンド・分析・同期・エクスポート）は Pro
        #expect(ProGate.canUseAdvancedCoaching == false)
        #expect(ProGate.canUseICloudSync == false)
        #expect(ProGate.canSeeAdvancedAnalytics == false)
        #expect(ProGate.canSeeHealthTrends == false)
        #expect(ProGate.canExportData == false)
    }

    @Test("ProGateError: localizedDescription に Pro 文字列を含む")
    func proGateErrorMessages() {
        let errors: [ProGateError] = [
            .routineLimitReached(current: 5, limit: 5),
            .customExerciseLimitReached(current: 5, limit: 5),
            .advancedCoachingRequiresPro,
            .liveActivityRequiresPro,
            .iCloudSyncRequiresPro,
            .advancedAnalyticsRequiresPro,
            .healthTrendsRequiresPro,
            .dataExportRequiresPro,
        ]
        for error in errors {
            let desc = error.errorDescription ?? ""
            #expect(desc.contains("Pro"))
        }
    }
}

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

    @Test("ProGate: Free プランの上限定数")
    @MainActor
    func proGateLimits() {
        #expect(ProGate.freeRoutineLimit == 5)
        #expect(ProGate.freeCustomExerciseLimit == 5)
    }

    @Test("ProGate: 未購入時でも Live Activity は Free 開放されている")
    @MainActor
    func proGateOffByDefault() {
        // テスト環境では Transaction.currentEntitlements は空のため isProActive == false
        #expect(ProGate.isProActive == false)
        #expect(ProGate.canCreateUnlimitedRoutines == false)
        #expect(ProGate.canCreateUnlimitedCustomExercises == false)
        #expect(ProGate.canReadHealthData == false)
        #expect(ProGate.canUseAICoaching == false)
        // Live Activity は v0.x で Free 開放済み（Pro 訴求は HRV コーチング側に集約）
        #expect(ProGate.canUseLiveActivity == true)
        #expect(ProGate.canUseICloudSync == false)
        #expect(ProGate.canSeeAdvancedAnalytics == false)
        #expect(ProGate.canExportData == false)
    }

    @Test("ProGateError: localizedDescription に Pro 文字列を含む")
    func proGateErrorMessages() {
        let errors: [ProGateError] = [
            .routineLimitReached(current: 5, limit: 5),
            .customExerciseLimitReached(current: 5, limit: 5),
            .healthDataReadRequiresPro,
            .aiCoachingRequiresPro,
            .liveActivityRequiresPro,
            .iCloudSyncRequiresPro,
        ]
        for error in errors {
            let desc = error.errorDescription ?? ""
            #expect(desc.contains("Pro"))
        }
    }
}

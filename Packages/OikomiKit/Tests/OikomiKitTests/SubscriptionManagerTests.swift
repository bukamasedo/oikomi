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
}

import Foundation
import Testing

@testable import OikomiKit

@Suite("TipJar")
struct TipJarManagerTests {

    @Test("TipProductIDs.all は 4 件の Consumable で構成される")
    func tipProductIDsCount() {
        #expect(TipProductIDs.all.count == 4)
        #expect(TipProductIDs.all.contains("com.shuhirouchi.oikomi.tip.protein"))
        #expect(TipProductIDs.all.contains("com.shuhirouchi.oikomi.tip.chicken"))
        #expect(TipProductIDs.all.contains("com.shuhirouchi.oikomi.tip.steak"))
        #expect(TipProductIDs.all.contains("com.shuhirouchi.oikomi.tip.cheatday"))
    }

    @Test("TipProductIDs の bundle プレフィックスが一貫している")
    func tipProductIDsBundlePrefix() {
        let prefix = "com.shuhirouchi.oikomi.tip."
        for id in TipProductIDs.all {
            #expect(id.hasPrefix(prefix))
        }
    }

    @Test("TipProductKind: 金額が仕様通り（120 / 250 / 500 / 1000 JPY）")
    func tipKindAmounts() {
        #expect(TipProductKind.protein.amountJPY == 120)
        #expect(TipProductKind.chicken.amountJPY == 250)
        #expect(TipProductKind.steak.amountJPY == 500)
        #expect(TipProductKind.cheatday.amountJPY == 1_000)
    }

    @Test("TipProductKind: 各 kind に絵文字と displayName が定義されている")
    func tipKindMetadata() {
        for kind in TipProductKind.allCases {
            #expect(!kind.emoji.isEmpty)
            #expect(!kind.displayName.isEmpty)
            #expect(!kind.productID.isEmpty)
        }
    }

    @Test("TipProductIDs.kind(for:) で productID → kind の逆引きができる")
    func reverseLookup() {
        for kind in TipProductKind.allCases {
            #expect(TipProductIDs.kind(for: kind.productID) == kind)
        }
        #expect(TipProductIDs.kind(for: "com.shuhirouchi.oikomi.pro.monthly") == nil)
        #expect(TipProductIDs.kind(for: "unknown") == nil)
    }

    @Test("nextTotals: 加算で count +1、金額は加算される")
    func nextTotalsBasic() {
        let next = TipJarManager.nextTotals(currentCount: 3, currentAmount: 750, adding: 500)
        #expect(next.count == 4)
        #expect(next.amount == 1_250)
    }

    @Test("nextTotals: 初回支援（0 → 1）も正しく加算される")
    func nextTotalsFirstTime() {
        let next = TipJarManager.nextTotals(currentCount: 0, currentAmount: 0, adding: 120)
        #expect(next.count == 1)
        #expect(next.amount == 120)
    }

    @Test("nextTotals: 負の金額が来ても累計金額は減らさない（防衛）")
    func nextTotalsNegativeGuard() {
        let next = TipJarManager.nextTotals(currentCount: 2, currentAmount: 500, adding: -100)
        #expect(next.count == 3)
        #expect(next.amount == 500)
    }

    @Test("TipJarManager.shared は単一インスタンス")
    @MainActor
    func sharedSingleton() {
        let a = TipJarManager.shared
        let b = TipJarManager.shared
        #expect(a === b)
        #expect(a.purchaseInProgress == false)
    }
}

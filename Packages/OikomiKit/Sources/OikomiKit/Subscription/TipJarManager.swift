import Foundation
import StoreKit

/// 開発者支援（Tip Jar）の消耗型 IAP を管理する。
///
/// 設計方針:
/// - Consumable は `Transaction.currentEntitlements` に残らないため、購入完了の確定は
///   `Transaction.updates` / `Transaction.unfinished` 経由で `finish()` するときに行う
/// - 累計サポート回数・金額は UserDefaults と `NSUbiquitousKeyValueStore` の両方に書く。
///   後者は同一 Apple ID のデバイス間で同期される（容量 1MB 制限の中で十分軽い）
/// - `SubscriptionManager` とは独立。Pro 解放には一切影響しない
@MainActor
@Observable
public final class TipJarManager {

    public static let shared = TipJarManager()

    /// 累計サポート回数（UserDefaults / iCloud KVS キー）。
    public static let totalCountKey = "OikomiTipTotalCount"
    /// 累計サポート金額（JPY、UserDefaults / iCloud KVS キー）。
    public static let totalAmountKey = "OikomiTipTotalAmountJPY"

    public private(set) var products: [Product] = []
    public private(set) var totalCount: Int = 0
    public private(set) var totalAmountJPY: Int = 0
    public private(set) var purchaseInProgress: Bool = false
    public private(set) var lastError: String?

    private var didStart: Bool = false
    private var listenerTask: Task<Void, Never>?
    private var processedTransactionIDs: Set<UInt64> = []

    private init() {}

    /// App 起動時に 1 度呼ぶ。商品ロード + Transaction listener 開始 + 未完了処理 + KVS 購読。
    public func start() async {
        if !didStart {
            didStart = true
            loadTotalsFromStorage()
            subscribeToCloudChanges()
            listenerTask = Task.detached { [weak self] in
                for await update in Transaction.updates {
                    await self?.handle(update: update)
                }
            }
            // 直近の購入完了直後にアプリが終了していた場合の救済
            await processUnfinishedTransactions()
            // iCloud KVS の最新値を取り寄せる（初回起動時のシード）
            NSUbiquitousKeyValueStore.default.synchronize()
            mergeFromCloudIfNewer()
        }
        await loadProducts()
    }

    /// App Store から Product 情報を取得して `products` を更新する。
    public func loadProducts() async {
        do {
            let fetched = try await Product.products(for: TipProductIDs.all)
            // 金額昇順に並べる
            self.products = fetched.sorted { lhs, rhs in lhs.price < rhs.price }
        } catch {
            lastError = "商品情報の取得に失敗: \(error.localizedDescription)"
            print("[Oikomi.tip] loadProducts failed: \(error)")
        }
    }

    /// 指定の Tip 商品を購入する。成功時は累計が加算され、true を返す。
    @discardableResult
    public func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        lastError = nil
        defer { purchaseInProgress = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await handle(transaction: transaction)
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    public func clearLastError() {
        lastError = nil
    }

    // MARK: - Totals

    /// 累計加算の純粋関数。テスト容易性のため切り出す。
    public nonisolated static func nextTotals(
        currentCount: Int, currentAmount: Int, adding amount: Int
    ) -> (count: Int, amount: Int) {
        (currentCount + 1, currentAmount + max(0, amount))
    }

    // MARK: - Private

    private func handle(update result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await handle(transaction: transaction)
        } catch {
            print("[Oikomi.tip] transaction verification failed: \(error)")
        }
    }

    private func handle(transaction: Transaction) async {
        guard TipProductIDs.all.contains(transaction.productID) else {
            // サブスク側のトランザクションがここに来ることはないが、安全側でスキップ
            await transaction.finish()
            return
        }
        // 二重カウント防止（updates と purchase() の両方から来うる）
        if processedTransactionIDs.contains(transaction.id) {
            await transaction.finish()
            return
        }
        processedTransactionIDs.insert(transaction.id)

        let amount = TipProductIDs.kind(for: transaction.productID)?.amountJPY ?? 0
        let next = Self.nextTotals(
            currentCount: totalCount, currentAmount: totalAmountJPY, adding: amount)
        totalCount = next.count
        totalAmountJPY = next.amount
        persistTotals()

        await transaction.finish()
    }

    private func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            await handle(update: result)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    private func loadTotalsFromStorage() {
        let defaults = UserDefaults.standard
        totalCount = defaults.integer(forKey: Self.totalCountKey)
        totalAmountJPY = defaults.integer(forKey: Self.totalAmountKey)
    }

    private func persistTotals() {
        let defaults = UserDefaults.standard
        defaults.set(totalCount, forKey: Self.totalCountKey)
        defaults.set(totalAmountJPY, forKey: Self.totalAmountKey)

        let kvs = NSUbiquitousKeyValueStore.default
        kvs.set(Int64(totalCount), forKey: Self.totalCountKey)
        kvs.set(Int64(totalAmountJPY), forKey: Self.totalAmountKey)
        kvs.synchronize()
    }

    private func subscribeToCloudChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.mergeFromCloudIfNewer()
            }
        }
    }

    /// iCloud KVS の値がローカルより大きければ採用する（消耗型は単調増加のため max でマージ）。
    private func mergeFromCloudIfNewer() {
        let kvs = NSUbiquitousKeyValueStore.default
        let cloudCount = Int(kvs.longLong(forKey: Self.totalCountKey))
        let cloudAmount = Int(kvs.longLong(forKey: Self.totalAmountKey))
        var changed = false
        if cloudCount > totalCount {
            totalCount = cloudCount
            changed = true
        }
        if cloudAmount > totalAmountJPY {
            totalAmountJPY = cloudAmount
            changed = true
        }
        if changed {
            UserDefaults.standard.set(totalCount, forKey: Self.totalCountKey)
            UserDefaults.standard.set(totalAmountJPY, forKey: Self.totalAmountKey)
        }
    }
}

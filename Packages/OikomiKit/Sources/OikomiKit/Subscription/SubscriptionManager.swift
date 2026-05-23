import Foundation
import StoreKit

/// StoreKit 2 ベースのサブスクリプション管理。
///
/// 設計方針:
/// - 真実のソースは `Transaction.currentEntitlements`。SwiftData / UserDefaults へキャッシュしない
/// - `Transaction.updates` の AsyncStream を起動時から購読し、renew / refund / 期限切れを反映
/// - iPhone / Watch / Mac 全ターゲットから `shared` で参照可能（OikomiKit に同梱）
/// - 同一 Apple ID であれば各デバイスが独自に `currentEntitlements` を見るため、デバイス間同期は不要
/// - 機能ゲートは別 PR で `isProActive` を消費する側を実装
@MainActor
@Observable
public final class SubscriptionManager {

    public static let shared = SubscriptionManager()

    /// `bootstrap()` のような同期文脈から isProActive を確認するために、UserDefaults に
    /// 直近の値をキャッシュする。リネーム時は SharedContainer 側と合わせて変更すること。
    public static let lastKnownProActiveKey = "OikomiLastKnownProActive"

    /// App Store から取得済みの Product 一覧（月額 / 年額）。
    public private(set) var products: [Product] = []

    /// Pro サブスクリプションが現在有効か。
    /// `Transaction.currentEntitlements` を評価して導出する。
    public private(set) var isProActive: Bool = false

    /// 購入処理中かどうか（UI のローディング表示用）。
    public private(set) var purchaseInProgress: Bool = false

    /// 直近のエラーメッセージ（UI でアラート表示）。
    public private(set) var lastError: String?

    /// 14 日間無料トライアル適格か（initial purchase 前のみ true）。
    public private(set) var isEligibleForIntroOffer: Bool = false

    /// `start()` が走った後 `true`。`Transaction.updates` の listener が稼働中。
    private var didStart: Bool = false
    private var listenerTask: Task<Void, Never>?

    private init() {}

    /// App 起動時に 1 度呼ぶ。商品ロード + Transaction listener 開始 + 現在の権利確認。
    /// 冪等：複数回呼んでも問題なし。
    public func start() async {
        if !didStart {
            didStart = true
            listenerTask = Task.detached { [weak self] in
                for await update in Transaction.updates {
                    await self?.handle(update: update)
                }
            }
        }
        await loadProducts()
        await refreshEntitlement()
    }

    /// App Store から Product 情報を取得して `products` を更新する。
    /// 失敗しても致命的ではない（再試行可能）。
    public func loadProducts() async {
        do {
            let fetched = try await Product.products(for: ProductIDs.all)
            // 年額 → 月額 の順で並べる（UI で年額をハイライトしたいため）
            self.products = fetched.sorted { lhs, rhs in
                lhs.id == ProductIDs.proYearly && rhs.id == ProductIDs.proMonthly
            }
            await updateIntroEligibility()
        } catch {
            lastError = "商品情報の取得に失敗: \(error.localizedDescription)"
            print("[Oikomi.sub] loadProducts failed: \(error)")
        }
    }

    /// 月額 / 年額を購入する。成功時 `isProActive` が `true` に変わる。
    /// 戻り値は実際に Entitlement が付与されたかどうか（ペンディング・キャンセル時は false）。
    @discardableResult
    public func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        lastError = nil
        defer { purchaseInProgress = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlement()
            return isProActive
        case .userCancelled:
            return false
        case .pending:
            // 親の承認待ち（Family Sharing 等）。完了時に Transaction.updates で受け取る。
            return false
        @unknown default:
            return false
        }
    }

    /// UI からエラー表示を閉じた際に呼ぶ。
    public func clearLastError() {
        lastError = nil
    }

    /// 過去の購入を復元。StoreKit 2 では `AppStore.sync()` が正式 API。
    public func restore() async throws {
        purchaseInProgress = true
        lastError = nil
        defer { purchaseInProgress = false }

        try await AppStore.sync()
        await refreshEntitlement()
    }

    /// 現在の有効な Entitlement を再評価して `isProActive` を更新する。
    public func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if ProductIDs.all.contains(transaction.productID),
                transaction.revocationDate == nil,
                (transaction.expirationDate ?? .distantFuture) > Date()
            {
                active = true
                break
            }
        }
        self.isProActive = active
        // 同期文脈（SharedContainer.bootstrap など）から参照できるようキャッシュ
        UserDefaults.standard.set(active, forKey: Self.lastKnownProActiveKey)
        await updateIntroEligibility()
    }

    // MARK: - Private

    private func handle(update result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await transaction.finish()
            await refreshEntitlement()
        } catch {
            print("[Oikomi.sub] transaction verification failed: \(error)")
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func updateIntroEligibility() async {
        // 月額・年額のいずれかが intro offer 適格かを判定する。
        // どちらか一方でも一度購入していれば全体が ineligible 扱い。
        for product in products {
            guard let subscription = product.subscription else { continue }
            let eligible = await subscription.isEligibleForIntroOffer
            if eligible {
                self.isEligibleForIntroOffer = true
                return
            }
        }
        self.isEligibleForIntroOffer = false
    }
}

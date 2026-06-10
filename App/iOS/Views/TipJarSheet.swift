import OikomiKit
import StoreKit
import SwiftUI

/// 開発者支援（Tip Jar）の購入シート。
///
/// 4 種の Consumable IAP を一覧から購入できる。購入完了で TipThankYouView に切り替わる。
/// Pro 解放には影響しない、純粋なドネーション機構。
struct TipJarSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var tipJar = TipJarManager.shared
    @State private var showThankYou: Bool = false
    @State private var lastPurchasedKind: TipProductKind?
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if showThankYou {
                    TipThankYouView(
                        purchasedKind: lastPurchasedKind,
                        onClose: { dismiss() },
                        onBack: { showThankYou = false }
                    )
                } else {
                    purchaseList
                }
            }
            .navigationTitle("開発者を支援")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { tipJar.clearLastError() }
            } message: {
                Text(tipJar.lastError ?? "")
            }
            .onChange(of: tipJar.lastError) { _, newValue in
                showError = newValue != nil
            }
            .task {
                if tipJar.loadState == .idle {
                    await tipJar.loadProducts()
                }
            }
        }
    }

    // MARK: - Purchase list

    @ViewBuilder
    private var purchaseList: some View {
        ScrollView {
            VStack(spacing: 24) {
                introCard
                switch tipJar.loadState {
                case .idle, .loading:
                    ProgressView().padding(.vertical, 40)
                case .loaded:
                    if tipJar.products.isEmpty {
                        emptyStateCard
                    } else {
                        VStack(spacing: 12) {
                            ForEach(orderedKinds(), id: \.rawValue) { kind in
                                if let product = product(for: kind) {
                                    tipRow(kind: kind, product: product)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                case .failed:
                    errorStateCard
                }
                noteSection
            }
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("現在チップ商品をご利用いただけません")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("再試行") {
                Task { await tipJar.loadProducts() }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var errorStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("商品情報の取得に失敗しました")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("再試行") {
                Task { await tipJar.loadProducts() }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var introCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(OikomiColor.brandPrimary)
                .accessibilityHidden(true)
            Text("Oikomi の開発を応援")
                .font(.title3.weight(.semibold))
            Text("いつもありがとうございます。お気持ちで支援いただけると、開発の励みになります。Pro とは別の任意のチップです。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func tipRow(kind: TipProductKind, product: Product) -> some View {
        Button {
            Task { await purchase(product: product, kind: kind) }
        } label: {
            HStack(spacing: 14) {
                Image(kind.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(tipRowSubtitle(for: kind))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .disabled(tipJar.purchaseInProgress)
    }

    private func tipRowSubtitle(for kind: TipProductKind) -> String {
        switch kind {
        case .pocari: String(localized: "ライトな応援")
        case .protein: String(localized: "ちょっと多めの応援")
        case .chicken: String(localized: "ガッツリ応援")
        case .cheatday: String(localized: "最大級の応援")
        }
    }

    @ViewBuilder
    private var noteSection: some View {
        VStack(spacing: 6) {
            Text("チップは消耗型 IAP です。復元はできません。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("購入によって Pro 機能が解放されることはありません。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func orderedKinds() -> [TipProductKind] {
        TipProductKind.allCases.sorted { $0.amountJPY < $1.amountJPY }
    }

    private func product(for kind: TipProductKind) -> Product? {
        tipJar.products.first(where: { $0.id == kind.productID })
    }

    private func purchase(product: Product, kind: TipProductKind) async {
        do {
            let ok = try await tipJar.purchase(product)
            if ok {
                lastPurchasedKind = kind
                showThankYou = true
            }
        } catch {
            print("[Oikomi.tip] purchase failed: \(error)")
        }
    }
}

// MARK: - Thank You View

struct TipThankYouView: View {

    let purchasedKind: TipProductKind?
    let onClose: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(OikomiColor.brandPrimary.opacity(0.18))
                    .frame(width: 160, height: 160)
                Image(purchasedKind?.imageName ?? TipProductKind.pocari.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 8) {
                Text("ありがとうございます！")
                    .font(.largeTitle.weight(.bold))
                if let kind = purchasedKind {
                    Text("\(kind.displayName) の応援、しっかり受け取りました。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            Text("追い込みの日々を続けます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(spacing: 10) {
                Button {
                    onClose()
                } label: {
                    Text("閉じる")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onBack()
                } label: {
                    Text("もう一度応援する")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }
}

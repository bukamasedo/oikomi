import OikomiKit
import StoreKit
import SwiftUI

struct OnboardingView: View {

    @Binding var isPresented: Bool

    @State private var step: Step = .welcome
    @State private var healthAuthorizationDone = false

    enum Step: Int, CaseIterable {
        case welcome
        case profile
        case integrations
        case pro
    }

    var body: some View {
        VStack {
            switch step {
            case .welcome:
                WelcomeStep(onContinue: { step = .profile })
            case .profile:
                ProfileStep(onContinue: { step = .integrations })
            case .integrations:
                IntegrationsStep(
                    healthDone: healthAuthorizationDone,
                    onRequestHealth: requestHealth,
                    onRequestNotifications: requestNotifications,
                    onContinue: { step = .pro }
                )
            case .pro:
                OnboardingProStep(onFinish: finish)
            }
        }
        .interactiveDismissDisabled()
    }

    private func requestHealth() {
        Task { @MainActor in
            do {
                try await HealthStore.shared.requestWorkoutWriteAuthorization()
            } catch {
                // 拒否されても続行可能
            }
            healthAuthorizationDone = true
        }
    }

    private func requestNotifications() {
        Task { @MainActor in
            await RestTimerNotifier.requestAuthorization()
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: OnboardingState.completedKey)
        isPresented = false
        Task { @MainActor in
            await NotificationCoordinator.bootstrap()
        }
    }
}

enum OnboardingState {
    static let completedKey = "OikomiOnboardingCompleted_v1"
    static var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }
}

// MARK: - Shared components

private struct OnboardingStepIndicator: View {
    let current: Int

    private let total = OnboardingView.Step.allCases.count

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { idx in
                Capsule()
                    .fill(idx == current ? OikomiColor.brandPrimary : OikomiColor.textTertiary)
                    .frame(width: idx == current ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: current)
            }
        }
    }
}

private struct OnboardingHeroIcon<Background: ShapeStyle>: View {
    let symbol: String
    let tint: Color
    let background: Background
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle().fill(background)
            Image(systemName: symbol)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

private struct OnboardingPrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: OikomiSpacing.s) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, OikomiSpacing.m + 2)
        }
        .buttonStyle(.borderedProminent)
        .tint(OikomiColor.brandPrimary)
        .disabled(isLoading)
    }
}

private struct ValueRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: OikomiSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                    .fill(OikomiColor.brandPrimary.opacity(0.14))
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandPrimary)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 0)
                .padding(.top, OikomiSpacing.xl)

            Spacer(minLength: OikomiSpacing.xxl)

            VStack(spacing: OikomiSpacing.l) {
                OnboardingHeroIcon(
                    symbol: "figure.strengthtraining.traditional",
                    tint: .white,
                    background: LinearGradient(
                        colors: [OikomiColor.brandPrimary, OikomiColor.brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    size: 132
                )
                Text("Oikomi へようこそ")
                    .font(.largeTitle.weight(.bold))
                Text("Apple Watch で完結する筋トレ記録")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: OikomiSpacing.xl) {
                ValueRow(
                    icon: "applewatch",
                    title: "手首だけで完結",
                    description: "Apple Watch スタンドアロン。Digital Crown で 1〜3 タップで記録"
                )
                ValueRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "数値で見える進捗",
                    description: "ボリューム推移と PR を可視化。HRV 連動の自動アドバイスは Pro で解放"
                )
                ValueRow(
                    icon: "character.bubble",
                    title: "日本語ネイティブ",
                    description: "UI・種目名・コーチング文言すべて自然な日本語"
                )
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.top, OikomiSpacing.xxl)

            Spacer()

            OnboardingPrimaryButton(title: "はじめる", action: onContinue)
                .padding(.horizontal, OikomiSpacing.xxl)
                .padding(.bottom, OikomiSpacing.xxxl)
        }
        .background(OikomiColor.appBackground)
    }
}

// MARK: - Profile

/// 経験・目標・週目標・場所・重量単位を 1 画面で設定する。
/// すべてデフォルト選択済みで、こだわらないユーザーは無操作で「次へ」を押せる（短さ優先）。
/// 保存先は設定タブの環境セクションと同一キーのため、双方向に一致する。
private struct ProfileStep: View {
    let onContinue: () -> Void

    // 経験 / 目標 / 週目標 / 場所 は SettingsTabView と同一の @AppStorage キーで即時保存する。
    @AppStorage(TrainingProfilePreference.experienceKey) private var experienceRaw =
        TrainingProfile.default.experience.rawValue
    @AppStorage(TrainingProfilePreference.goalKey) private var goalRaw =
        TrainingProfile.default.goal.rawValue
    @AppStorage(WeeklyTrainingTarget.storageKey) private var weeklyTargetDays =
        WeeklyTrainingTarget.defaultDays
    @AppStorage("OikomiPreferredLocation") private var locationRaw = Location.gym.rawValue

    // 重量単位だけは App Group suite 保存のため @AppStorage(.standard) を使えない。
    // 「次へ」押下時に UnitPreference 経由で書き込み、Watch にも同期する。
    @State private var unit: WeightUnit = UnitPreference.current()

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 1)
                .padding(.top, OikomiSpacing.xl)

            ScrollView {
                VStack(spacing: OikomiSpacing.xl) {
                    OnboardingHeroIcon(
                        symbol: "slider.horizontal.3",
                        tint: OikomiColor.brandPrimary,
                        background: OikomiColor.brandPrimary.opacity(0.14),
                        size: 84
                    )
                    .padding(.top, OikomiSpacing.l)

                    VStack(spacing: OikomiSpacing.xs) {
                        Text("あなたについて")
                            .font(.title.weight(.bold))
                        Text("コーチングの精度を高めます。あとで設定でいつでも変更できます。")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, OikomiSpacing.xl)
                    }

                    VStack(spacing: 0) {
                        ProfileRow(label: "経験レベル") {
                            Picker("経験レベル", selection: $experienceRaw) {
                                ForEach(ExperienceLevel.allCases, id: \.rawValue) { level in
                                    Text(level.displayName).tag(level.rawValue)
                                }
                            }
                        }
                        Divider()
                        ProfileRow(label: "目標") {
                            Picker("目標", selection: $goalRaw) {
                                ForEach(TrainingGoal.allCases, id: \.rawValue) { goal in
                                    Text(goal.displayName).tag(goal.rawValue)
                                }
                            }
                        }
                        Divider()
                        ProfileRow(label: "週のトレーニング日数") {
                            Picker("週のトレーニング日数", selection: $weeklyTargetDays) {
                                ForEach(WeeklyTrainingTarget.allowedRange, id: \.self) { days in
                                    Text("週 \(days) 日").tag(days)
                                }
                            }
                        }
                        Divider()
                        ProfileRow(label: "場所") {
                            Picker("場所", selection: $locationRaw) {
                                Text("ジム").tag(Location.gym.rawValue)
                                Text("自宅").tag(Location.home.rawValue)
                            }
                        }
                        Divider()
                        ProfileRow(label: "重量の単位") {
                            Picker("重量の単位", selection: $unit) {
                                ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                                    Text("\(unit.localizedName) (\(unit.symbol))").tag(unit)
                                }
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                            .fill(OikomiColor.cardBackground)
                    )
                    .padding(.horizontal, OikomiSpacing.xxl)
                }
                .padding(.bottom, OikomiSpacing.xl)
            }

            OnboardingPrimaryButton(title: "次へ") {
                // 重量単位は App Group へ保存し、設定タブと同様に Watch へ同期する。
                UnitPreference.set(unit)
                WCSyncBridge.shared.sendUnitPreferenceUpdate(unit)
                onContinue()
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.top, OikomiSpacing.s)
            .padding(.bottom, OikomiSpacing.xxxl)
        }
        .background(OikomiColor.appBackground)
    }
}

/// ラベル左・セレクトボックス右のフォーム行。`content` はメニュー方式の `Picker` を想定。
private struct ProfileRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer(minLength: OikomiSpacing.m)
            content
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(OikomiColor.brandPrimary)
        }
        .padding(.horizontal, OikomiSpacing.l)
        .padding(.vertical, OikomiSpacing.s + 2)
    }
}

// MARK: - Integrations (HealthKit + Notifications)

/// HealthKit と通知の許可を 1 画面に統合。どちらも任意で、「次へ」で許可状況に関わらず進める。
private struct IntegrationsStep: View {
    let healthDone: Bool
    let onRequestHealth: () -> Void
    let onRequestNotifications: () -> Void
    let onContinue: () -> Void

    @State private var notifRequested = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 2)
                .padding(.top, OikomiSpacing.xl)

            Spacer(minLength: OikomiSpacing.xl)

            OnboardingHeroIcon(
                symbol: "link",
                tint: OikomiColor.brandPrimary,
                background: OikomiColor.brandPrimary.opacity(0.14)
            )

            VStack(spacing: OikomiSpacing.s) {
                Text("連携")
                    .font(.title.weight(.bold))
                Text("ヘルスケアと通知を有効にすると、記録の保存とトレーニングのサポートが受けられます。どちらも後から設定で変更できます。")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, OikomiSpacing.xxl)
            }
            .padding(.top, OikomiSpacing.l)

            VStack(spacing: OikomiSpacing.m) {
                PermissionRow(
                    icon: "heart.text.square.fill",
                    tint: .pink,
                    title: "ヘルスケア連携",
                    description: "ワークアウトを保存。HRV・睡眠の活用は Pro で解放（計算はオンデバイス完結）",
                    isDone: healthDone,
                    action: onRequestHealth
                )
                PermissionRow(
                    icon: "bell.badge.fill",
                    tint: OikomiColor.brandPrimary,
                    title: "通知",
                    description: "レスト終了・PR 予測・終了し忘れをお知らせ",
                    isDone: notifRequested,
                    action: {
                        onRequestNotifications()
                        notifRequested = true
                    }
                )
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.top, OikomiSpacing.xl)

            Spacer()

            VStack(spacing: OikomiSpacing.s) {
                OnboardingPrimaryButton(title: "次へ", action: onContinue)
                Text("許可は後から「設定 → 連携・同期 / 通知」で変更できます")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.bottom, OikomiSpacing.xxxl)
        }
        .background(OikomiColor.appBackground)
    }
}

private struct PermissionRow: View {
    let icon: String
    let tint: Color
    let title: String
    let description: String
    let isDone: Bool
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: OikomiSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                    .fill(tint.opacity(0.14))
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: OikomiSpacing.s)

            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Button("許可", action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(OikomiColor.brandPrimary)
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }
}

// MARK: - Pro

private struct OnboardingProStep: View {
    let onFinish: () -> Void

    @State private var manager = SubscriptionManager.shared
    @State private var showError = false

    private var yearly: Product? {
        manager.products.first(where: { $0.id == ProductIDs.proYearly })
    }

    private var ctaLabel: String {
        manager.isEligibleForIntroOffer ? "14 日間無料で試す" : "Pro を購入する"
    }

    private var isPurchaseAvailable: Bool {
        yearly != nil && manager.loadState == .loaded
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 3)
                .padding(.top, OikomiSpacing.xl)

            Spacer(minLength: OikomiSpacing.xxl)

            OnboardingHeroIcon(
                symbol: "sparkles",
                tint: .white,
                background: LinearGradient(
                    colors: [OikomiColor.brandPrimary, OikomiColor.proAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                size: 132
            )

            VStack(spacing: OikomiSpacing.s) {
                Text("Oikomi Pro")
                    .font(.largeTitle.weight(.bold))
                Text("HRV と AI で、追い込みをもっと賢く")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, OikomiSpacing.xxl)
            }
            .padding(.top, OikomiSpacing.l)

            VStack(alignment: .leading, spacing: OikomiSpacing.l) {
                ForEach(ProFeatureCatalog.highlightFeatures) { feature in
                    ProValueRow(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description
                    )
                }
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.top, OikomiSpacing.xl)

            Spacer()

            VStack(spacing: OikomiSpacing.m) {
                OnboardingProPricingStatus(
                    loadState: manager.loadState,
                    yearly: yearly,
                    isEligibleForIntroOffer: manager.isEligibleForIntroOffer,
                    onRetry: reloadProducts
                )

                OnboardingPrimaryButton(
                    title: ctaLabel,
                    isLoading: manager.purchaseInProgress,
                    action: purchaseYearly
                )
                .disabled(!isPurchaseAvailable || manager.purchaseInProgress)

                // Guideline 3.1.1: 購入導線と同一画面に「購入を復元」を提供する。
                Button("購入を復元", action: restorePurchases)
                    .font(.subheadline)
                    .disabled(manager.purchaseInProgress)
                    .padding(.top, OikomiSpacing.xs)

                Button("今はしない", action: onFinish)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, OikomiSpacing.xs)

                // Guideline 3.1.2: 購入導線と同一画面に自動更新条件と法的リンクを明示する。
                Text(Self.autoRenewDisclosure)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, OikomiSpacing.xs)

                HStack(spacing: OikomiSpacing.l) {
                    Link("利用規約", destination: URL(string: "https://bukamasedo.github.io/oikomi/legal/terms/")!)
                    Link("プライバシーポリシー", destination: URL(string: "https://bukamasedo.github.io/oikomi/legal/privacy/")!)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.bottom, OikomiSpacing.xxxl)
        }
        .background(OikomiColor.appBackground)
        .task {
            if manager.products.isEmpty {
                await manager.loadProducts()
            }
        }
        .onChange(of: manager.isProActive) { _, isActive in
            if isActive { onFinish() }
        }
        .onChange(of: manager.lastError) { _, error in
            // 商品ロード失敗時は本体 UI に出すのでアラートでは出さない。購入経路のエラーのみ拾う。
            if case .failed = manager.loadState {
                showError = false
            } else {
                showError = error != nil
            }
        }
        .alert(
            "購入できませんでした",
            isPresented: $showError,
            presenting: manager.lastError
        ) { _ in
            Button("OK") { manager.clearLastError() }
        } message: { message in
            Text(message)
        }
    }

    private func purchaseYearly() {
        Task {
            guard let yearly else { return }
            _ = try? await manager.purchase(yearly)
        }
    }

    private func reloadProducts() {
        Task { await manager.loadProducts() }
    }

    /// 復元に成功して Pro が有効化されると `onChange(isProActive)` 経由で `onFinish()` が走る。
    private func restorePurchases() {
        Task { try? await manager.restore() }
    }

    /// 自動更新サブスクリプションの定型開示文（年額トライアル前提）。
    static let autoRenewDisclosure =
        "サブスクリプションは期間終了の 24 時間前までに解約しない限り自動更新され、Apple ID に課金されます。"
        + "無料トライアル中に解約した場合は課金されません。購入後は App Store の「サブスクリプション」からいつでも管理・解約できます。"
}

private struct OnboardingProPricingStatus: View {
    let loadState: SubscriptionManager.LoadState
    let yearly: Product?
    let isEligibleForIntroOffer: Bool
    let onRetry: () -> Void

    var body: some View {
        switch loadState {
        case .idle, .loading:
            HStack(spacing: OikomiSpacing.s) {
                ProgressView()
                    .controlSize(.small)
                Text("価格を取得中…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .failed(let message):
            LoadFailureView(
                title: "価格情報を取得できませんでした",
                message: message,
                onRetry: onRetry
            )
        case .loaded:
            if let yearly {
                // Guideline 3.1.2: トライアル長と「終了後に課金される金額・期間」を一文で結びつける。
                Text(
                    isEligibleForIntroOffer
                        ? "14日間無料、その後 \(yearly.displayPrice)/年 ・ いつでも解約可"
                        : "\(yearly.displayPrice)/年 ・ いつでも解約可"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            } else {
                LoadFailureView(
                    title: "価格情報が見つかりませんでした",
                    message: "もう一度お試しください。",
                    onRetry: onRetry
                )
            }
        }
    }
}

private struct ProValueRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: OikomiSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                    .fill(OikomiColor.proAccent.opacity(0.20))
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OikomiColor.brandPrimary)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

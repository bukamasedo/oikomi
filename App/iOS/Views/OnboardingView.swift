import OikomiKit
import StoreKit
import SwiftUI

struct OnboardingView: View {

    @Binding var isPresented: Bool

    @State private var step: Step = .welcome
    @State private var healthAuthorizationDone = false

    enum Step: Int, CaseIterable {
        case welcome
        case healthKit
        case notifications
        case routinePrompt
        case weightUnit
        case pro
    }

    var body: some View {
        VStack {
            switch step {
            case .welcome:
                WelcomeStep(onContinue: { step = .healthKit })
            case .healthKit:
                HealthKitStep(
                    isDone: healthAuthorizationDone,
                    onRequest: requestHealth,
                    onContinue: { step = .notifications }
                )
            case .notifications:
                NotificationsStep(onRequest: requestNotifications, onContinue: { step = .routinePrompt })
            case .routinePrompt:
                RoutinePromptStep(onContinue: { step = .weightUnit })
            case .weightUnit:
                WeightUnitStep(onContinue: { step = .pro })
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

private struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline)
        }
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

// MARK: - HealthKit

private struct HealthKitStep: View {
    let isDone: Bool
    let onRequest: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 1)
                .padding(.top, OikomiSpacing.xl)

            Spacer(minLength: OikomiSpacing.xxl)

            OnboardingHeroIcon(
                symbol: "heart.text.square.fill",
                tint: .pink,
                background: Color.pink.opacity(0.14)
            )

            VStack(spacing: OikomiSpacing.s) {
                Text("ヘルスケア連携")
                    .font(.title.weight(.bold))
                Text("ワークアウトをヘルスケアに保存し、HRV や睡眠からトレーニング負荷を最適化します。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, OikomiSpacing.xxl)
            }
            .padding(.top, OikomiSpacing.l)

            VStack(alignment: .leading, spacing: OikomiSpacing.m) {
                BulletPoint(text: "ワークアウトをヘルスケアに保存")
                BulletPoint(text: "HRV・睡眠の活用は Pro で解放（権限はここで一括許可）")
                BulletPoint(text: "すべての計算はオンデバイスで完結")
            }
            .padding(.horizontal, OikomiSpacing.xxxl)
            .padding(.top, OikomiSpacing.xl)

            Spacer()

            VStack(spacing: OikomiSpacing.m) {
                if isDone {
                    OnboardingPrimaryButton(
                        title: "次へ",
                        systemImage: "checkmark.circle.fill",
                        action: onContinue
                    )
                } else {
                    OnboardingPrimaryButton(title: "次へ", action: onRequest)
                }
                Text("「次へ」を選ぶと、ヘルスケアの権限を確認します。許可は後から「設定 → ヘルスケア連携」で変更できます")
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

// MARK: - Notifications

private struct NotificationsStep: View {
    let onRequest: () -> Void
    let onContinue: () -> Void

    @State private var requested = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 2)
                .padding(.top, OikomiSpacing.xl)

            Spacer(minLength: OikomiSpacing.xxl)

            OnboardingHeroIcon(
                symbol: "bell.badge.fill",
                tint: OikomiColor.brandPrimary,
                background: OikomiColor.brandPrimary.opacity(0.14)
            )

            VStack(spacing: OikomiSpacing.s) {
                Text("通知でサポート")
                    .font(.title.weight(.bold))
                Text("レスト終了や AI コーチング、トライアル残日数などをお知らせします。各通知は設定タブで個別に OFF にできます。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, OikomiSpacing.xxl)
            }
            .padding(.top, OikomiSpacing.l)

            VStack(alignment: .leading, spacing: OikomiSpacing.m) {
                BulletPoint(text: "レスト終了を Apple Watch でお知らせ")
                BulletPoint(text: "翌日 PR 圏内の種目があれば朝に通知")
                BulletPoint(text: "ワークアウト終了し忘れをリマインド")
            }
            .padding(.horizontal, OikomiSpacing.xxxl)
            .padding(.top, OikomiSpacing.xl)

            Spacer()

            VStack(spacing: OikomiSpacing.m) {
                if requested {
                    OnboardingPrimaryButton(
                        title: "次へ",
                        systemImage: "checkmark.circle.fill",
                        action: onContinue
                    )
                } else {
                    OnboardingPrimaryButton(title: "通知を許可") {
                        onRequest()
                        requested = true
                    }
                    Button("後で設定", action: onContinue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("通知は後から「設定 → 通知」で個別に切り替えできます")
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

// MARK: - Routine Prompt

private struct RoutinePromptStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 3)
                .padding(.top, OikomiSpacing.xl)

            Spacer(minLength: OikomiSpacing.xxl)

            OnboardingHeroIcon(
                symbol: "list.bullet.clipboard.fill",
                tint: OikomiColor.brandPrimary,
                background: OikomiColor.brandPrimary.opacity(0.16)
            )

            VStack(spacing: OikomiSpacing.s) {
                Text("ルーティンで素早く")
                    .font(.title.weight(.bold))
                Text("プッシュ・プル・レッグなど、毎回行うメニューをルーティンとして保存しておくと、1 タップでセッションを開始できます。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, OikomiSpacing.xxl)
            }
            .padding(.top, OikomiSpacing.l)

            VStack(alignment: .leading, spacing: OikomiSpacing.m) {
                BulletPoint(text: "種目リストをワンタップで開始")
                BulletPoint(text: "前回の重量・レップを自動表示")
                BulletPoint(text: "ホームと進行中画面に進捗表示")
            }
            .padding(.horizontal, OikomiSpacing.xxxl)
            .padding(.top, OikomiSpacing.xl)

            Spacer()

            VStack(spacing: OikomiSpacing.s) {
                OnboardingPrimaryButton(title: "次へ", action: onContinue)
                Text("ルーティンはトレーニングタブで後から作成できます（Free は 5 個まで）")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.bottom, OikomiSpacing.xxxl)
        }
        .background(OikomiColor.appBackground)
    }
}

// MARK: - Weight Unit

private struct WeightUnitStep: View {
    let onContinue: () -> Void

    @State private var selected: WeightUnit = UnitPreference.current()

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 4)
                .padding(.top, OikomiSpacing.xl)

            Spacer(minLength: OikomiSpacing.xxl)

            OnboardingHeroIcon(
                symbol: "scalemass.fill",
                tint: .blue,
                background: Color.blue.opacity(0.14)
            )

            VStack(spacing: OikomiSpacing.s) {
                Text("重量の単位")
                    .font(.title.weight(.bold))
                Text("kg と lb のどちらで記録しますか？ あとから設定でいつでも変更できます。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, OikomiSpacing.xxl)
            }
            .padding(.top, OikomiSpacing.l)

            VStack(spacing: OikomiSpacing.m) {
                ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                    WeightUnitChoiceCard(
                        unit: unit,
                        isSelected: selected == unit,
                        onTap: { selected = unit }
                    )
                }
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.top, OikomiSpacing.xl)

            Spacer()

            OnboardingPrimaryButton(title: "次へ") {
                UnitPreference.set(selected)
                onContinue()
            }
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.bottom, OikomiSpacing.xxxl)
        }
        .background(OikomiColor.appBackground)
    }
}

private struct WeightUnitChoiceCard: View {
    let unit: WeightUnit
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    Circle()
                        .fill(isSelected ? OikomiColor.brandPrimary.opacity(0.16) : OikomiColor.elevatedBackground)
                    Text(unit.symbol)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(isSelected ? OikomiColor.brandPrimary : .secondary)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.localizedName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(unitDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
            }
            .padding(OikomiSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .fill(OikomiColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? OikomiColor.brandPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var unitDescription: String {
        switch unit {
        case .kg: return "メートル法・日本国内の標準"
        case .lb: return "ヤード・ポンド法・米国式器具に多い"
        }
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

    private var priceLabel: String {
        if let yearly {
            return "\(yearly.displayPrice)/年 ・ いつでも解約可"
        }
        return "¥5,800/年 ・ いつでも解約可"
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepIndicator(current: 5)
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
                Text(priceLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                OnboardingPrimaryButton(
                    title: ctaLabel,
                    isLoading: manager.purchaseInProgress
                ) {
                    Task {
                        guard let yearly else { return }
                        _ = try? await manager.purchase(yearly)
                    }
                }

                Button("今はしない", action: onFinish)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, OikomiSpacing.xs)
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
            showError = error != nil
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

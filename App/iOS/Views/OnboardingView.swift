import AuthenticationServices
import OikomiKit
import SwiftUI

struct OnboardingView: View {

    @Binding var isPresented: Bool

    @State private var step: Step = .welcome
    @State private var healthAuthorizationDone = false

    enum Step: Int {
        case welcome
        case signInWithApple
        case healthKit
        case routinePrompt
    }

    var body: some View {
        VStack {
            switch step {
            case .welcome:
                WelcomeStep(onContinue: { step = .signInWithApple })
            case .signInWithApple:
                SignInWithAppleStep(onAdvance: { step = .healthKit })
            case .healthKit:
                HealthKitStep(
                    isDone: healthAuthorizationDone,
                    onRequest: requestHealth,
                    onContinue: { step = .routinePrompt }
                )
            case .routinePrompt:
                RoutinePromptStep(onFinish: finish)
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

    private func finish() {
        UserDefaults.standard.set(true, forKey: OnboardingState.completedKey)
        isPresented = false
    }
}

enum OnboardingState {
    static let completedKey = "OikomiOnboardingCompleted_v1"
    static var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: OikomiSpacing.xxl) {
            Spacer()

            VStack(spacing: OikomiSpacing.m) {
                ZStack {
                    Circle()
                        .fill(OikomiColor.brandPrimary.opacity(0.18))
                        .frame(width: 120, height: 120)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
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
                    description: "Apple Watch スタンドアロン動作。Digital Crown で 1〜3 タップ記録"
                )
                ValueRow(
                    icon: "brain.head.profile",
                    title: "賢いコーチング",
                    description: "HRV・睡眠・ボリューム推移から自動でアドバイス"
                )
                ValueRow(
                    icon: "character.bubble",
                    title: "日本語ネイティブ",
                    description: "UI・種目名・コーチング文言すべて自然な日本語"
                )
            }
            .padding(.horizontal, OikomiSpacing.xxl)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OikomiSpacing.m + 2)
            }
            .buttonStyle(.borderedProminent)
            .tint(OikomiColor.brandPrimary)
            .padding(.horizontal, OikomiSpacing.xxl)
            .padding(.bottom, OikomiSpacing.xxxl)
        }
        .background(OikomiColor.appBackground)
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

// MARK: - Sign in with Apple

private struct SignInWithAppleStep: View {
    let onAdvance: () -> Void

    @State private var lastError: String?

    var body: some View {
        VStack(spacing: OikomiSpacing.xl) {
            Spacer()

            VStack(spacing: OikomiSpacing.m) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 96, height: 96)
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Text("Apple でサインイン")
                    .font(.title.weight(.bold))
                Text("匿名化された識別子と表示名のみを取得します。メールアドレスは取得しません。サインインしなくても全機能を利用できます。")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, OikomiSpacing.xxl)
            }

            Spacer()

            VStack(spacing: OikomiSpacing.m) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        AppleAuthManager.shared.handle(authorization: authorization)
                        WCSyncBridge.shared.sendAuthStateChange(
                            userID: AppleAuthManager.shared.signedInUserID,
                            displayName: AppleAuthManager.shared.displayName
                        )
                        onAdvance()
                    case .failure(let error):
                        // .canceled はユーザーが閉じただけなのでエラー扱いしない。
                        if (error as? ASAuthorizationError)?.code != .canceled {
                            lastError = error.localizedDescription
                        }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, OikomiSpacing.xxl)

                if let lastError {
                    Text(lastError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, OikomiSpacing.xxl)
                }

                Button {
                    onAdvance()
                } label: {
                    Text("今はスキップ")
                        .foregroundStyle(.secondary)
                }
            }
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
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)

            VStack(spacing: 8) {
                Text("ヘルスケア連携")
                    .font(.title.weight(.bold))
                Text("HealthKit を利用して、ワークアウトを保存し、HRV や睡眠からトレーニング負荷を最適化します。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 12) {
                BulletPoint(text: "ワークアウトをヘルスケアに保存")
                BulletPoint(text: "HRV・睡眠・安静時心拍数を読み取り")
                BulletPoint(text: "すべての計算はオンデバイスで完結")
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                if isDone {
                    Button {
                        onContinue()
                    } label: {
                        Label("次へ", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OikomiColor.brandPrimary)
                } else {
                    Button {
                        onRequest()
                    } label: {
                        Text("HealthKit を許可")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OikomiColor.brandPrimary)

                    Button {
                        onContinue()
                    } label: {
                        Text("後で設定")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
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

// MARK: - Routine Prompt

private struct RoutinePromptStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("ルーティンで素早く")
                    .font(.title.weight(.bold))
                Text("プッシュ・プル・レッグなど、毎回行うメニューをルーティンとして保存しておくと、1 タップでセッション開始できます。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                BulletPoint(text: "種目リストをワンタップで開始")
                BulletPoint(text: "前回の重量・レップを自動表示")
                BulletPoint(text: "ホームと進行中画面に進捗表示")
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onFinish()
                } label: {
                    Text("はじめる")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(OikomiColor.brandPrimary)

                Text("ルーティンはトレーニングタブで後から作成できます")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

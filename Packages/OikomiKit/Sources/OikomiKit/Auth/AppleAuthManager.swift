import AuthenticationServices
import Foundation
import Observation

/// Apple ID Sign-In のセッション管理。
///
/// 任意機能（オプショナル）。CloudKit が iCloud アカウントで自動隔離するため、
/// 認証目的ではなく以下用途に限定する:
/// - 表示名 (display name) のパーソナライゼーション
/// - 将来的なソーシャル機能 (v2.0+) で本人確認
///
/// メールアドレスは取得しない（プライバシー訴求）。Apple は初回サインイン時のみ
/// `fullName` を提供し、以降は nil なので displayName は初回時に保存する。
@Observable
@MainActor
public final class AppleAuthManager {

    public static let shared = AppleAuthManager()

    /// 永続化された Apple ユーザー識別子。匿名化された opaque な文字列。
    public private(set) var signedInUserID: String?

    /// 初回サインイン時に取得した表示名。以降は更新できない (Apple の仕様)。
    public private(set) var displayName: String?

    public var isSignedIn: Bool { signedInUserID != nil }

    public static let userIDKey = "OikomiAppleUserID"
    public static let displayNameKey = "OikomiAppleDisplayName"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.signedInUserID = defaults.string(forKey: Self.userIDKey)
        self.displayName = defaults.string(forKey: Self.displayNameKey)
    }

    /// `SignInWithAppleButton` 完了ハンドラから呼ぶ。
    public func handle(authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        else { return }

        let userID = credential.user
        let formattedName: String? = credential.fullName.flatMap(formatName) ?? displayName

        signedInUserID = userID
        displayName = formattedName

        defaults.set(userID, forKey: Self.userIDKey)
        if let formattedName {
            defaults.set(formattedName, forKey: Self.displayNameKey)
        }
    }

    /// 端末側のセッションをクリア。Apple 側の revoke は iOS Settings からのみ可能。
    public func signOut() {
        signedInUserID = nil
        displayName = nil
        defaults.removeObject(forKey: Self.userIDKey)
        defaults.removeObject(forKey: Self.displayNameKey)
    }

    /// 起動時に credential の状態を Apple に問い合わせる。Revoke 検出時は signOut。
    public func verifyCredentialState() async {
        guard let userID = signedInUserID else { return }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: userID)
            switch state {
            case .authorized:
                break
            case .revoked, .notFound, .transferred:
                signOut()
            @unknown default:
                break
            }
        } catch {
            // 通信エラー等は無視。次回起動で再確認する。
        }
    }

    /// 外部 (WCSession 経由など) からの状態反映用。Watch 側で iPhone 由来の値を保存する経路。
    public func applyRemoteState(userID: String?, displayName: String?) {
        if let userID {
            signedInUserID = userID
            defaults.set(userID, forKey: Self.userIDKey)
            if let displayName {
                self.displayName = displayName
                defaults.set(displayName, forKey: Self.displayNameKey)
            }
        } else {
            signOut()
        }
    }

    private func formatName(_ components: PersonNameComponents) -> String? {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let formatted = formatter.string(from: components)
        return formatted.isEmpty ? nil : formatted
    }
}

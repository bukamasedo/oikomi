import Foundation
import Testing

@testable import OikomiKit

@Suite("AppleAuthManager")
@MainActor
struct AppleAuthManagerTests {

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "OikomiAppleAuthManagerTests_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("init: 未保存なら signedInUserID / displayName が nil")
    func initialState() {
        let defaults = makeIsolatedDefaults()
        let manager = AppleAuthManager(defaults: defaults)
        #expect(manager.signedInUserID == nil)
        #expect(manager.displayName == nil)
        #expect(manager.isSignedIn == false)
    }

    @Test("init: 既存の UserDefaults からロードする")
    func loadsExisting() {
        let defaults = makeIsolatedDefaults()
        defaults.set("apple-user-001", forKey: AppleAuthManager.userIDKey)
        defaults.set("ヒロウチ シュウ", forKey: AppleAuthManager.displayNameKey)

        let manager = AppleAuthManager(defaults: defaults)
        #expect(manager.signedInUserID == "apple-user-001")
        #expect(manager.displayName == "ヒロウチ シュウ")
        #expect(manager.isSignedIn == true)
    }

    @Test("signOut: 状態をクリアし UserDefaults からも削除")
    func signOutClears() {
        let defaults = makeIsolatedDefaults()
        defaults.set("apple-user-002", forKey: AppleAuthManager.userIDKey)
        defaults.set("テスト ユーザー", forKey: AppleAuthManager.displayNameKey)

        let manager = AppleAuthManager(defaults: defaults)
        manager.signOut()

        #expect(manager.signedInUserID == nil)
        #expect(manager.displayName == nil)
        #expect(defaults.string(forKey: AppleAuthManager.userIDKey) == nil)
        #expect(defaults.string(forKey: AppleAuthManager.displayNameKey) == nil)
    }

    @Test("applyRemoteState: userID + displayName を反映")
    func applyRemoteState() {
        let defaults = makeIsolatedDefaults()
        let manager = AppleAuthManager(defaults: defaults)

        manager.applyRemoteState(userID: "remote-001", displayName: "リモート ユーザー")

        #expect(manager.signedInUserID == "remote-001")
        #expect(manager.displayName == "リモート ユーザー")
        #expect(defaults.string(forKey: AppleAuthManager.userIDKey) == "remote-001")
        #expect(defaults.string(forKey: AppleAuthManager.displayNameKey) == "リモート ユーザー")
    }

    @Test("applyRemoteState: userID が nil なら signOut 扱い")
    func applyRemoteStateSignsOut() {
        let defaults = makeIsolatedDefaults()
        defaults.set("apple-user-003", forKey: AppleAuthManager.userIDKey)
        let manager = AppleAuthManager(defaults: defaults)

        manager.applyRemoteState(userID: nil, displayName: nil)

        #expect(manager.signedInUserID == nil)
        #expect(manager.isSignedIn == false)
    }
}

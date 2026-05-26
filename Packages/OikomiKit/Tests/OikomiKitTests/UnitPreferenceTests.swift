import Foundation
import Testing

@testable import OikomiKit

@Suite("UnitPreference")
struct UnitPreferenceTests {

    /// テスト用に分離した in-memory UserDefaults を生成する。
    private func ephemeralDefaults() -> UserDefaults {
        let suiteName = "unit-preference-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("未設定時は kg がデフォルト")
    func defaultIsKg() {
        let defaults = ephemeralDefaults()
        #expect(UnitPreference.current(defaults: defaults) == .kg)
    }

    @Test("set → current の往復で値が保存される")
    func roundtrip() {
        let defaults = ephemeralDefaults()
        UnitPreference.set(.lb, defaults: defaults)
        #expect(UnitPreference.current(defaults: defaults) == .lb)
        UnitPreference.set(.kg, defaults: defaults)
        #expect(UnitPreference.current(defaults: defaults) == .kg)
    }

    @Test("不正な rawValue が入っていてもデフォルトにフォールバック")
    func invalidRawValueFallback() {
        let defaults = ephemeralDefaults()
        defaults.set("invalid", forKey: UnitPreference.storageKey)
        #expect(UnitPreference.current(defaults: defaults) == .kg)
    }
}

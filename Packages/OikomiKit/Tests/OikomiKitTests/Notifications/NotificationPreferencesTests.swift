import Foundation
import Testing

@testable import OikomiKit

@Suite("NotificationPreferences")
struct NotificationPreferencesTests {

    private static func makeIsolatedDefaults() -> UserDefaults {
        let suite = "OikomiNotifTest_\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test("デフォルトでは全種別 ON")
    func defaultsAllEnabled() {
        let defaults = Self.makeIsolatedDefaults()
        for kind in NotificationKind.allCases {
            #expect(NotificationPreferences.isEnabled(kind, in: defaults) == true)
        }
    }

    @Test("明示的に false を書くと OFF として読み取れる")
    func writingFalseTurnsOff() {
        let defaults = Self.makeIsolatedDefaults()
        defaults.set(false, forKey: NotificationKind.prPrediction.storageKey)
        #expect(NotificationPreferences.isEnabled(.prPrediction, in: defaults) == false)
        // 他種別はデフォルトのまま ON
        #expect(NotificationPreferences.isEnabled(.weekly, in: defaults) == true)
    }

    @Test("時刻プリセットのデフォルトは朝 7:00")
    func defaultTimePresetIsMorning() {
        let defaults = Self.makeIsolatedDefaults()
        #expect(NotificationPreferences.timePreset(in: defaults) == .morning)
        #expect(NotificationPreferences.timePreset(in: defaults).hour == 7)
    }

    @Test("時刻プリセットを書き換えると読み出せる")
    func timePresetIsWriteable() {
        let defaults = Self.makeIsolatedDefaults()
        defaults.set(NotificationTimePreset.evening.rawValue, forKey: NotificationPreferences.timePresetKey)
        #expect(NotificationPreferences.timePreset(in: defaults) == .evening)
        #expect(NotificationPreferences.timePreset(in: defaults).hour == 19)
    }

    @Test("不正な rawValue は朝にフォールバック")
    func invalidPresetFallsBackToMorning() {
        let defaults = Self.makeIsolatedDefaults()
        defaults.set(999, forKey: NotificationPreferences.timePresetKey)
        #expect(NotificationPreferences.timePreset(in: defaults) == .morning)
    }
}

import Foundation
import Testing

@testable import OikomiKit

@Suite("TrainingProfile")
struct TrainingProfileTests {

    @Test("ExperienceLevel/TrainingGoal: allCases と displayName")
    func enumBasics() {
        #expect(ExperienceLevel.allCases.count == 3)
        #expect(TrainingGoal.allCases.count == 3)
        #expect(ExperienceLevel.beginner.displayName == "初心者")
        #expect(ExperienceLevel.intermediate.displayName == "中級者")
        #expect(ExperienceLevel.advanced.displayName == "上級者")
        #expect(TrainingGoal.hypertrophy.displayName == "筋肥大")
        #expect(TrainingGoal.strength.displayName == "筋力")
        #expect(TrainingGoal.maintenance.displayName == "維持")
    }

    @Test("TrainingProfile.default は中級者・筋肥大")
    func defaultProfile() {
        #expect(TrainingProfile.default.experience == .intermediate)
        #expect(TrainingProfile.default.goal == .hypertrophy)
    }

    @Test("TrainingProfilePreference: UserDefaults 往復と未設定フォールバック")
    func preferenceRoundTrip() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        // 未設定 → default
        #expect(TrainingProfilePreference.current(defaults: suite) == .default)
        // 書く → 読む
        suite.set(ExperienceLevel.advanced.rawValue, forKey: TrainingProfilePreference.experienceKey)
        suite.set(TrainingGoal.strength.rawValue, forKey: TrainingProfilePreference.goalKey)
        let profile = TrainingProfilePreference.current(defaults: suite)
        #expect(profile.experience == .advanced)
        #expect(profile.goal == .strength)
    }

    @Test("TrainingProfilePreference: 不正な rawValue は default にフォールバック")
    func preferenceInvalidFallback() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        suite.set("not-a-level", forKey: TrainingProfilePreference.experienceKey)
        suite.set("not-a-goal", forKey: TrainingProfilePreference.goalKey)
        #expect(TrainingProfilePreference.current(defaults: suite) == .default)
    }
}

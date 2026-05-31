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
}

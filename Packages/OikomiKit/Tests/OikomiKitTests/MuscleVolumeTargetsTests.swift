import Foundation
import Testing

@testable import OikomiKit

@Suite("MuscleVolumeTargets")
struct MuscleVolumeTargetsTests {

    @Test("全 case で mev <= mav")
    func mevDoesNotExceedMav() {
        for muscle in MuscleGroup.allCases {
            let target = muscle.weeklySetTarget
            #expect(target.mev <= target.mav, "\(muscle): mev=\(target.mev) mav=\(target.mav)")
        }
    }

    @Test("fullBody は (0, 0) で isTracked=false")
    func fullBodyIsUntracked() {
        let target = MuscleGroup.fullBody.weeklySetTarget
        #expect(target.mev == 0)
        #expect(target.mav == 0)
        #expect(target.isTracked == false)
    }

    @Test("主要部位（chest/back/quads など）は MAV > 0")
    func majorMusclesAreTracked() {
        let majors: [MuscleGroup] = [.chest, .back, .shoulders, .biceps, .triceps, .quads, .hamstrings, .glutes]
        for muscle in majors {
            #expect(muscle.weeklySetTarget.isTracked, "\(muscle) should be tracked")
        }
    }
}

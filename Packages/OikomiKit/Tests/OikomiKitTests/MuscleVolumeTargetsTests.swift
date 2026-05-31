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

    @Test("weeklySetTarget(for:.default) はベースラインに一致")
    func defaultMatchesBaseline() {
        for muscle in MuscleGroup.allCases {
            #expect(muscle.weeklySetTarget(for: .default) == muscle.weeklySetTarget)
        }
    }

    @Test("経験レベルで MAV が単調増加（初心者<=中級<=上級）")
    func experienceMonotonic() {
        for muscle in MuscleGroup.allCases where muscle.weeklySetTarget.isTracked {
            let beg = muscle.weeklySetTarget(for: TrainingProfile(experience: .beginner, goal: .hypertrophy)).mav
            let mid = muscle.weeklySetTarget(for: TrainingProfile(experience: .intermediate, goal: .hypertrophy)).mav
            let adv = muscle.weeklySetTarget(for: TrainingProfile(experience: .advanced, goal: .hypertrophy)).mav
            #expect(beg <= mid)
            #expect(mid <= adv)
        }
    }

    @Test("目標: 筋力は筋肥大より MAV が小さい")
    func goalReducesVolume() {
        for muscle in MuscleGroup.allCases where muscle.weeklySetTarget.isTracked {
            let hyp = muscle.weeklySetTarget(for: TrainingProfile(experience: .intermediate, goal: .hypertrophy)).mav
            let str = muscle.weeklySetTarget(for: TrainingProfile(experience: .intermediate, goal: .strength)).mav
            #expect(str <= hyp)
        }
    }

    @Test("個人化しても mev<=mav・fullBody は (0,0)")
    func personalizedInvariants() {
        let profiles = [
            TrainingProfile(experience: .beginner, goal: .strength),
            TrainingProfile(experience: .advanced, goal: .maintenance),
            TrainingProfile(experience: .beginner, goal: .maintenance),
        ]
        for profile in profiles {
            for muscle in MuscleGroup.allCases {
                let t = muscle.weeklySetTarget(for: profile)
                #expect(t.mev <= t.mav)
            }
            let fb = MuscleGroup.fullBody.weeklySetTarget(for: profile)
            #expect(fb.mev == 0 && fb.mav == 0)
        }
    }
}

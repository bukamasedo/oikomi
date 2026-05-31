import Foundation
import Testing

@testable import OikomiKit

@Suite("MonthlySummaryPrompt")
struct MonthlySummaryPromptTests {

    private func digest() -> MonthlyTrainingDigest {
        MonthlyTrainingDigest(
            yearMonth: "2026-05",
            sessionCount: 12,
            trainingDays: 12,
            totalVolumeKg: 48000,
            muscleSetCounts: [MonthlyMuscleVolume(muscle: .chest, sets: 40)],
            underTrainedMuscles: [.hamstrings],
            personalRecords: [MonthlyPR(exerciseName: "ベンチプレス", weight: 100, reps: 3, estimated1RM: 110)],
            readiness: MonthlyReadiness(average: 62, lowDays: 2, normalDays: 8, highDays: 5),
            bodyPhase: BodyPhaseResult(phase: .cut, kgPerMonth: -1.5)
        )
    }

    @Test("prompt に主要事実が含まれる")
    func promptContainsFacts() {
        let payload = MonthlySummaryPrompt.make(from: digest())
        #expect(payload.prompt.contains("2026-05"))
        #expect(payload.prompt.contains("ベンチプレス"))
        #expect(payload.prompt.contains("12"))  // セッション/トレ日数
        #expect(payload.prompt.contains("ハムストリング"))  // underTrained 部位の displayName
        #expect(payload.prompt.contains("減量期"))  // bodyPhase displayName
    }

    @Test("instructions に制約文言が含まれる")
    func instructionsHaveGuardrails() {
        let payload = MonthlySummaryPrompt.make(from: digest())
        #expect(payload.instructions.contains("日本語"))
        #expect(!payload.instructions.isEmpty)
    }
}

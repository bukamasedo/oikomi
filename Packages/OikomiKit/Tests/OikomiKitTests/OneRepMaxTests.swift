import Testing

@testable import OikomiKit

@Suite("OneRepMax")
struct OneRepMaxTests {

    @Test("Epley: 単一レップは重量そのまま")
    func epleySingleRep() {
        let result = OneRepMax.epley(weight: 100, reps: 1)
        #expect(result == 100)
    }

    @Test("Epley: 80kg × 8レップは約 101.3kg")
    func epleyEightReps() {
        let result = OneRepMax.epley(weight: 80, reps: 8)
        #expect(abs(result - 101.333) < 0.01)
    }

    @Test("Epley: 不正入力は 0 を返す")
    func epleyInvalidInput() {
        #expect(OneRepMax.epley(weight: 0, reps: 5) == 0)
        #expect(OneRepMax.epley(weight: 100, reps: 0) == 0)
        #expect(OneRepMax.epley(weight: -50, reps: 5) == 0)
    }

    @Test("Brzycki: 100kg × 5レップは約 112.5kg")
    func brzyckiFiveReps() {
        let result = OneRepMax.brzycki(weight: 100, reps: 5)
        #expect(abs(result - 112.5) < 0.01)
    }

    @Test("best: 最大の推定値を返す")
    func bestPicksMax() {
        let sets: [(weight: Double, reps: Int)] = [
            (80, 8),  // ≈ 101.3
            (90, 5),  // ≈ 105.0
            (100, 3),  // ≈ 110.0
        ]
        let best = OneRepMax.best(from: sets)
        #expect(abs(best - 110.0) < 0.01)
    }

    @Test("relativeIntensity: 80kg / 100kg 1RM = 0.8")
    func relativeIntensity() {
        let intensity = OneRepMax.relativeIntensity(weight: 80, estimated1RM: 100)
        #expect(abs(intensity - 0.8) < 0.001)
    }

    @Test("estimate: rpe=nil・8レップは Brzycki を使う（6 以上）")
    func estimateMidRepUsesBrzycki() {
        // Brzycki(80,8) = 80*36/(37-8) = 99.310...
        let result = OneRepMax.estimate(weight: 80, reps: 8, rpe: nil)
        #expect(abs(result - 99.310) < 0.01)
    }

    @Test("estimate: rpe=nil・3レップは Epley を使う（1〜5 域）")
    func estimateLowRepUsesEpley() {
        // Epley(100,3) = 100*(1+3/30) = 110
        let result = OneRepMax.estimate(weight: 100, reps: 3, rpe: nil)
        #expect(abs(result - 110.0) < 0.01)
    }

    @Test("estimate: RPE8(RIR2) は実効レップ +2 で推定する")
    func estimateRIRAdjustment() {
        // (100kg, 5reps, RPE8) → effectiveReps 7 → Brzycki(100,7) = 100*36/30 = 120
        let result = OneRepMax.estimate(weight: 100, reps: 5, rpe: 8)
        #expect(abs(result - 120.0) < 0.01)
    }

    @Test("estimate: 不正入力は 0")
    func estimateInvalid() {
        #expect(OneRepMax.estimate(weight: 0, reps: 5, rpe: nil) == 0)
        #expect(OneRepMax.estimate(weight: 100, reps: 0, rpe: nil) == 0)
    }

    @Test("estimate: 範囲外の低 RPE はクランプされ 1 扱いになる")
    func estimateClampsLowRPE() {
        // rpe < 1 は 1 にクランプ → rpe=1 と同じ結果（過大推定を防ぐ）
        #expect(
            OneRepMax.estimate(weight: 100, reps: 5, rpe: 0)
                == OneRepMax.estimate(weight: 100, reps: 5, rpe: 1))
        #expect(
            OneRepMax.estimate(weight: 100, reps: 5, rpe: -5)
                == OneRepMax.estimate(weight: 100, reps: 5, rpe: 1))
    }

    @Test("workingWeight: 単一レップは 1RM そのまま")
    func workingWeightSingleRep() {
        #expect(OneRepMax.workingWeight(forOneRM: 100, reps: 1) == 100)
    }

    @Test("workingWeight: 低レップ(≤5)は Epley の逆算で往復一致")
    func workingWeightRoundTripEpley() {
        // Epley(90, 3) を逆算 → 90 に戻る
        let oneRM = OneRepMax.epley(weight: 90, reps: 3)
        let back = OneRepMax.workingWeight(forOneRM: oneRM, reps: 3)
        #expect(abs(back - 90) < 0.001)
    }

    @Test("workingWeight: 中レップ(≥6)は Brzycki の逆算で往復一致")
    func workingWeightRoundTripBrzycki() {
        // Brzycki(80, 8) を逆算 → 80 に戻る
        let oneRM = OneRepMax.brzycki(weight: 80, reps: 8)
        let back = OneRepMax.workingWeight(forOneRM: oneRM, reps: 8)
        #expect(abs(back - 80) < 0.001)
    }

    @Test("workingWeight: 不正入力は 0")
    func workingWeightInvalid() {
        #expect(OneRepMax.workingWeight(forOneRM: 0, reps: 5) == 0)
        #expect(OneRepMax.workingWeight(forOneRM: 100, reps: 0) == 0)
        #expect(OneRepMax.workingWeight(forOneRM: 100, reps: 37) == 0)
    }
}

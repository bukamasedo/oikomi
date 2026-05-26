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
}

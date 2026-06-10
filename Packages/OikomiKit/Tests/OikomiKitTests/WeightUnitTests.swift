import Testing

@testable import OikomiKit

@Suite("WeightUnit")
struct WeightUnitTests {

    @Test("kg.toKilograms は恒等変換")
    func kgIdentity() {
        #expect(WeightUnit.kg.toKilograms(50) == 50)
        #expect(WeightUnit.kg.fromKilograms(50) == 50)
    }

    @Test("lb → kg 変換: 220.462 lb ≈ 100 kg")
    func lbToKg() {
        let kg = WeightUnit.lb.toKilograms(220.4622)
        #expect(abs(kg - 100.0) < 1e-3)
    }

    @Test("kg → lb 変換: 100 kg ≈ 220.462 lb")
    func kgToLb() {
        let lb = WeightUnit.lb.fromKilograms(100)
        #expect(abs(lb - 220.4622) < 1e-3)
    }

    @Test("往復変換で誤差が極小")
    func roundtrip() {
        for kg in stride(from: 0.5, through: 250.0, by: 7.5) {
            let lb = WeightUnit.lb.fromKilograms(kg)
            let back = WeightUnit.lb.toKilograms(lb)
            #expect(abs(back - kg) < 1e-9)
        }
    }

    @Test("displayStep は kg=0.5, lb=5.0")
    func displaySteps() {
        #expect(WeightUnit.kg.displayStep == 0.5)
        #expect(WeightUnit.lb.displayStep == 5.0)
    }

    @Test("symbol と localizedName")
    func labels() {
        #expect(WeightUnit.kg.symbol == "kg")
        #expect(WeightUnit.lb.symbol == "lb")
        #expect(WeightUnit.kg.localizedName == "キログラム")
        #expect(WeightUnit.lb.localizedName == "ポンド")
    }

    @Test("defaultRange は単位ごとに kg 500 と等価な上限")
    func ranges() {
        #expect(WeightUnit.kg.defaultRange == 0...500)
        #expect(WeightUnit.lb.defaultRange == 0...1100)
    }

    @Test("snappedKilograms: kg は 0.5kg 刻みに丸める")
    func snapKg() {
        #expect(WeightUnit.kg.snappedKilograms(78.9) == 79.0)
        #expect(WeightUnit.kg.snappedKilograms(81.2) == 81.0)
        #expect(WeightUnit.kg.snappedKilograms(82.5) == 82.5)
    }

    @Test("snappedKilograms: lb は 5lb 刻みに丸めた値を kg で返す")
    func snapLb() {
        // 100kg ≈ 220.46lb → 最寄りの 5lb = 220lb → kg に戻すと ≈ 99.79kg
        let snapped = WeightUnit.lb.snappedKilograms(100.0)
        let lb = WeightUnit.lb.fromKilograms(snapped)
        #expect(abs(lb - 220.0) < 1e-6)
    }
}

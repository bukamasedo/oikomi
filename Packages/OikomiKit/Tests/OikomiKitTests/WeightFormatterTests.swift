import Foundation
import Testing

@testable import OikomiKit

@Suite("WeightFormatter")
struct WeightFormatterTests {

    @Test("kg 100 は記号付きで '100 kg'（小数 0〜1 桁）")
    func kgInteger() {
        #expect(WeightFormatter.string(kilograms: 100, in: .kg) == "100 kg")
    }

    @Test("kg 102.5 は小数 1 桁を保持")
    func kgFractional() {
        #expect(WeightFormatter.string(kilograms: 102.5, in: .kg) == "102.5 kg")
    }

    @Test("kg 100 を lb 表示すると約 220.5")
    func lbConversion() {
        let s = WeightFormatter.string(kilograms: 100, in: .lb)
        #expect(s == "220.5 lb")
    }

    @Test("oneRM は常に小数 1 桁")
    func oneRMFormat() {
        #expect(WeightFormatter.oneRM(kilograms: 100, in: .kg) == "100.0 kg")
        #expect(WeightFormatter.oneRM(kilograms: 112.55, in: .kg) == "112.6 kg")
    }

    @Test("volume は整数に丸める")
    func volumeRounding() {
        let s = WeightFormatter.volume(kilograms: 5240.7, in: .kg)
        #expect(s.hasSuffix(" kg"))
        // ロケール依存で区切り文字が変わりうるため、5241 を含むこと（と末尾 kg）のみ検証
        #expect(s.contains("5,241") || s.contains("5241"))
    }

    @Test("numberOnly は記号を含まない")
    func numberOnlyNoSymbol() {
        let s = WeightFormatter.numberOnly(kilograms: 100, in: .kg)
        #expect(!s.contains("kg"))
        #expect(s == "100")
    }
}

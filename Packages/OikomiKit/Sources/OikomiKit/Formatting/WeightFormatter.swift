import Foundation

/// 重量表示の共通フォーマッタ。内部値（kg）を指定単位の文字列に整形する。
/// iOS / Watch / Widget / Live Activity から同一実装を再利用するため OikomiKit に集約。
public enum WeightFormatter {

    /// 単位記号付きの整形済み文字列。例: "100 kg", "220.5 lb"
    public static func string(
        kilograms: Double,
        in unit: WeightUnit,
        fractionDigits: ClosedRange<Int> = 0...1
    ) -> String {
        "\(numberOnly(kilograms: kilograms, in: unit, fractionDigits: fractionDigits)) \(unit.symbol)"
    }

    /// 数値のみ。単位記号を別の Text View で出したい場合用。
    public static func numberOnly(
        kilograms: Double,
        in unit: WeightUnit,
        fractionDigits: ClosedRange<Int> = 0...1
    ) -> String {
        let converted = unit.fromKilograms(kilograms)
        return converted.formatted(.number.precision(.fractionLength(fractionDigits)))
    }

    /// 推定 1RM 表示専用（小数 1 桁固定）。例: "112.5 kg"
    public static func oneRM(kilograms: Double, in unit: WeightUnit) -> String {
        string(kilograms: kilograms, in: unit, fractionDigits: 1...1)
    }

    /// ボリューム表示専用（整数 + 桁区切り）。例: "5,240 kg"
    public static func volume(kilograms: Double, in unit: WeightUnit) -> String {
        let converted = unit.fromKilograms(kilograms)
        let formatted = converted.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
        return "\(formatted) \(unit.symbol)"
    }
}

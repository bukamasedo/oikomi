import Foundation

/// 表示・入力時の重量単位。内部 SwiftData モデル `SetRecord.weight` は常に kg 固定。
/// ユーザー設定（`UnitPreference`）で kg / lb を切り替える。
public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kg
    case lb

    public static let kilogramsToPounds: Double = 2.2046226218

    public func toKilograms(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lb: return value / Self.kilogramsToPounds
        }
    }

    public func fromKilograms(_ kilograms: Double) -> Double {
        switch self {
        case .kg: return kilograms
        case .lb: return kilograms * Self.kilogramsToPounds
        }
    }

    /// 入力ステッパーの最小増減単位。
    /// kg はダンベルの微調整（マイクロロード）に合わせて 0.5kg 刻み、
    /// lb = 2.5lb プレート両側分（米国式）。
    public var displayStep: Double {
        switch self {
        case .kg: return 0.5
        case .lb: return 5.0
        }
    }

    /// 任意の kg 値を、表示単位のステッパー刻み（`displayStep`）の整数倍に丸めて kg で返す。
    /// `NumericStepperField` の丸め（表示単位で step の整数倍）と整合させ、半端な推奨値が出ないようにする。
    public func snappedKilograms(_ kilograms: Double) -> Double {
        let display = fromKilograms(kilograms)
        let snapped = (display / displayStep).rounded() * displayStep
        return toKilograms(snapped)
    }

    public var symbol: String {
        switch self {
        case .kg: return "kg"
        case .lb: return "lb"
        }
    }

    public var localizedName: String {
        switch self {
        case .kg: return loc("キログラム")
        case .lb: return loc("ポンド")
        }
    }

    /// 入力フィールドのデフォルト上限。kg の 500 と等価な lbs 上限。
    public var defaultRange: ClosedRange<Double> {
        switch self {
        case .kg: return 0...500
        case .lb: return 0...1100
        }
    }

    /// 新規入力時のデフォルト値（kg 内部表現）。
    /// kg = 20kg（オリンピックバー）、lb = 45lb（米国式バー、20.41kg 相当）。
    /// 各単位のグリッドに乗る値を選び、初期表示で `44.1` のような半端な値が出ないようにする。
    public var defaultInitialKilograms: Double {
        switch self {
        case .kg: return 20.0
        case .lb: return 45.0 / Self.kilogramsToPounds  // ≈ 20.4117 kg = 45.0 lb
        }
    }
}

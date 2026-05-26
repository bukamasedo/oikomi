import Foundation

/// 重量単位のユーザー設定を App Group 共有 UserDefaults から読み書きする。
/// iOS 本体 / Apple Watch / Widget / Live Activity すべてが同じ値を参照する必要があるため、
/// `.standard` ではなく App Group suite (`SharedModelContainer.appGroupID`) を使う。
public enum UnitPreference {

    public static let storageKey = "OikomiWeightUnit"
    public static let defaultUnit: WeightUnit = .kg

    public static func current(defaults: UserDefaults = .sharedAppGroup) -> WeightUnit {
        guard let raw = defaults.string(forKey: storageKey),
            let unit = WeightUnit(rawValue: raw)
        else {
            return defaultUnit
        }
        return unit
    }

    public static func set(_ unit: WeightUnit, defaults: UserDefaults = .sharedAppGroup) {
        defaults.set(unit.rawValue, forKey: storageKey)
    }
}

extension UserDefaults {
    /// App Group 共有の UserDefaults。Watch / Widget からも同じインスタンスを参照する。
    /// entitlements 未付与環境（テスト等）では `.standard` にフォールバック。
    public static var sharedAppGroup: UserDefaults {
        UserDefaults(suiteName: "group.com.shuhirouchi.oikomi") ?? .standard
    }
}

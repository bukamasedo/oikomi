import Foundation

/// 週次トレーニング目標日数の共有定数。
///
/// 筋トレは休養日込みのサイクルなので「連続日数」ではなく週ベースで目標を持つ。
/// 設定タブのユーザー指定値を UserDefaults 経由でアプリ・ウィジェット間で共有する。
public enum WeeklyTrainingTarget {

    /// UserDefaults キー。`@AppStorage` でも `UserDefaults.standard.integer(forKey:)` でも使う。
    public static let storageKey = "OikomiWeeklyTargetDays"

    /// デフォルト目標日数。ハイパートロフィー文献では週 3〜5 日が一般的。中央値の 4 を採用。
    public static let defaultDays = 4

    /// 許容範囲。1 日は休養込みの最低限、7 は連日。両端も尊重する。
    public static let allowedRange: ClosedRange<Int> = 1...7

    /// 現在の設定値を返す。未設定（0）ならデフォルトに丸める。
    public static func currentTarget(defaults: UserDefaults = .standard) -> Int {
        let stored = defaults.integer(forKey: storageKey)
        guard allowedRange.contains(stored) else { return defaultDays }
        return stored
    }
}

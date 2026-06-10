import Foundation

/// 通知の種類。設定タブで個別 ON/OFF を切り替えるトグルと対応する。
public enum NotificationKind: String, CaseIterable, Sendable {
    case rest
    case weekly
    case prPrediction
    case hrvDeload
    case forgottenSession
    case trial

    /// 設定タブで表示するラベル。
    public var displayName: String {
        switch self {
        case .rest: return loc("レストタイマー終了")
        case .weekly: return loc("週次サマリ")
        case .prPrediction: return loc("PR 予測")
        case .hrvDeload: return loc("HRV 連動ディロード推奨")
        case .forgottenSession: return loc("ワークアウト終了忘れ")
        case .trial: return loc("トライアル残日数")
        }
    }

    /// 設定タブで表示する補足説明。
    public var description: String {
        switch self {
        case .rest: return loc("セット間レストが終わったら知らせます。")
        case .weekly: return loc("日曜の指定時刻に今週の総ボリュームを送ります。")
        case .prPrediction: return loc("翌日のルーティンで PR 圏内の種目があると朝に通知します。")
        case .hrvDeload: return loc("HRV 低下を検知したら強度を落とすよう促します。")
        case .forgottenSession: return loc("セッションが 90 分以上アイドルだとリマインドします。")
        case .trial: return loc("トライアル終了 3 日前と当日に確認を送ります。")
        }
    }

    /// `@AppStorage` で使う UserDefaults キー。
    public var storageKey: String {
        switch self {
        case .rest: return "OikomiNotif_Rest"
        case .weekly: return "OikomiNotif_Weekly"
        case .prPrediction: return "OikomiNotif_PRPrediction"
        case .hrvDeload: return "OikomiNotif_HRVDeload"
        case .forgottenSession: return "OikomiNotif_ForgottenSession"
        case .trial: return "OikomiNotif_Trial"
        }
    }
}

/// 朝 / 昼 / 夜のプリセット時刻。AI コーチング通知と週次サマリ通知の発火時刻に使う。
public enum NotificationTimePreset: Int, CaseIterable, Sendable, Identifiable {
    case morning = 7
    case noon = 12
    case evening = 19

    public var id: Int { rawValue }

    /// 発火時刻 (24h)。
    public var hour: Int { rawValue }

    public var displayName: String {
        switch self {
        case .morning: return loc("朝 (7:00)")
        case .noon: return loc("昼 (12:00)")
        case .evening: return loc("夜 (19:00)")
        }
    }
}

/// 通知設定の集約。デフォルト値は全 ON / 朝 7 時。
///
/// UserDefaults を直接読むため iOS / watchOS / Widget 等どのターゲットからも参照可能。
/// SwiftUI 側は `@AppStorage(NotificationKind.<kind>.storageKey)` でバインドする。
public enum NotificationPreferences {
    public static let timePresetKey = "OikomiNotif_TimePreset"

    /// 指定種別の通知が ON かどうか。未設定（初回起動）はデフォルト ON。
    public static func isEnabled(_ kind: NotificationKind, in defaults: UserDefaults = .standard) -> Bool {
        if defaults.object(forKey: kind.storageKey) == nil { return true }
        return defaults.bool(forKey: kind.storageKey)
    }

    /// 通知時刻プリセット。未設定なら朝 7 時。
    public static func timePreset(in defaults: UserDefaults = .standard) -> NotificationTimePreset {
        let raw = defaults.object(forKey: timePresetKey) as? Int ?? NotificationTimePreset.morning.rawValue
        return NotificationTimePreset(rawValue: raw) ?? .morning
    }

    /// テストや設定リセット用。プロダクションコードからの呼び出しは想定しない。
    public static func reset(in defaults: UserDefaults = .standard) {
        for kind in NotificationKind.allCases {
            defaults.removeObject(forKey: kind.storageKey)
        }
        defaults.removeObject(forKey: timePresetKey)
    }
}

import Foundation

/// Pro 機能ゲートの判定ヘルパー。`SubscriptionManager.isProActive` の薄いラッパー。
///
/// 各機能フラグの真偽値は SubscriptionManager から導出するため、テストでは
/// `SubscriptionManager.shared` の状態を差し替えて検証する。
@MainActor
public enum ProGate {

    // MARK: - Free 上限

    /// Free プランで作成できるルーティンの最大数（仕様書 §10）
    public static let freeRoutineLimit = 3

    /// Free プランで作成できるカスタム種目の最大数（仕様書 §10）
    public static let freeCustomExerciseLimit = 5

    // MARK: - Subscription 参照

    /// 真実のソース。SubscriptionManager から導出。
    public static var isProActive: Bool {
        SubscriptionManager.shared.isProActive
    }

    // MARK: - 機能フラグ

    /// ルーティンを 3 個以上作れるか
    public static var canCreateUnlimitedRoutines: Bool { isProActive }

    /// カスタム種目を 5 個以上作れるか
    public static var canCreateUnlimitedCustomExercises: Bool { isProActive }

    /// HealthKit から HRV・睡眠・安静時心拍数を読み取れるか
    public static var canReadHealthData: Bool { isProActive }

    /// AI コーチング 3 種（ディロード / PR 予測 / ボリューム警告）が利用できるか
    public static var canUseAICoaching: Bool { isProActive }

    /// Live Activity / Dynamic Island を起動できるか
    public static var canUseLiveActivity: Bool { isProActive }

    /// iCloud / CloudKit 同期を有効にできるか
    public static var canUseICloudSync: Bool { isProActive }

    /// 高度な分析グラフ（週次ボリューム / 種目別推移 / PR リスト）を見られるか
    public static var canSeeAdvancedAnalytics: Bool { isProActive }

    /// データエクスポート（CSV / JSON）を実行できるか
    public static var canExportData: Bool { isProActive }
}

/// 機能ゲートに引っかかったときに投げるエラー。UI 側で localizedDescription を表示し、
/// ProUpgradeSheet を開く導線を提供する想定。
public enum ProGateError: LocalizedError, Equatable {
    case routineLimitReached(current: Int, limit: Int)
    case customExerciseLimitReached(current: Int, limit: Int)
    case healthDataReadRequiresPro
    case aiCoachingRequiresPro
    case liveActivityRequiresPro
    case iCloudSyncRequiresPro
    case advancedAnalyticsRequiresPro
    case dataExportRequiresPro

    public var errorDescription: String? {
        switch self {
        case .routineLimitReached(_, let limit):
            return "Free プランで作成できるルーティンは \(limit) 個までです。Pro にアップグレードすると無制限になります。"
        case .customExerciseLimitReached(_, let limit):
            return "Free プランで作成できるカスタム種目は \(limit) 個までです。Pro にアップグレードすると無制限になります。"
        case .healthDataReadRequiresPro:
            return "HRV・睡眠データの読み取りは Pro 限定機能です。"
        case .aiCoachingRequiresPro:
            return "AI コーチングは Pro 限定機能です。"
        case .liveActivityRequiresPro:
            return "Live Activity は Pro 限定機能です。"
        case .iCloudSyncRequiresPro:
            return "iCloud 同期は Pro 限定機能です。"
        case .advancedAnalyticsRequiresPro:
            return "高度な分析は Pro 限定機能です。"
        case .dataExportRequiresPro:
            return "データエクスポートは Pro 限定機能です。"
        }
    }
}

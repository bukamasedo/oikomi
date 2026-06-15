import Foundation

/// Pro 機能ゲートの判定ヘルパー。`SubscriptionManager.isProActive` の薄いラッパー。
///
/// 各機能フラグの真偽値は SubscriptionManager から導出するため、テストでは
/// `SubscriptionManager.shared` の状態を差し替えて検証する。
@MainActor
public enum ProGate {

    // MARK: - Free 上限

    /// Free プランで作成できるルーティンの最大数（仕様書 §10）
    ///
    /// 4〜6 分割法を使うトレーニーが Free でも回せるよう、v0.x で 3→5 に緩和。
    public static let freeRoutineLimit = 5

    /// Free プランで作成できるカスタム種目の最大数（仕様書 §10）
    public static let freeCustomExerciseLimit = 5

    // MARK: - Subscription 参照

    /// 真実のソース。SubscriptionManager から導出。
    public static var isProActive: Bool {
        SubscriptionManager.shared.isProActive
    }

    // MARK: - 機能フラグ
    //
    // 課金境界は split 型「楔は無料・深さは有料」（SPEC §10「課金境界の原則」, 2026-06-15）。
    // Free = 今日のレディネス/ディロード推奨（楔の1シグナル）＋それに必要な HealthKit 読み取り。
    // Pro  = 深さ（長期トレンド・高度分析・高度コーチング）・同期・無制限・エクスポート。

    /// ルーティンを 5 個以上作れるか
    public static var canCreateUnlimitedRoutines: Bool { isProActive }

    /// カスタム種目を 5 個以上作れるか
    public static var canCreateUnlimitedCustomExercises: Bool { isProActive }

    /// HealthKit から HRV・睡眠・安静時心拍数を読み取れるか。
    ///
    /// v0.x split（SPEC §10）で **Free 開放**。「今日のレディネス＝楔」を全ユーザーに体感させるには
    /// 読み取り自体が必須なため（レディネス算出は内部で 60 日 HRV/RHR 系列を使う）。Pro 境界は
    /// 深さ側（`canSeeHealthTrends` / `canSeeAdvancedAnalytics` / `canUseAdvancedCoaching`）へ移した。
    /// 将来再ゲートする場合は本プロパティを `isProActive` に戻す。
    public static var canReadHealthData: Bool { true }

    /// 今日のレディネス判定＋追い込み/ディロード推奨（＝楔の1シグナル）を使えるか。
    ///
    /// v0.x split で **Free 開放**。HRV 連動ディロード提案・RPE 自動調整・部位回復など
    /// 「今日の判断」に直結する助言を含む。深さ（PR 予測・停滞・ボリューム警告等）は別フラグ。
    public static var canUseReadinessCoaching: Bool { true }

    /// 高度コーチング（線形回帰 PR 予測・停滞検出・部位別ボリューム警告・漸進・体組成フェーズ）が使えるか。Pro。
    public static var canUseAdvancedCoaching: Bool { isProActive }

    /// Live Activity / Dynamic Island を起動できるか
    ///
    /// v0.x で Free 開放。一番尖った差別化を全ユーザーに体験させる方針。
    /// 将来再ゲートする場合は本プロパティを `isProActive` に戻すだけで巻き戻し可能。
    public static var canUseLiveActivity: Bool { true }

    /// iCloud / CloudKit 同期を有効にできるか
    public static var canUseICloudSync: Bool { isProActive }

    /// 高度な分析グラフ（週次ボリューム / 種目別推移 / 部位別）を見られるか。Pro。
    public static var canSeeAdvancedAnalytics: Bool { isProActive }

    /// コンディションの長期トレンド（HRV・睡眠・安静時心拍・体組成の推移グラフ）を見られるか。Pro（深さ）。
    public static var canSeeHealthTrends: Bool { isProActive }

    /// データエクスポート（CSV / JSON）を実行できるか
    public static var canExportData: Bool { isProActive }
}

/// 機能ゲートに引っかかったときに投げるエラー。UI 側で localizedDescription を表示し、
/// ProUpgradeSheet を開く導線を提供する想定。
public enum ProGateError: LocalizedError, Equatable {
    case routineLimitReached(current: Int, limit: Int)
    case customExerciseLimitReached(current: Int, limit: Int)
    case advancedCoachingRequiresPro
    case liveActivityRequiresPro
    case iCloudSyncRequiresPro
    case advancedAnalyticsRequiresPro
    case healthTrendsRequiresPro
    case dataExportRequiresPro

    public var errorDescription: String? {
        switch self {
        case .routineLimitReached(_, let limit):
            return loc("Free プランで作成できるルーティンは \(limit) 個までです。Pro にアップグレードすると無制限になります。")
        case .customExerciseLimitReached(_, let limit):
            return loc("Free プランで作成できるカスタム種目は \(limit) 個までです。Pro にアップグレードすると無制限になります。")
        case .advancedCoachingRequiresPro:
            return loc("高度コーチング（PR 予測・ボリューム警告など）は Pro 限定機能です。")
        case .liveActivityRequiresPro:
            return loc("Live Activity は Pro 限定機能です。")
        case .iCloudSyncRequiresPro:
            return loc("iCloud 同期は Pro 限定機能です。")
        case .advancedAnalyticsRequiresPro:
            return loc("高度な分析は Pro 限定機能です。")
        case .healthTrendsRequiresPro:
            return loc("コンディションの長期トレンドは Pro 限定機能です。")
        case .dataExportRequiresPro:
            return loc("データエクスポートは Pro 限定機能です。")
        }
    }
}

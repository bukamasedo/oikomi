import Foundation

/// App Store レビュー依頼（StoreKit `requestReview`）を「いつ呼ぶか」を決める純粋ロジック。
///
/// 表示回数の最終的な制御は OS（年3回まで）に委ねる。本ゲートはアプリ側の自前間引きとして、
/// 完了セッション数のマイルストーン到達時のみ、かつ前回依頼から一定期間が空いている場合だけ
/// 「依頼してよい」と判断する。状態は `UserDefaults` に保存し、UI 非依存でテスト容易にする。
public enum ReviewRequestGate {

    /// 依頼を出す完了セッション数の節目（昇順）。最初の依頼は 3 回目の完了後。
    static let milestones = [3, 15, 40]

    /// 連投を避ける最小間隔（前回依頼からこれ未満なら出さない）。
    static let minInterval: TimeInterval = 90 * 24 * 60 * 60

    static let lastConsumedMilestoneKey = "OikomiReview_LastConsumedMilestone"
    static let lastRequestDateKey = "OikomiReview_LastRequestDate"

    /// 今レビュー依頼を出すべきなら、その対象マイルストーンを返す。出すべきでなければ `nil`。
    ///
    /// 条件: `completedSessionCount` 以下で、まだ消化していない最大のマイルストーンが存在し、
    /// かつ前回依頼から `minInterval` 以上経過している（初回は前回日時が無いので無条件で可）。
    public static func milestoneDue(
        completedSessionCount: Int,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> Int? {
        let lastConsumed = defaults.integer(forKey: lastConsumedMilestoneKey)
        guard
            let target = milestones.last(where: { $0 <= completedSessionCount && $0 > lastConsumed })
        else {
            return nil
        }
        if let last = lastRequestDate(in: defaults), now.timeIntervalSince(last) < minInterval {
            return nil
        }
        return target
    }

    /// レビュー依頼を出した後に呼ぶ。消化マイルストーンと依頼日時を記録する。
    ///
    /// OS が実際にダイアログを表示したかは判定できないため、Apple 推奨に従い「呼んだら消化・リトライしない」。
    public static func markRequested(
        milestone: Int,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) {
        defaults.set(milestone, forKey: lastConsumedMilestoneKey)
        defaults.set(now.timeIntervalSince1970, forKey: lastRequestDateKey)
    }

    private static func lastRequestDate(in defaults: UserDefaults) -> Date? {
        let raw = defaults.double(forKey: lastRequestDateKey)
        return raw > 0 ? Date(timeIntervalSince1970: raw) : nil
    }
}

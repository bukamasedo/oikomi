import Foundation

/// ホーム画面・分析タブで使う集計関数群。すべて純粋関数。
///
/// SwiftData クエリ結果を渡して呼ぶ前提で、副作用なし・テスト容易。
public enum Analytics {

    /// 連続記録日数（streak）を計算する。
    ///
    /// 仕様: 「今日 or 昨日」が直近セッションなら streak は継続中とみなす。
    /// 連続する日付がギャップなく続く限りカウント。
    ///
    /// - Parameters:
    ///   - sessions: 完了済みセッション（endedAt != nil）の配列。順不同で OK。
    ///   - referenceDate: 「今日」とみなす基準日（テスト容易性のため引数化）
    ///   - calendar: 用途に応じた Calendar（デフォルト = .current）
    public static func streakDays(
        sessions: [WorkoutSession],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let activeDates = Set(
            sessions
                .filter { $0.endedAt != nil }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        guard !activeDates.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: referenceDate)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // 起点は「今日に活動あり」なら今日、なければ昨日。それ以外は streak 0。
        var cursor: Date
        if activeDates.contains(today) {
            cursor = today
        } else if activeDates.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while activeDates.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    /// 指定期間のセットを部位別ボリューム（重量 × レップ）に集計する。
    ///
    /// 1セットが複数の主働筋に該当する場合、それぞれにフルカウントで加算する
    /// （業界一般的な簡易集計）。
    public static func volumeByMuscleGroup(
        sets: [SetRecord],
        in range: ClosedRange<Date>
    ) -> [MuscleGroup: Double] {
        var totals: [MuscleGroup: Double] = [:]
        for set in sets where range.contains(set.completedAt) {
            guard let weight = set.weight, let reps = set.reps, weight > 0, reps > 0 else { continue }
            let contribution = weight * Double(reps)
            for group in (set.exercise?.muscleGroups ?? []) {
                totals[group, default: 0] += contribution
            }
        }
        return totals
    }

    /// 「今週」の日付範囲（月曜開始）。
    public static func currentWeekRange(
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ClosedRange<Date> {
        var cal = calendar
        cal.firstWeekday = 2  // 月曜
        let now = referenceDate
        let weekday = cal.component(.weekday, from: now)
        // firstWeekday=2(月) のとき、weekday=2(月)なら 0 日戻る、weekday=1(日)なら 6 日戻る
        let daysFromMonday = (weekday + 5) % 7
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -daysFromMonday, to: now)!)
        let end = cal.date(byAdding: .day, value: 7, to: start)!.addingTimeInterval(-1)
        return start...end
    }
}

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

    /// 「先週」の日付範囲（月曜開始）。今週レンジを 7 日前にシフト。
    public static func lastWeekRange(
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ClosedRange<Date> {
        let thisWeek = currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let start = calendar.date(byAdding: .day, value: -7, to: thisWeek.lowerBound)!
        let end = calendar.date(byAdding: .day, value: -7, to: thisWeek.upperBound)!
        return start...end
    }

    /// 先週比ボリューム変動から警告/称賛アドバイスを生成する。
    ///
    /// 仕様書 §4.2.2 のボリューム警告ロジック：
    /// - 先週比 150% 超 → オーバーワーク警告
    /// - 先週比 50% 未満（かつ先週に十分なボリュームあり）→ 不足警告
    /// - それ以外で先週比 90〜110% → 安定の称賛
    ///
    /// 結果はインパクト（変化幅）の大きい順に並べて返す。
    public static func volumeAdvice(
        from sets: [SetRecord],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        let thisWeekRange = currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let lastWeekRange = lastWeekRange(referenceDate: referenceDate, calendar: calendar)
        let thisWeek = volumeByMuscleGroup(sets: sets, in: thisWeekRange)
        let lastWeek = volumeByMuscleGroup(sets: sets, in: lastWeekRange)

        var advices: [CoachingAdvice] = []

        // 過剰/不足の判定
        let allMuscles = Set(thisWeek.keys).union(lastWeek.keys)
        for muscle in allMuscles {
            let this = thisWeek[muscle] ?? 0
            let last = lastWeek[muscle] ?? 0

            // どちらも極小なら無視
            guard max(this, last) >= 500 else { continue }

            // 先週ゼロで今週多い → 新規参入。1.5倍ルールには該当しないが情報として有用なので軽い info
            if last == 0 && this > 0 {
                advices.append(
                    CoachingAdvice(
                        title: "新しい部位",
                        message: "\(muscle.displayName)を今週から再開しました。",
                        severity: .info,
                        impact: this
                    )
                )
                continue
            }
            // 今週ゼロで先週多い → 抜け。下記の 50% 判定と等価なのでスキップ
            guard last > 0 else { continue }

            let ratio = this / last

            if ratio > 1.5 {
                let percent = Int((ratio * 100).rounded())
                advices.append(
                    CoachingAdvice(
                        title: "オーバーワーク注意",
                        message: "今週の\(muscle.displayName)トレが先週比\(percent)%です。回復を意識しましょう。",
                        severity: .warning,
                        impact: this - last
                    )
                )
            } else if ratio < 0.5 {
                let percent = Int((ratio * 100).rounded())
                advices.append(
                    CoachingAdvice(
                        title: "ボリューム不足",
                        message: "今週の\(muscle.displayName)トレは先週比\(percent)%です。追加できる余地があります。",
                        severity: .warning,
                        impact: last - this
                    )
                )
            } else if (0.9...1.1).contains(ratio) {
                advices.append(
                    CoachingAdvice(
                        title: "安定したペース",
                        message: "今週の\(muscle.displayName)は先週とほぼ同じボリュームを維持できています。",
                        severity: .success,
                        impact: this
                    )
                )
            }
        }

        return advices.sorted { $0.impact > $1.impact }
    }
}

/// ホーム画面・通知に出す簡易コーチングメッセージ。
public struct CoachingAdvice: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let message: String
    public let severity: Severity
    /// 並び替えに使う重要度。値が大きいほど上位表示
    public let impact: Double

    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        severity: Severity,
        impact: Double
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.impact = impact
    }

    public enum Severity: String, Sendable {
        case info
        case warning
        case success
    }
}

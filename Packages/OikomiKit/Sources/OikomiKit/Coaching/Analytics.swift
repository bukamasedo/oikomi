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

    /// 直近 N 週分の週次ボリューム時系列を返す。古い順。
    ///
    /// グラフ表示用。各週は月曜開始でグループ化される。
    public static func weeklyVolumeSeries(
        sets: [SetRecord],
        weeks: Int = 8,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [WeeklyVolumePoint] {
        let thisWeek = currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        var points: [WeeklyVolumePoint] = []
        for offset in (0..<weeks).reversed() {
            let start = calendar.date(byAdding: .day, value: -7 * offset, to: thisWeek.lowerBound)!
            let end = calendar.date(byAdding: .day, value: -7 * offset, to: thisWeek.upperBound)!
            let range = start...end
            let byGroup = volumeByMuscleGroup(sets: sets, in: range)
            let total = byGroup.values.reduce(0, +)
            points.append(
                WeeklyVolumePoint(
                    weekStart: start,
                    total: total,
                    byMuscleGroup: byGroup
                )
            )
        }
        return points
    }

    /// ディロード（休息）推奨アドバイスを生成する。
    ///
    /// 仕様書 §4.2.2 のディロード推奨の v0.1 簡易版。HRV ベースの本格判定は v1.1 で追加予定。
    /// 現状は「連続トレ日数」と「直近4週の週ボリュームの増加率」をシグナルにする：
    /// - 連続 5 日以上トレーニング → 休息提案
    /// - 直近1週のボリュームが過去3週平均の 130% 以上 → ディロード提案
    public static func deloadAdvice(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        var advices: [CoachingAdvice] = []

        // 1) 連続トレ日数
        let activeDates = Set(
            sessions
                .filter { $0.endedAt != nil }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        var consecutive = 0
        var cursor = calendar.startOfDay(for: referenceDate)
        while activeDates.contains(cursor) {
            consecutive += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        if consecutive >= 5 {
            advices.append(
                CoachingAdvice(
                    title: "休息日を入れましょう",
                    message: "\(consecutive) 日連続でトレーニングしています。回復のために 1 日空けることも検討してください。",
                    severity: .warning,
                    impact: Double(consecutive) * 1000
                )
            )
        }

        // 2) 直近1週 vs 過去3週平均の総ボリューム比較
        let thisWeek = currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let thisVolume = volumeByMuscleGroup(sets: sets, in: thisWeek).values.reduce(0, +)

        var priorAvg = 0.0
        var validWeeks = 0
        for weekOffset in 1...3 {
            let start = calendar.date(byAdding: .day, value: -7 * weekOffset, to: thisWeek.lowerBound)!
            let end = calendar.date(byAdding: .day, value: -7 * weekOffset, to: thisWeek.upperBound)!
            let v = volumeByMuscleGroup(sets: sets, in: start...end).values.reduce(0, +)
            if v > 0 {
                priorAvg += v
                validWeeks += 1
            }
        }
        if validWeeks >= 2 {
            priorAvg /= Double(validWeeks)
            if thisVolume > priorAvg * 1.3 && priorAvg > 1000 {
                let percent = Int((thisVolume / priorAvg * 100).rounded())
                advices.append(
                    CoachingAdvice(
                        title: "ディロード推奨",
                        message: "今週の総ボリュームが過去3週平均の \(percent)% です。来週は強度を 80% 程度に落とすことを検討してください。",
                        severity: .warning,
                        impact: thisVolume - priorAvg
                    )
                )
            }
        }

        return advices.sorted { $0.impact > $1.impact }
    }

    /// 自己ベスト更新の可能性が高い種目について、コーチングアドバイスを生成する。
    ///
    /// 仕様書 §4.2.2 「PR 予測 — 直近5回の伸び率から推定」のシンプル実装。
    /// 線形回帰の代わりに「直近 N セッションの最高 1RM が現 PR の 95% 以上」を閾値とする。
    /// より高度な予測モデルは v1.1 以降で検討。
    public static func prPredictions(
        sets: [SetRecord],
        records: [PersonalRecord],
        sessionCount: Int = 3,
        threshold: Double = 0.95,
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        var advices: [CoachingAdvice] = []

        for pr in records {
            guard let exercise = pr.exercise, pr.estimated1RM > 0 else { continue }
            let exerciseId = exercise.id

            // 種目別のセットを「セッション単位」にまとめて、各セッションの最高 1RM を取る
            let exerciseSets = sets.filter { !$0.isWarmup && $0.exercise?.id == exerciseId }
            let bySession = Dictionary(grouping: exerciseSets) { $0.session?.id ?? UUID() }
            let sessionMaxes = bySession.values
                .compactMap { setsInSession -> (date: Date, max: Double)? in
                    let validRMs = setsInSession.compactMap(\.estimated1RM)
                    guard let maxRM = validRMs.max(),
                        let latest = setsInSession.map(\.completedAt).max()
                    else {
                        return nil
                    }
                    return (date: latest, max: maxRM)
                }
                .sorted { $0.date > $1.date }
                .prefix(sessionCount)

            guard let bestRecent = sessionMaxes.map(\.max).max(), bestRecent > 0 else { continue }
            let ratio = bestRecent / pr.estimated1RM

            // 既に PR を超えていれば（次回更新もう間近で予測価値あり）または閾値を超えていれば予測
            if ratio >= threshold {
                let predicted = max(pr.estimated1RM, bestRecent) * 1.025  // +2.5% を狙う
                advices.append(
                    CoachingAdvice(
                        title: "PR 更新の可能性",
                        message: "次回\(exercise.name)で推定 \(predicted.formatted(.number.precision(.fractionLength(1))))kg の PR を狙えます。",
                        severity: .info,
                        impact: predicted
                    )
                )
            }
        }

        return advices.sorted { $0.impact > $1.impact }
    }

    /// 指定種目の「最大挙上重量の日次推移」を返す。古い順。
    ///
    /// 種目別チャート用。同一日に複数セットあれば最大値を取る。ウォームアップは除外。
    public static func maxWeightSeries(
        sets: [SetRecord],
        forExerciseId exerciseId: UUID,
        calendar: Calendar = .current
    ) -> [DateWeightPoint] {
        let filtered = sets.filter { set in
            !set.isWarmup
                && set.exercise?.id == exerciseId
                && (set.weight ?? 0) > 0
        }
        let grouped = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.completedAt) }
        return grouped
            .compactMap { (date, sets) -> DateWeightPoint? in
                let maxWeight = sets.compactMap(\.weight).max() ?? 0
                return DateWeightPoint(date: date, weight: maxWeight)
            }
            .sorted { $0.date < $1.date }
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

/// 1週間分の集計データポイント。
public struct WeeklyVolumePoint: Sendable, Identifiable, Hashable {
    public var id: Date { weekStart }
    public let weekStart: Date
    public let total: Double
    public let byMuscleGroup: [MuscleGroup: Double]

    public init(weekStart: Date, total: Double, byMuscleGroup: [MuscleGroup: Double]) {
        self.weekStart = weekStart
        self.total = total
        self.byMuscleGroup = byMuscleGroup
    }
}

/// 日次重量データポイント。
public struct DateWeightPoint: Sendable, Identifiable, Hashable {
    public var id: Date { date }
    public let date: Date
    public let weight: Double

    public init(date: Date, weight: Double) {
        self.date = date
        self.weight = weight
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

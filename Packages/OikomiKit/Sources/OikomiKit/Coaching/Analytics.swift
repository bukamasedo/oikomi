import Foundation

/// ホーム画面・分析タブで使う集計関数群。すべて純粋関数。
///
/// SwiftData クエリ結果を渡して呼ぶ前提で、副作用なし・テスト容易。
public enum Analytics {

    /// 指定週内のユニークなトレーニング実施日数を返す。
    ///
    /// 筋トレは休養日を含むサイクルが前提なので「連続日数」ではなく「週あたり頻度」で進捗を測る。
    /// 仕様: 範囲内に endedAt != nil のセッションがある日を 1 日とカウント。同日複数セッションは 1 日扱い。
    ///
    /// - Parameters:
    ///   - sessions: 完了済みセッション（endedAt != nil）の配列。順不同で OK。
    ///   - range: 集計対象の期間（通常は `currentWeekRange()`）
    ///   - calendar: 用途に応じた Calendar（デフォルト = .current）
    public static func weeklySessionDays(
        sessions: [WorkoutSession],
        in range: ClosedRange<Date>,
        calendar: Calendar = .current
    ) -> Int {
        let days = Set(
            sessions
                .filter { $0.endedAt != nil && range.contains($0.startedAt) }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        return days.count
    }

    /// 連続してトレーニングを実施した「週」の数を返す。
    ///
    /// 仕様: 「今週 or 先週」を起点に、過去に向かって 1 セッション以上ある週がギャップなく続く限りカウント。
    /// 「今週まだ未実施」でも先週があれば streak は継続中扱い（休養日と同じ哲学）。
    ///
    /// - Parameters:
    ///   - sessions: 完了済みセッション（endedAt != nil）の配列。順不同で OK。
    ///   - referenceDate: 「今週」とみなす基準日
    ///   - calendar: 週の起算日を決める Calendar
    public static func consecutiveActiveWeeks(
        sessions: [WorkoutSession],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let activeWeekStarts = Set(
            sessions
                .filter { $0.endedAt != nil }
                .compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.startedAt)?.start }
        )
        guard !activeWeekStarts.isEmpty else { return 0 }

        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start
        else { return 0 }
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!

        var cursor: Date
        if activeWeekStarts.contains(thisWeekStart) {
            cursor = thisWeekStart
        } else if activeWeekStarts.contains(lastWeekStart) {
            cursor = lastWeekStart
        } else {
            return 0
        }

        var count = 0
        while activeWeekStarts.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
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

    /// 指定期間のワーキングセット数を部位別に集計する。
    ///
    /// `volumeByMuscleGroup` と異なり「セット数（刺激の頻度）」を測る指標。
    /// ウォームアップと未完了（計画のみ）セットは除外する。
    /// `.fullBody` は特定部位に紐づかないため集計対象外。
    public static func setCountByMuscleGroup(
        sets: [SetRecord],
        in range: ClosedRange<Date>
    ) -> [MuscleGroup: Int] {
        var counts: [MuscleGroup: Int] = [:]
        for set in sets where range.contains(set.completedAt) {
            guard !set.isWarmup, set.isCompleted else { continue }
            for group in (set.exercise?.muscleGroups ?? []) where group != .fullBody {
                counts[group, default: 0] += 1
            }
        }
        return counts
    }

    /// 「今週」の部位別セット数を、MEV/MAV 推奨レンジと合わせて集計する。
    ///
    /// UI 側はこの戻り値を直接表示できる。`count` 降順ソート済み。
    /// `weeklySetTarget.isTracked == false` の部位（fullBody）は含めない。
    public static func weeklySetCountReport(
        sets: [SetRecord],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [MuscleSetCountRow] {
        let range = currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let counts = setCountByMuscleGroup(sets: sets, in: range)
        let rows: [MuscleSetCountRow] = MuscleGroup.allCases.compactMap { muscle in
            let target = muscle.weeklySetTarget
            guard target.isTracked else { return nil }
            let count = counts[muscle] ?? 0
            return MuscleSetCountRow(muscle: muscle, count: count, target: target)
        }
        return rows.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.muscle.rawValue < rhs.muscle.rawValue
        }
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
    /// 仕様書 §4.2.2 準拠。3 種類のシグナルを組み合わせる：
    /// - 連続 5 日以上トレーニング → 休息提案
    /// - 直近1週のボリュームが過去3週平均の 130% 以上 → ディロード提案
    /// - レディネス（コンディション総合スコア）が low → 回復優先提案 / high → PR 狙い提案
    ///
    /// レディネス（コンディション総合スコア）は呼び出し側で `HealthStore.readinessSnapshot()` を取得して渡す。
    /// Pro 未契約や HealthKit 未認可など readiness が nil の場合、レディネス判定はスキップして既存ロジックのみ動作する。
    public static func deloadAdvice(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        readiness: ReadinessScore? = nil,
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

        // 3) レディネス（HRV z-score 主・睡眠/安静時心拍 統合）判定
        if let advice = readinessAdvice(readiness: readiness) {
            advices.append(advice)
        }

        return advices.sorted { $0.impact > $1.impact }
    }

    /// レディネススコアから単発の `CoachingAdvice` を生成する。
    ///
    /// low → 回復優先（warning）、high → PR 狙える日（success）、normal/nil → なし。
    static func readinessAdvice(readiness: ReadinessScore?) -> CoachingAdvice? {
        guard let readiness else { return nil }
        switch readiness.band {
        case .low:
            return CoachingAdvice(
                title: "今日は回復優先",
                message:
                    "コンディションスコアが \(readiness.value) と低めです。前回比 80% 程度の重量で軽めに組むことを検討してください。",
                severity: .warning,
                impact: Double(100 - readiness.value) * 100
            )
        case .high:
            return CoachingAdvice(
                title: "コンディション良好",
                message: "コンディションスコアが \(readiness.value) と好調です。PR を狙える日です。",
                severity: .success,
                // .low と同スケールに揃える（×100）。そうしないと好調メッセージが他シグナルに埋もれて表示されない。
                impact: Double(readiness.value) * 100
            )
        case .normal:
            return nil
        }
    }

    /// 自己ベスト更新の可能性が高い種目について、コーチングアドバイスを生成する。
    ///
    /// 仕様書 §4.2.2 「PR 予測 — 直近の伸び率から推定」を最小二乗線形回帰で実装。
    /// 種目ごとに「セッション順 (0..n-1)」を X 軸、各セッションの最高推定 1RM を Y 軸として
    /// 直線フィットし、次回セッション (X = n) の予測値が現 PR を超える時のみ advice を発行する。
    ///
    /// フィルタ条件：
    /// - 直近 `windowSize` セッションを採用（デフォルト 10）。最低 `minSamples` (= 5) 必要。
    /// - slope > 0（上昇トレンド）のみ予測
    /// - R² >= `minR2`（デフォルト 0.3）でばらつきが大きすぎる系列は除外
    /// - 予測値 > 現 PR の場合のみ発行
    public static func prPredictions(
        sets: [SetRecord],
        records: [PersonalRecord],
        windowSize: Int = 10,
        minSamples: Int = 5,
        minR2: Double = 0.3,
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg
    ) -> [CoachingAdvice] {
        var advices: [CoachingAdvice] = []

        for pr in records {
            guard let exercise = pr.exercise, pr.estimated1RM > 0 else { continue }
            let exerciseId = exercise.id

            // 種目別のセットを「セッション単位」にまとめて、各セッションの最高 1RM を取り
            // 古い順に並べる（線形回帰の X は 0..n-1）
            let exerciseSets = sets.filter { !$0.isWarmup && $0.exercise?.id == exerciseId }
            let bySession = Dictionary(grouping: exerciseSets) { $0.session?.id ?? UUID() }
            let sessionMaxes =
                bySession.values
                .compactMap { setsInSession -> (date: Date, max: Double)? in
                    let validRMs = setsInSession.compactMap(\.estimated1RM)
                    guard let maxRM = validRMs.max(),
                        let latest = setsInSession.map(\.completedAt).max()
                    else { return nil }
                    return (date: latest, max: maxRM)
                }
                .sorted { $0.date < $1.date }
                .suffix(windowSize)

            guard sessionMaxes.count >= minSamples else { continue }
            let points = sessionMaxes.enumerated().map {
                (x: Double($0.offset), y: $0.element.max)
            }
            guard let fit = linearRegression(points) else { continue }
            guard fit.slope > 0, fit.r2 >= minR2 else { continue }

            let predicted = fit.intercept + fit.slope * Double(points.count)
            guard predicted > pr.estimated1RM else { continue }

            let growth = predicted - pr.estimated1RM
            advices.append(
                CoachingAdvice(
                    title: "PR 更新の可能性",
                    message:
                        "次回\(exercise.name)で推定 \(WeightFormatter.oneRM(kilograms: predicted, in: weightUnit)) の PR を狙えます（直近\(points.count)セッションの上昇トレンドより）。",
                    severity: .info,
                    impact: predicted + growth
                )
            )
        }

        return advices.sorted { $0.impact > $1.impact }
    }

    /// 最小二乗法による単純線形回帰。
    ///
    /// 戻り値の `r2` は決定係数（1 に近いほど直線フィットが良い）。
    /// 入力点が 2 点未満、または X の分散がゼロのときは `nil`。
    static func linearRegression(
        _ points: [(x: Double, y: Double)]
    ) -> (slope: Double, intercept: Double, r2: Double)? {
        let n = Double(points.count)
        guard n >= 2 else { return nil }
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0) { $0 + $1.x * $1.x }
        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n

        let meanY = sumY / n
        let ssTot = points.reduce(0) { acc, p in acc + (p.y - meanY) * (p.y - meanY) }
        let ssRes = points.reduce(0) { acc, p in
            let pred = intercept + slope * p.x
            return acc + (p.y - pred) * (p.y - pred)
        }
        let r2 = ssTot == 0 ? (ssRes == 0 ? 1 : 0) : 1 - ssRes / ssTot
        return (slope, intercept, r2)
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
        return
            grouped
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

    /// RPE オートレギュレーション（セッション間）。
    ///
    /// 種目ごとに直近 2 セッションの平均 RPE を見て、次回の推奨重量を提案する。
    /// 目標 RPE を中心に、上限 = targetRPE+1（重すぎ→減量）、下限 = targetRPE-2（軽すぎ→増量）。
    /// 既定 targetRPE=8 では上限 9・下限 6。RPE 未入力の種目・データ不足（< 2 セッション）はスキップ。提案は読み取り専用。
    /// impact は同関数内（複数種目）の並び順用で、変化幅が大きい提案を上位にする。
    public static func autoregulationAdvice(
        sets: [SetRecord],
        targetRPE: Double = 8,
        minSessions: Int = 2,
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg
    ) -> [CoachingAdvice] {
        let highThreshold = targetRPE + 1  // これ以上が続く → 重すぎ
        let lowThreshold = targetRPE - 2  // これ以下が続く → 軽すぎ
        let working = sets.filter {
            !$0.isWarmup && $0.isCompleted && $0.rpe != nil && ($0.weight ?? 0) > 0
        }
        let byExercise = Dictionary(grouping: working) { $0.exercise?.id ?? UUID() }

        var advices: [CoachingAdvice] = []
        for (_, exSets) in byExercise {
            guard let exercise = exSets.first?.exercise else { continue }

            let bySession = Dictionary(grouping: exSets) { $0.session?.id ?? UUID() }
            let summaries =
                bySession.values
                .compactMap { s -> (date: Date, avgRPE: Double, topWeight: Double)? in
                    let rpes = s.compactMap(\.rpe)
                    guard !rpes.isEmpty, let date = s.map(\.completedAt).max() else { return nil }
                    let avg = rpes.reduce(0, +) / Double(rpes.count)
                    let topWeight = s.compactMap(\.weight).max() ?? 0
                    return (date, avg, topWeight)
                }
                .sorted { $0.date < $1.date }

            guard summaries.count >= minSessions else { continue }
            let recent = summaries.suffix(2)
            guard let lastWeight = recent.last?.topWeight, lastWeight > 0 else { continue }

            if recent.allSatisfy({ $0.avgRPE >= highThreshold }) {
                let suggested = roundToPlate(lastWeight * 0.95)
                guard suggested < lastWeight else { continue }
                advices.append(
                    CoachingAdvice(
                        title: "重量を少し下げましょう",
                        message:
                            "\(exercise.name)は直近2回とも高強度（RPE \(Int(highThreshold)) 以上）でした。次回は \(WeightFormatter.oneRM(kilograms: lastWeight, in: weightUnit)) → \(WeightFormatter.oneRM(kilograms: suggested, in: weightUnit)) を目安に。",
                        severity: .warning,
                        impact: (lastWeight - suggested) + 50
                    )
                )
            } else if recent.allSatisfy({ $0.avgRPE <= lowThreshold }) {
                let suggested = roundToPlate(lastWeight * 1.025)
                guard suggested > lastWeight else { continue }
                advices.append(
                    CoachingAdvice(
                        title: "重量を上げてみましょう",
                        message:
                            "\(exercise.name)は直近2回とも余裕（RPE \(Int(lowThreshold)) 以下）でした。次回は \(WeightFormatter.oneRM(kilograms: lastWeight, in: weightUnit)) → \(WeightFormatter.oneRM(kilograms: suggested, in: weightUnit)) を目安に。",
                        severity: .info,
                        impact: (suggested - lastWeight) + 50
                    )
                )
            }
        }
        return advices.sorted { $0.impact > $1.impact }
    }

    /// 2.5kg 刻みに丸める（プレート単位）。
    static func roundToPlate(_ weight: Double) -> Double {
        (weight / 2.5).rounded() * 2.5
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

/// 部位別の週セット数 + MEV/MAV 推奨レンジ + 過不足判定。
///
/// 分析タブの「部位別」セクションで一覧表示する。
public struct MuscleSetCountRow: Sendable, Identifiable, Hashable {
    public var id: MuscleGroup { muscle }
    public let muscle: MuscleGroup
    public let count: Int
    public let target: WeeklySetTarget

    public init(muscle: MuscleGroup, count: Int, target: WeeklySetTarget) {
        self.muscle = muscle
        self.count = count
        self.target = target
    }

    public enum Status: String, Sendable {
        /// MEV 未満（刺激不足）
        case insufficient
        /// MEV 〜 MAV のレンジ内
        case optimal
        /// MAV 超過（過剰）
        case excessive
    }

    public var status: Status {
        if count < target.mev { return .insufficient }
        if count > target.mav { return .excessive }
        return .optimal
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

import Foundation

/// 部位の回復状態。
public enum RecoveryState: String, CaseIterable, Hashable, Sendable {
    case recovered  // 回復済
    case recovering  // 回復中
    case fatigued  // 疲労
    case untrained  // 未実施
}

/// 1 部位の回復状態を表す表示用の行。
public struct MuscleRecoveryRow: Sendable, Identifiable, Hashable {
    public var id: MuscleGroup { muscle }
    public let muscle: MuscleGroup
    /// 最終トレ日からの経過日数。未実施は nil。
    public let daysSinceLastTrained: Int?
    /// 回復率 0...1（バー表示用）。`.untrained` 行は便宜上 1.0。
    /// この値を読む側は必ず `state` も確認すること（未実施を「完全回復」と誤解しないため）。
    public let recoveryFraction: Double
    public let state: RecoveryState

    public init(
        muscle: MuscleGroup, daysSinceLastTrained: Int?,
        recoveryFraction: Double, state: RecoveryState
    ) {
        self.muscle = muscle
        self.daysSinceLastTrained = daysSinceLastTrained
        self.recoveryFraction = recoveryFraction
        self.state = state
    }
}

/// 部位別リカバリーの純粋計算。SetRecord の completedAt と Exercise.muscleGroups だけから導出する。
public enum MuscleRecovery {

    // 暫定定数（テストで調整可・実装詳細なので private）。
    private static let freeSets = 6  // これ以下のセット数は回復時間を延ばさない
    private static let hoursPerExtraSet = 3.0  // freeSets 超 1 セットあたりの延長時間
    private static let maxExtraHours = 24.0  // 負荷による延長の上限
    private static let highRPE = 8.5  // これ以上の平均 RPE で回復時間 +rpeAdjustHours
    private static let lowRPE = 6.0  // これ以下で -rpeAdjustHours
    private static let rpeAdjustHours = 6.0
    private static let recentTrainingDays = 10  // recoveryAdvice の対象とする「直近トレ」の窓（日）

    /// 部位別の基準回復時間（時間）。大筋群ほど長い。fullBody は untracked。
    private static func baseHours(for muscle: MuscleGroup) -> Double {
        switch muscle {
        case .quads, .hamstrings, .glutes, .back: return 72
        case .chest, .shoulders: return 48
        case .biceps, .triceps, .forearms, .calves, .abs, .obliques: return 36
        case .fullBody: return 0
        }
    }

    /// 全 tracked 筋群の回復状態。並び: untrained を末尾に固定し、残りを recoveryFraction 降順
    /// （タイブレーク muscle.rawValue 昇順）。
    public static func report(
        sets: [SetRecord],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [MuscleRecoveryRow] {
        let working = sets.filter { !$0.isWarmup && $0.isCompleted }

        // muscle -> その筋群を刺激したワーキングセット
        var byMuscle: [MuscleGroup: [SetRecord]] = [:]
        for set in working {
            for group in (set.exercise?.muscleGroups ?? []) where group.weeklySetTarget.isTracked {
                byMuscle[group, default: []].append(set)
            }
        }

        let referenceDay = calendar.startOfDay(for: referenceDate)
        var rows: [MuscleRecoveryRow] = []

        for muscle in MuscleGroup.allCases where muscle.weeklySetTarget.isTracked {
            let muscleSets = byMuscle[muscle] ?? []
            guard let lastTrained = muscleSets.map(\.completedAt).max() else {
                rows.append(
                    MuscleRecoveryRow(
                        muscle: muscle, daysSinceLastTrained: nil,
                        recoveryFraction: 1.0, state: .untrained))
                continue
            }

            // 直近トレ日（同一カレンダー日）の負荷
            let lastDaySets = muscleSets.filter {
                calendar.isDate($0.completedAt, inSameDayAs: lastTrained)
            }
            let setCount = lastDaySets.count
            let rpes = lastDaySets.compactMap(\.rpe)
            let avgRPE: Double? = rpes.isEmpty ? nil : rpes.reduce(0, +) / Double(rpes.count)

            let base = baseHours(for: muscle)
            let loadExtra = min(maxExtraHours, Double(max(0, setCount - freeSets)) * hoursPerExtraSet)
            var rpeAdjust = 0.0
            if let avgRPE {
                if avgRPE >= highRPE {
                    rpeAdjust = rpeAdjustHours
                } else if avgRPE <= lowRPE {
                    rpeAdjust = -rpeAdjustHours
                }
            }
            let window = max(base * 0.5, base + loadExtra + rpeAdjust)

            // elapsedHours は completedAt の絶対時刻差（回復率の精度のため）。
            // daysSince はカレンダー日数（表示用）。両者は日境界付近で ±1 日ずれうるが意図的。
            let elapsedHours = referenceDate.timeIntervalSince(lastTrained) / 3600.0
            let fraction = min(max(elapsedHours / window, 0.0), 1.0)
            let days =
                calendar.dateComponents(
                    [.day], from: calendar.startOfDay(for: lastTrained), to: referenceDay
                ).day ?? 0

            let state: RecoveryState =
                fraction >= 1.0 ? .recovered : (fraction >= 0.5 ? .recovering : .fatigued)
            rows.append(
                MuscleRecoveryRow(
                    muscle: muscle, daysSinceLastTrained: days,
                    recoveryFraction: fraction, state: state))
        }

        return rows.sorted { lhs, rhs in
            let lu = lhs.state == .untrained ? 1 : 0
            let ru = rhs.state == .untrained ? 1 : 0
            if lu != ru { return lu < ru }
            if lhs.recoveryFraction != rhs.recoveryFraction {
                return lhs.recoveryFraction > rhs.recoveryFraction
            }
            return lhs.muscle.rawValue < rhs.muscle.rawValue
        }
    }

    /// 直近 `recentTrainingDays` 日に鍛えて今 `.recovered` の筋群を「次のトレ候補」として最大1件にまとめる。
    /// 未実施・長期未トレは対象外（ボリューム不足は MEV/MAV 側の責務）。対象ゼロなら空配列。
    public static func recoveryAdvice(
        sets: [SetRecord],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        let ready =
            report(sets: sets, referenceDate: referenceDate, calendar: calendar)
            .filter { row in
                guard let days = row.daysSinceLastTrained else { return false }
                return days <= recentTrainingDays && row.state == .recovered
            }
        guard !ready.isEmpty else { return [] }

        let shown = ready.prefix(4)
        var names = shown.map(\.muscle.displayName).joined(separator: "・")
        if ready.count > 4 { names += " など" }

        return [
            CoachingAdvice(
                title: "回復済みの部位",
                message: "\(names) が回復済みです。次のトレーニング候補です。",
                severity: .info,
                impact: 100 + Double(ready.count) * 10
            )
        ]
    }
}

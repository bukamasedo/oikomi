import Foundation

/// 個人化 MEV/MAV に対する漸進性過負荷の提案（純粋関数）。
public enum ProgressiveOverload {

    private static let maxListed = 4

    /// 今週の部位別セット数を個人化目標と比較し、最大2件の提案を返す。
    /// - MEV 未満の部位（不足）→ warning 1件
    /// - 今週鍛えていて MEV〜MAV 未到達の部位（漸進候補）→ info 1件
    /// MAV 以上は出さない（部位別チップ + deloadAdvice が担当）。
    public static func progressiveOverloadAdvice(
        sets: [SetRecord],
        profile: TrainingProfile = .default,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        let range = Analytics.currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let counts = Analytics.setCountByMuscleGroup(sets: sets, in: range)

        var insufficient: [(muscle: MuscleGroup, gap: Int)] = []
        var progressable: [(muscle: MuscleGroup, room: Int)] = []
        for muscle in MuscleGroup.allCases {
            let target = muscle.weeklySetTarget(for: profile)
            guard target.isTracked else { continue }
            let count = counts[muscle] ?? 0
            if count < target.mev {
                insufficient.append((muscle, target.mev - count))
            } else if count >= 1 && count < target.mav {
                // 今週鍛えている（>=1）かつ MAV 未到達のみ漸進候補（未トレ筋群は対象外）
                progressable.append((muscle, target.mav - count))
            }
        }

        var advices: [CoachingAdvice] = []

        if !insufficient.isEmpty {
            let ordered = insufficient.sorted {
                $0.gap != $1.gap ? $0.gap > $1.gap : $0.muscle.rawValue < $1.muscle.rawValue
            }
            advices.append(
                CoachingAdvice(
                    // volumeAdvice の前週比「ボリューム不足」と区別するため、絶対 MEV 基準は「MEV未達」とする。
                    title: "MEV未達",
                    message:
                        "\(names(ordered.map(\.muscle))) が今週 MEV 未満です。来週は各 +1〜2 セット増やしましょう。",
                    severity: .warning,
                    impact: 1000 + Double(insufficient.count) * 100
                )
            )
        }

        if !progressable.isEmpty {
            let ordered = progressable.sorted {
                $0.room != $1.room ? $0.room > $1.room : $0.muscle.rawValue < $1.muscle.rawValue
            }
            advices.append(
                CoachingAdvice(
                    title: "漸進的に増やす",
                    message:
                        "\(names(ordered.map(\.muscle))) は来週 +1〜2 セットで MAV に向けて漸進できます。",
                    severity: .info,
                    impact: 120 + Double(progressable.count) * 10
                )
            )
        }

        return advices
    }

    /// 最大 `maxListed` 部位を「・」連結。超過分は「など」。
    private static func names(_ muscles: [MuscleGroup]) -> String {
        var s = muscles.prefix(maxListed).map(\.displayName).joined(separator: "・")
        if muscles.count > maxListed { s += " など" }
        return s
    }
}

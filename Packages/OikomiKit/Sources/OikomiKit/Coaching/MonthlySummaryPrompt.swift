import Foundation

/// 月次ダイジェストを Foundation Models 用の (instructions, prompt) に変換する純粋関数。
public enum MonthlySummaryPrompt {

    public struct Payload: Sendable, Hashable {
        public let instructions: String
        public let prompt: String
        public init(instructions: String, prompt: String) {
            self.instructions = instructions
            self.prompt = prompt
        }
    }

    public static func make(from digest: MonthlyTrainingDigest, weightUnit: WeightUnit = .kg) -> Payload {
        let instructions = """
            あなたは筋力トレーニングのコーチです。以下の月次データだけを根拠に、日本語で簡潔な振り返りを書いてください。
            - データに無い事実を作らない。数値を誇張しない。
            - 医療・診断的な助言はしない。
            - headline は1文。highlights は良かった点を2〜3個。watchPoints は気になる点を1〜3個。nextFocus は来月の具体的フォーカスを1〜2個。
            - 前向きで具体的に。各項目は短く。
            """

        var lines: [String] = []
        lines.append("対象月: \(digest.yearMonth)")
        lines.append("トレーニング回数: \(digest.sessionCount) 回 / トレーニング日数: \(digest.trainingDays) 日")
        let volume = Int(weightUnit.fromKilograms(digest.totalVolumeKg).rounded())
        lines.append("総ボリューム: 約 \(volume) \(weightUnit.symbol)")

        if !digest.muscleSetCounts.isEmpty {
            let top = digest.muscleSetCounts.prefix(5)
                .map { "\($0.muscle.displayName) \($0.sets)セット" }
                .joined(separator: "、")
            lines.append("部位別セット数（多い順）: \(top)")
        }
        if !digest.underTrainedMuscles.isEmpty {
            let under = digest.underTrainedMuscles.map(\.displayName).joined(separator: "、")
            lines.append("ボリュームが少なめの部位（週平均が MEV 未満）: \(under)")
        }
        if digest.personalRecords.isEmpty {
            lines.append("今月の自己ベスト更新: なし")
        } else {
            let prs = digest.personalRecords.prefix(5).map { pr -> String in
                let oneRM = Int(weightUnit.fromKilograms(pr.estimated1RM).rounded())
                return "\(pr.exerciseName)（推定1RM \(oneRM)\(weightUnit.symbol)）"
            }.joined(separator: "、")
            lines.append("今月の自己ベスト更新: \(prs)")
        }
        if let readiness = digest.readiness {
            lines.append(
                "コンディションスコア: 平均 \(readiness.average)（好調 \(readiness.highDays)日 / 普通 \(readiness.normalDays)日 / 低調 \(readiness.lowDays)日）"
            )
        }
        if let phase = digest.bodyPhase {
            let perMonth = String(format: "%.1f", abs(phase.kgPerMonth))
            let sign = phase.kgPerMonth >= 0 ? "+" : "-"
            lines.append("体重トレンド: \(phase.phase.displayName)（\(sign)\(perMonth) kg/月）")
        }

        let prompt = "次の月次トレーニングデータを振り返ってください。\n\n" + lines.joined(separator: "\n")
        return Payload(instructions: instructions, prompt: prompt)
    }
}

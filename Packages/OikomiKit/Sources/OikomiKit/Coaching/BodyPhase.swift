import Foundation

/// 体重トレンドから推定するトレーニングフェーズ。
public enum BodyPhase: String, Sendable, CaseIterable {
    case bulk  // 増量期
    case cut  // 減量期
    case maintenance  // 維持期

    public var displayName: String {
        switch self {
        case .bulk: return "増量期"
        case .cut: return "減量期"
        case .maintenance: return "維持期"
        }
    }

    private static let minSamples = 6
    private static let monthlyThresholdKg = 0.5

    /// 体重系列の傾きからフェーズを判定。サンプル不足なら nil。
    /// x は最初の計測点からの経過日数（不規則な計測間隔に対応）、y は kg。
    public static func detect(
        bodyMassSeries: [HealthTrendPoint],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> BodyPhaseResult? {
        let valid = bodyMassSeries.filter { $0.value > 0 }.sorted { $0.date < $1.date }
        guard valid.count >= minSamples, let first = valid.first else { return nil }
        let points: [(x: Double, y: Double)] = valid.map { point in
            let days = calendar.dateComponents([.day], from: first.date, to: point.date).day ?? 0
            return (x: Double(days), y: point.value)
        }
        guard let fit = Analytics.linearRegression(points) else { return nil }
        let kgPerMonth = fit.slope * 30
        let phase: BodyPhase
        if kgPerMonth > monthlyThresholdKg {
            phase = .bulk
        } else if kgPerMonth < -monthlyThresholdKg {
            phase = .cut
        } else {
            phase = .maintenance
        }
        return BodyPhaseResult(phase: phase, kgPerMonth: kgPerMonth)
    }

    /// フェーズに応じた文脈コーチングを 0〜1 件返す。維持期・nil は空。
    public static func phaseAdvice(_ result: BodyPhaseResult?) -> [CoachingAdvice] {
        guard let result else { return [] }
        let formatted = String(format: "%.1f", abs(result.kgPerMonth))
        switch result.phase {
        case .bulk:
            return [
                CoachingAdvice(
                    title: "増量期",
                    message: "体重が +\(formatted) kg/月 で増加中。PR を伸ばしやすい時期です。",
                    severity: .info,
                    impact: 110
                )
            ]
        case .cut:
            return [
                CoachingAdvice(
                    title: "減量期",
                    message: "体重が -\(formatted) kg/月 で減少中。筋力を維持できていれば成功です。",
                    severity: .info,
                    impact: 110
                )
            ]
        case .maintenance:
            return []
        }
    }
}

/// フェーズ判定結果。
public struct BodyPhaseResult: Sendable, Hashable {
    public let phase: BodyPhase
    public let kgPerMonth: Double  // 体重変化率（符号付き）

    public init(phase: BodyPhase, kgPerMonth: Double) {
        self.phase = phase
        self.kgPerMonth = kgPerMonth
    }
}

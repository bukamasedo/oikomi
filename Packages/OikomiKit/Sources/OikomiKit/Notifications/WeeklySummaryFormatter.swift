import Foundation

/// 週次サマリ通知の本文ビルダー。純粋関数のみ。
public enum WeeklySummaryFormatter {

    /// 1 週間分のサマリ。`Analytics` の戻り値を受け取って通知本文に整形する。
    public struct Report: Sendable, Equatable {
        public let sessionDays: Int
        public let totalVolume: Double
        public let topMuscles: [(muscle: MuscleGroup, volume: Double)]

        public init(
            sessionDays: Int,
            totalVolume: Double,
            topMuscles: [(muscle: MuscleGroup, volume: Double)]
        ) {
            self.sessionDays = sessionDays
            self.totalVolume = totalVolume
            self.topMuscles = topMuscles
        }

        public static func == (lhs: Report, rhs: Report) -> Bool {
            guard lhs.sessionDays == rhs.sessionDays else { return false }
            guard lhs.totalVolume == rhs.totalVolume else { return false }
            guard lhs.topMuscles.count == rhs.topMuscles.count else { return false }
            for (a, b) in zip(lhs.topMuscles, rhs.topMuscles) {
                guard a.muscle == b.muscle, a.volume == b.volume else { return false }
            }
            return true
        }
    }

    /// 通知タイトル。煽らない一定文。
    public static func title(for report: Report) -> String {
        return "今週のトレーニングまとめ"
    }

    /// 通知本文。「実施日数 / 総ボリューム / 上位部位 1 件」をまとめる。
    /// 実施なしの週は「今週は休養週でした。来週もマイペースで。」。
    public static func body(for report: Report, weightUnit: WeightUnit = .kg) -> String {
        if report.sessionDays == 0 {
            return "今週は休養週でした。来週もマイペースで。"
        }
        let volumeString = WeightFormatter.volume(kilograms: report.totalVolume, in: weightUnit)
        if let top = report.topMuscles.first {
            return "\(report.sessionDays) 日 / 総ボリューム \(volumeString) ・ 重点: \(top.muscle.displayName)"
        } else {
            return "\(report.sessionDays) 日 / 総ボリューム \(volumeString)"
        }
    }

    /// `Analytics` 出力から `Report` を組み立てるヘルパー。
    public static func makeReport(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> Report {
        let range = Analytics.currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let sessionDays = Analytics.weeklySessionDays(sessions: sessions, in: range, calendar: calendar)
        let byMuscle = Analytics.volumeByMuscleGroup(sets: sets, in: range)
        let totalVolume = byMuscle.values.reduce(0, +)
        let top =
            byMuscle
            .map { (muscle: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
        return Report(
            sessionDays: sessionDays,
            totalVolume: totalVolume,
            topMuscles: Array(top.prefix(3))
        )
    }
}

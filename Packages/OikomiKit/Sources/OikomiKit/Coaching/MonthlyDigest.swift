import Foundation

/// 月次振り返りの素材となる構造化ダイジェスト。
public struct MonthlyTrainingDigest: Sendable, Hashable {
    public let yearMonth: String
    public let sessionCount: Int
    public let trainingDays: Int
    public let totalVolumeKg: Double
    public let muscleSetCounts: [MonthlyMuscleVolume]
    public let underTrainedMuscles: [MuscleGroup]
    public let personalRecords: [MonthlyPR]
    public let readiness: MonthlyReadiness?
    public let bodyPhase: BodyPhaseResult?

    public var isSubstantial: Bool { sessionCount >= 4 }

    public init(
        yearMonth: String, sessionCount: Int, trainingDays: Int, totalVolumeKg: Double,
        muscleSetCounts: [MonthlyMuscleVolume], underTrainedMuscles: [MuscleGroup],
        personalRecords: [MonthlyPR], readiness: MonthlyReadiness?, bodyPhase: BodyPhaseResult?
    ) {
        self.yearMonth = yearMonth
        self.sessionCount = sessionCount
        self.trainingDays = trainingDays
        self.totalVolumeKg = totalVolumeKg
        self.muscleSetCounts = muscleSetCounts
        self.underTrainedMuscles = underTrainedMuscles
        self.personalRecords = personalRecords
        self.readiness = readiness
        self.bodyPhase = bodyPhase
    }
}

public struct MonthlyMuscleVolume: Sendable, Hashable {
    public let muscle: MuscleGroup
    public let sets: Int
    public init(muscle: MuscleGroup, sets: Int) {
        self.muscle = muscle
        self.sets = sets
    }
}

public struct MonthlyPR: Sendable, Hashable {
    public let exerciseName: String
    public let weight: Double
    public let reps: Int
    public let estimated1RM: Double
    public init(exerciseName: String, weight: Double, reps: Int, estimated1RM: Double) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.estimated1RM = estimated1RM
    }
}

public struct MonthlyReadiness: Sendable, Hashable {
    public let average: Int
    public let lowDays: Int
    public let normalDays: Int
    public let highDays: Int
    public init(average: Int, lowDays: Int, normalDays: Int, highDays: Int) {
        self.average = average
        self.lowDays = lowDays
        self.normalDays = normalDays
        self.highDays = highDays
    }
}

public enum MonthlyDigest {
    /// 指定年月（"yyyy-MM"）のデータからダイジェストを構築。完了セッションが無ければ nil。
    /// bodyPhase は端末依存（HealthKit）のため呼び出し側で取得して渡す。
    public static func build(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        snapshots: [HealthSnapshot],
        yearMonth: String,
        profile: TrainingProfile = .default,
        bodyPhase: BodyPhaseResult? = nil,
        calendar: Calendar = .current
    ) -> MonthlyTrainingDigest? {
        guard let range = monthRange(yearMonth: yearMonth, calendar: calendar) else { return nil }

        let monthSessions = sessions.filter { $0.endedAt != nil && range.contains($0.startedAt) }
        guard !monthSessions.isEmpty else { return nil }

        let trainingDays = Set(monthSessions.map { calendar.startOfDay(for: $0.startedAt) }).count

        let workingSets = sets.filter {
            range.contains($0.completedAt) && !$0.isWarmup && $0.isCompleted
        }
        let totalVolume = workingSets.reduce(0.0) { acc, set in
            guard let w = set.weight, let r = set.reps else { return acc }
            return acc + w * Double(r)
        }

        let counts = Analytics.setCountByMuscleGroup(sets: sets, in: range)
        let muscleSetCounts =
            counts
            .map { MonthlyMuscleVolume(muscle: $0.key, sets: $0.value) }
            .sorted { $0.sets > $1.sets }

        // 全 case を走査する。まったく鍛えなかった部位（counts に現れない）も
        // 「放置」として検出するため（setCountByMuscleGroup は出現した部位しか返さない）。
        let weeks = max(1.0, weeksInMonth(range: range, calendar: calendar))
        let underTrained = MuscleGroup.allCases.compactMap { muscle -> MuscleGroup? in
            let target = muscle.weeklySetTarget(for: profile)
            guard target.isTracked, target.mev > 0 else { return nil }
            let weeklyAverage = Double(counts[muscle] ?? 0) / weeks
            return weeklyAverage < Double(target.mev) ? muscle : nil
        }

        let monthPRs =
            records
            .filter { range.contains($0.achievedAt) }
            .sorted { $0.estimated1RM > $1.estimated1RM }
            .compactMap { pr -> MonthlyPR? in
                guard let exercise = pr.exercise else { return nil }
                return MonthlyPR(
                    exerciseName: exercise.name, weight: pr.weight,
                    reps: pr.reps, estimated1RM: pr.estimated1RM)
            }

        let scores =
            snapshots
            .filter { range.contains($0.date) }
            .compactMap { $0.readinessScore }
        let readiness: MonthlyReadiness?
        if scores.isEmpty {
            readiness = nil
        } else {
            let average = scores.reduce(0, +) / scores.count
            let low = scores.filter { ReadinessScore.band(for: $0) == .low }.count
            let normal = scores.filter { ReadinessScore.band(for: $0) == .normal }.count
            let high = scores.filter { ReadinessScore.band(for: $0) == .high }.count
            readiness = MonthlyReadiness(average: average, lowDays: low, normalDays: normal, highDays: high)
        }

        return MonthlyTrainingDigest(
            yearMonth: yearMonth,
            sessionCount: monthSessions.count,
            trainingDays: trainingDays,
            totalVolumeKg: totalVolume,
            muscleSetCounts: muscleSetCounts,
            underTrainedMuscles: underTrained,
            personalRecords: monthPRs,
            readiness: readiness,
            bodyPhase: bodyPhase
        )
    }

    /// "yyyy-MM" → その月全体を含む ClosedRange<Date>。不正な文字列は nil。
    static func monthRange(yearMonth: String, calendar: Calendar) -> ClosedRange<Date>? {
        let parts = yearMonth.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return nil }
        var startComps = DateComponents()
        startComps.year = year
        startComps.month = month
        startComps.day = 1
        guard let start = calendar.date(from: startComps),
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start),
            let end = calendar.date(byAdding: .second, value: -1, to: nextMonth)
        else { return nil }
        return start...end
    }

    private static func weeksInMonth(range: ClosedRange<Date>, calendar: Calendar) -> Double {
        // upperBound は「月末 23:59:59」なので、翌月頭（= upperBound + 1秒）まで数えて
        // 31日月で正しく 31 日になるようにする（off-by-one 回避）。
        guard let nextMonth = calendar.date(byAdding: .second, value: 1, to: range.upperBound) else {
            return 4.0
        }
        let days = calendar.dateComponents([.day], from: range.lowerBound, to: nextMonth).day ?? 30
        return Double(days) / 7.0
    }
}

import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("Analytics")
@MainActor
struct AnalyticsTests {

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2  // 月曜
        return cal
    }()

    // MARK: - weeklySessionDays

    @Test("weeklySessionDays: 完了済みセッションがゼロなら0")
    func weekDaysEmpty() {
        let range = Analytics.currentWeekRange(calendar: Self.calendar)
        let result = Analytics.weeklySessionDays(sessions: [], in: range, calendar: Self.calendar)
        #expect(result == 0)
    }

    @Test("weeklySessionDays: 同日複数セッションは 1 日にまとめる")
    func weekDaysDeduplicatesSameDay() {
        let cal = Self.calendar
        let now = Date()
        let range = Analytics.currentWeekRange(referenceDate: now, calendar: cal)
        // 今日 2 セッション
        let morning = cal.startOfDay(for: now)
        let evening = cal.date(byAdding: .hour, value: 18, to: morning)!
        let s1 = WorkoutSession(startedAt: morning)
        s1.endedAt = morning
        let s2 = WorkoutSession(startedAt: evening)
        s2.endedAt = evening
        let result = Analytics.weeklySessionDays(sessions: [s1, s2], in: range, calendar: cal)
        #expect(result == 1)
    }

    @Test("weeklySessionDays: 今週月・水・金で3")
    func weekDaysThreeDistinctDays() {
        let cal = Self.calendar
        let now = Date()
        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)!.start
        let range = Analytics.currentWeekRange(referenceDate: now, calendar: cal)
        let sessions = [0, 2, 4].map { offset -> WorkoutSession in
            let date = cal.date(byAdding: .day, value: offset, to: weekStart)!
            let s = WorkoutSession(startedAt: date)
            s.endedAt = date
            return s
        }
        let result = Analytics.weeklySessionDays(sessions: sessions, in: range, calendar: cal)
        #expect(result == 3)
    }

    @Test("weeklySessionDays: 範囲外は集計しない")
    func weekDaysIgnoresOutsideRange() {
        let cal = Self.calendar
        let now = Date()
        let range = Analytics.currentWeekRange(referenceDate: now, calendar: cal)
        let lastWeek = cal.date(byAdding: .day, value: -10, to: now)!
        let s = WorkoutSession(startedAt: lastWeek)
        s.endedAt = lastWeek
        let result = Analytics.weeklySessionDays(sessions: [s], in: range, calendar: cal)
        #expect(result == 0)
    }

    @Test("weeklySessionDays: 未完了セッションは無視")
    func weekDaysIgnoresInProgress() {
        let cal = Self.calendar
        let range = Analytics.currentWeekRange(calendar: cal)
        let s = WorkoutSession(startedAt: Date())  // endedAt = nil
        let result = Analytics.weeklySessionDays(sessions: [s], in: range, calendar: cal)
        #expect(result == 0)
    }

    // MARK: - consecutiveActiveWeeks

    @Test("consecutiveActiveWeeks: 空配列なら0")
    func consecutiveWeeksEmpty() {
        let result = Analytics.consecutiveActiveWeeks(sessions: [], calendar: Self.calendar)
        #expect(result == 0)
    }

    @Test("consecutiveActiveWeeks: 今週のみ活動なら1")
    func consecutiveWeeksThisOnly() {
        let s = WorkoutSession(startedAt: Date())
        s.endedAt = Date()
        let result = Analytics.consecutiveActiveWeeks(sessions: [s], calendar: Self.calendar)
        #expect(result == 1)
    }

    @Test("consecutiveActiveWeeks: 今週未実施でも先週あれば1（休養日と同じ哲学）")
    func consecutiveWeeksLastWeekOnly() {
        let cal = Self.calendar
        let now = Date()
        let lastWeek = cal.date(byAdding: .day, value: -7, to: now)!
        let s = WorkoutSession(startedAt: lastWeek)
        s.endedAt = lastWeek
        let result = Analytics.consecutiveActiveWeeks(sessions: [s], referenceDate: now, calendar: cal)
        #expect(result == 1)
    }

    @Test("consecutiveActiveWeeks: 3週連続活動なら3")
    func consecutiveWeeksThree() {
        let cal = Self.calendar
        let now = Date()
        let sessions = (0...2).map { offset -> WorkoutSession in
            let date = cal.date(byAdding: .weekOfYear, value: -offset, to: now)!
            let s = WorkoutSession(startedAt: date)
            s.endedAt = date
            return s
        }
        let result = Analytics.consecutiveActiveWeeks(
            sessions: sessions, referenceDate: now, calendar: cal)
        #expect(result == 3)
    }

    @Test("consecutiveActiveWeeks: 2週前で途切れていれば 0（今週も先週も未実施）")
    func consecutiveWeeksBroken() {
        let cal = Self.calendar
        let now = Date()
        let twoWeeksAgo = cal.date(byAdding: .weekOfYear, value: -2, to: now)!
        let s = WorkoutSession(startedAt: twoWeeksAgo)
        s.endedAt = twoWeeksAgo
        let result = Analytics.consecutiveActiveWeeks(
            sessions: [s], referenceDate: now, calendar: cal)
        #expect(result == 0)
    }

    @Test("consecutiveActiveWeeks: 真ん中の週が抜けていれば streak は最新側のみ")
    func consecutiveWeeksGap() {
        let cal = Self.calendar
        let now = Date()
        // 今週 + 2 週前（先週なし）→ 今週は連続 1
        let thisWeek = now
        let twoWeeksAgo = cal.date(byAdding: .weekOfYear, value: -2, to: now)!
        let s1 = WorkoutSession(startedAt: thisWeek)
        s1.endedAt = thisWeek
        let s2 = WorkoutSession(startedAt: twoWeeksAgo)
        s2.endedAt = twoWeeksAgo
        let result = Analytics.consecutiveActiveWeeks(
            sessions: [s1, s2], referenceDate: now, calendar: cal)
        #expect(result == 1)
    }

    @Test("consecutiveActiveWeeks: 未完了セッションは無視")
    func consecutiveWeeksIgnoresInProgress() {
        let s = WorkoutSession(startedAt: Date())  // endedAt = nil
        let result = Analytics.consecutiveActiveWeeks(sessions: [s], calendar: Self.calendar)
        #expect(result == 0)
    }

    // MARK: - volumeByMuscleGroup

    @Test("volumeByMuscleGroup: ベンチプレス80kg×8レップは chest/triceps/shoulders に 640 加算")
    func volumeByGroup() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let set = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 80, reps: 8)

        let range = set.completedAt.addingTimeInterval(-60)...set.completedAt.addingTimeInterval(60)
        let volume = Analytics.volumeByMuscleGroup(sets: [set], in: range)
        #expect(volume[.chest] == 640)
        #expect(volume[.triceps] == 640)
        #expect(volume[.shoulders] == 640)
    }

    @Test("volumeByMuscleGroup: 範囲外のセットは集計しない")
    func volumeRespectsRange() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let set = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 100, reps: 5)

        // 1時間以上前の範囲を指定 → 集計対象外
        let oldEnd = set.completedAt.addingTimeInterval(-3600)
        let oldStart = oldEnd.addingTimeInterval(-3600)
        let volume = Analytics.volumeByMuscleGroup(sets: [set], in: oldStart...oldEnd)
        #expect(volume.isEmpty)
    }

    // MARK: - setCountByMuscleGroup

    @Test("setCountByMuscleGroup: ベンチ1セットで chest/triceps/shoulders に +1")
    func setCountSingleSetMultiMuscle() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let set = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 80, reps: 8)

        let range = set.completedAt.addingTimeInterval(-60)...set.completedAt.addingTimeInterval(60)
        let counts = Analytics.setCountByMuscleGroup(sets: [set], in: range)
        #expect(counts[.chest] == 1)
        #expect(counts[.triceps] == 1)
        #expect(counts[.shoulders] == 1)
    }

    @Test("setCountByMuscleGroup: warmup セットは集計しない")
    func setCountExcludesWarmup() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let warm = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 40, reps: 10, isWarmup: true)
        let work = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 80, reps: 8)

        let range = warm.completedAt.addingTimeInterval(-60)...work.completedAt.addingTimeInterval(60)
        let counts = Analytics.setCountByMuscleGroup(sets: [warm, work], in: range)
        #expect(counts[.chest] == 1)
    }

    @Test("setCountByMuscleGroup: 計画のみ（isCompleted=false）は集計しない")
    func setCountExcludesPlanned() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let planned = try WorkoutSessionRepository(context: context)
            .addPlannedSet(to: session, exercise: bench, weight: 80, reps: 8)

        let range = planned.completedAt.addingTimeInterval(-60)...planned.completedAt.addingTimeInterval(60)
        let counts = Analytics.setCountByMuscleGroup(sets: [planned], in: range)
        #expect(counts.isEmpty)
    }

    @Test("setCountByMuscleGroup: 範囲外のセットは集計しない")
    func setCountRespectsRange() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!

        let session = try WorkoutSessionRepository(context: context).startSession()
        let set = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 80, reps: 8)

        let oldEnd = set.completedAt.addingTimeInterval(-3600)
        let oldStart = oldEnd.addingTimeInterval(-3600)
        let counts = Analytics.setCountByMuscleGroup(sets: [set], in: oldStart...oldEnd)
        #expect(counts.isEmpty)
    }

    // MARK: - weeklySetCountReport

    @Test("weeklySetCountReport: fullBody は含まない")
    func weeklySetCountExcludesFullBody() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())

        let report = Analytics.weeklySetCountReport(
            sets: allSets,
            calendar: Self.calendar
        )
        #expect(!report.contains { $0.muscle == .fullBody })
    }

    @Test("weeklySetCountReport: count 0 → insufficient")
    func weeklySetCountInsufficient() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())

        let report = Analytics.weeklySetCountReport(
            sets: allSets,
            calendar: Self.calendar
        )
        // セッションがゼロなら chest など MEV > 0 の部位はすべて insufficient
        let chest = report.first { $0.muscle == .chest }
        #expect(chest?.status == .insufficient)
    }

    @Test("weeklySetCountReport: MAV 超過で excessive")
    func weeklySetCountExcessive() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()

        // chest の MAV=22 を超える 25 セット
        for _ in 0..<25 {
            try repo.addSet(to: session, exercise: bench, weight: 60, reps: 8)
        }

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let report = Analytics.weeklySetCountReport(sets: allSets, calendar: Self.calendar)
        let chest = report.first { $0.muscle == .chest }
        #expect(chest?.count == 25)
        #expect(chest?.status == .excessive)
    }

    @Test("weeklySetCountReport: MEV〜MAV レンジ内で optimal")
    func weeklySetCountOptimal() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()

        // chest MEV=10 MAV=22 のレンジ内 (15)
        for _ in 0..<15 {
            try repo.addSet(to: session, exercise: bench, weight: 60, reps: 8)
        }

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let report = Analytics.weeklySetCountReport(sets: allSets, calendar: Self.calendar)
        let chest = report.first { $0.muscle == .chest }
        #expect(chest?.count == 15)
        #expect(chest?.status == .optimal)
    }

    @Test("weeklySetCountReport: profile で MEV/MAV が個人化される")
    func reportPersonalizesTarget() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()
        // chest を 24 セット（中級 MAV22 → 過多、上級 MAV26 → 適正）
        for _ in 0..<24 { try repo.addSet(to: session, exercise: bench, weight: 60, reps: 8) }
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())

        let mid = Analytics.weeklySetCountReport(sets: allSets, calendar: Self.calendar)
            .first { $0.muscle == .chest }
        let adv = Analytics.weeklySetCountReport(
            sets: allSets,
            profile: TrainingProfile(experience: .advanced, goal: .hypertrophy),
            calendar: Self.calendar
        ).first { $0.muscle == .chest }

        #expect(mid?.status == .excessive)  // 24 > 22
        #expect(adv?.status == .optimal)  // 10 <= 24 <= 26
    }

    @Test("weeklySetCountReport: count 降順ソート")
    func weeklySetCountSortedDescending() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()

        for _ in 0..<5 {
            try repo.addSet(to: session, exercise: bench, weight: 60, reps: 8)
        }

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let report = Analytics.weeklySetCountReport(sets: allSets, calendar: Self.calendar)
        // 全部位が出る前提で、counts が降順
        let counts = report.map(\.count)
        #expect(counts == counts.sorted(by: >))
    }

    // MARK: - currentWeekRange

    // MARK: - volumeAdvice

    @Test("volumeAdvice: 今週が先週比150%超で warning が出る")
    func volumeAdviceOverwork() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let session = try WorkoutSessionRepository(context: context).startSession()

        let cal = Self.calendar
        let now = Date()
        // -7 だとちょうど 1週間前で境界条件、月曜起算で先週レンジは [-7..-1] 日前。
        // テストの再現性のため、確実に lastWeekRange に入る -3 〜 -1 日前を選ぶ。
        // ただし「先週」を表現するため、今週月曜より前の絶対時刻を使う必要がある。
        // currentWeekRange の lowerBound から -3 日 = 先週の木曜あたり。
        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let lastWeek = cal.date(byAdding: .day, value: -3, to: weekStart)!
        let thisWeek = now

        // 先週: 80kg × 8 × 1セット = 640
        let s1 = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 80, reps: 8)
        s1.completedAt = lastWeek
        // 今週: 80kg × 8 × 3セット = 1920 → 先週比 300%
        for _ in 0..<3 {
            let s = try WorkoutSessionRepository(context: context)
                .addSet(to: session, exercise: bench, weight: 80, reps: 8)
            s.completedAt = thisWeek
        }

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.volumeAdvice(from: allSets, referenceDate: now, calendar: cal)

        let warnings = advices.filter { $0.severity == .warning && $0.title.contains("オーバーワーク") }
        #expect(!warnings.isEmpty)
        // ベンチプレスは chest / triceps / shoulders に該当。順序は dict 由来で非決定的だが、いずれかは出る。
        let bodyParts = ["胸", "上腕三頭筋", "肩"]
        let hit = warnings.contains { advice in
            bodyParts.contains { advice.message.contains($0) }
        }
        #expect(hit)
    }

    @Test("volumeAdvice: 先週多くて今週少ないと不足警告")
    func volumeAdviceUndertraining() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let session = try WorkoutSessionRepository(context: context).startSession()

        let cal = Self.calendar
        let now = Date()
        // -7 だとちょうど 1週間前で境界条件、月曜起算で先週レンジは [-7..-1] 日前。
        // テストの再現性のため、確実に lastWeekRange に入る -3 〜 -1 日前を選ぶ。
        // ただし「先週」を表現するため、今週月曜より前の絶対時刻を使う必要がある。
        // currentWeekRange の lowerBound から -3 日 = 先週の木曜あたり。
        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let lastWeek = cal.date(byAdding: .day, value: -3, to: weekStart)!

        // 先週: 80kg × 8 × 4セット = 2560
        for _ in 0..<4 {
            let s = try WorkoutSessionRepository(context: context)
                .addSet(to: session, exercise: bench, weight: 80, reps: 8)
            s.completedAt = lastWeek
        }
        // 今週: 0
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.volumeAdvice(from: allSets, referenceDate: now, calendar: cal)
        // last=2560, this=0, 0/2560 < 0.5 → 不足警告のはずだが、guard last > 0 後に ratio < 0.5 で発火
        let undertraining = advices.first { $0.title.contains("不足") }
        #expect(undertraining != nil)
    }

    @Test("volumeAdvice: 極小ボリュームは無視（500 未満）")
    func volumeAdviceIgnoresLowVolume() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let session = try WorkoutSessionRepository(context: context).startSession()

        // 今週: 20kg × 5 = 100 だけ
        let s = try WorkoutSessionRepository(context: context)
            .addSet(to: session, exercise: bench, weight: 20, reps: 5)
        _ = s

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.volumeAdvice(from: allSets, calendar: Self.calendar)
        #expect(advices.isEmpty)
    }

    // MARK: - deloadAdvice

    @Test("deloadAdvice: 連続5日トレで警告")
    func deloadConsecutive5Days() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        let cal = Self.calendar
        let now = Date()

        // 直近 5 日（今日含む）に各 1 セッション、すべて完了済み
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -offset, to: now)!
            let s = try repo.startSession(at: date)
            try repo.addSet(to: s, exercise: bench, weight: 60, reps: 5, completedAt: date)
            s.endedAt = date
        }

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let sets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.deloadAdvice(sessions: sessions, sets: sets, referenceDate: now, calendar: cal)

        #expect(advices.contains { $0.title.contains("休息") })
    }

    @Test("deloadAdvice: 1日トレだけなら警告出さない")
    func deloadSingleDay() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        let s = try repo.startSession()
        try repo.addSet(to: s, exercise: bench, weight: 60, reps: 5)
        s.endedAt = Date()

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let sets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.deloadAdvice(sessions: sessions, sets: sets, calendar: Self.calendar)

        #expect(!advices.contains { $0.title.contains("休息") })
    }

    // MARK: - prPredictions (線形回帰)

    @Test("prPredictions: 5 セッション以上の明確な上昇トレンドで予測 advice を出す")
    func prPredictionRisingTrend() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        // 80 → 84kg まで 1kg ずつ漸増（計 5 セッション）。reps は 8 固定。
        // estimated1RM は 101.33 → 106.4 と直線的に上昇するので R² ≈ 1 で発火する。
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<5 {
            let weight = Double(80 + offset)
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: weight, reps: 8, completedAt: date)
            session.endedAt = date
        }

        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let predictions = Analytics.prPredictions(sets: allSets, records: records)

        #expect(!predictions.isEmpty)
        #expect(predictions.first?.title.contains("PR") == true)
    }

    @Test("prPredictions: 横ばいトレンドでは予測を出さない")
    func prPredictionFlatTrend() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        // 5 セッションすべて同じ重量・レップ → slope ≈ 0、予測値 ≤ PR
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8, completedAt: date)
            session.endedAt = date
        }

        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let predictions = Analytics.prPredictions(sets: allSets, records: records)

        #expect(predictions.isEmpty)
    }

    @Test("prPredictions: サンプル不足（4 セッション）では予測を出さない")
    func prPredictionInsufficientSamples() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        let cal = Self.calendar
        let now = Date()
        for offset in 0..<4 {
            let weight = Double(80 + offset)
            let date = cal.date(byAdding: .day, value: -(3 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: weight, reps: 8, completedAt: date)
            session.endedAt = date
        }

        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let predictions = Analytics.prPredictions(sets: allSets, records: records)

        #expect(predictions.isEmpty)
    }

    @Test("prPredictions: 予測メッセージに信頼レンジ（±）が含まれる")
    func prPredictionShowsConfidenceRange() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<5 {
            let weight = Double(80 + offset)
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: weight, reps: 8, completedAt: date)
            session.endedAt = date
        }
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let predictions = Analytics.prPredictions(sets: allSets, records: records)
        #expect(predictions.first?.message.contains("±") == true)
    }

    @Test("linearRegression: 完全直線で R² == 1、slope と intercept が一致")
    func linearRegressionPerfectFit() {
        let points: [(x: Double, y: Double)] = (0..<5).map { (Double($0), Double($0) * 2 + 3) }
        let fit = Analytics.linearRegression(points)
        #expect(fit != nil)
        #expect(abs((fit?.slope ?? 0) - 2) < 1e-9)
        #expect(abs((fit?.intercept ?? 0) - 3) < 1e-9)
        #expect(abs((fit?.r2 ?? 0) - 1) < 1e-9)
    }

    @Test("predictionMargin: 完全直線なら残差マージン 0")
    func predictionMarginPerfectFit() {
        let points: [(x: Double, y: Double)] = (0..<5).map { (Double($0), Double($0) * 2 + 3) }
        let fit = Analytics.linearRegression(points)!
        #expect(Analytics.predictionMargin(points: points, fit: fit) == 0)
    }

    @Test("predictionMargin: ばらつきのある系列は正の残差マージン")
    func predictionMarginNoisy() {
        // 直線から外れた点を含む → RSE > 0
        let points: [(x: Double, y: Double)] = [(0, 0), (1, 2), (2, 1), (3, 5), (4, 3)]
        let fit = Analytics.linearRegression(points)!
        #expect(Analytics.predictionMargin(points: points, fit: fit) > 0)
    }

    @Test("predictionMargin: 点が 3 未満なら 0")
    func predictionMarginTooFewPoints() {
        let points: [(x: Double, y: Double)] = [(0, 1), (1, 3)]
        let fit = Analytics.linearRegression(points)!
        #expect(Analytics.predictionMargin(points: points, fit: fit) == 0)
    }

    // MARK: - plateauAdvice

    @Test("plateauAdvice: 横ばい 5 セッションで停滞 advice を出す")
    func plateauFlat() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8, completedAt: date)
            session.endedAt = date
        }
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.plateauAdvice(sets: allSets, records: records)
        #expect(advices.contains { $0.title.contains("停滞") })
    }

    @Test("plateauAdvice: 明確な上昇トレンドでは停滞を出さない")
    func plateauRisingNone() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<5 {
            let weight = Double(80 + offset)
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: weight, reps: 8, completedAt: date)
            session.endedAt = date
        }
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.plateauAdvice(sets: allSets, records: records)
        #expect(advices.isEmpty)
    }

    @Test("plateauAdvice: サンプル不足では出さない")
    func plateauInsufficient() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<4 {
            let date = cal.date(byAdding: .day, value: -(3 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8, completedAt: date)
            session.endedAt = date
        }
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.plateauAdvice(sets: allSets, records: records)
        #expect(advices.isEmpty)
    }

    // MARK: - deloadAdvice × readiness

    @Test("deloadAdvice: readiness が low なら回復優先 advice を含む")
    func deloadIncludesReadinessLow() {
        let r = ReadinessScore(value: 30, band: .low, confidence: .high, hrvZ: -1.5, usedSignals: [.hrv])
        let advices = Analytics.deloadAdvice(
            sessions: [], sets: [], readiness: r, calendar: Self.calendar)
        #expect(advices.contains { $0.title.contains("回復優先") })
    }

    @Test("deloadAdvice: readiness が nil なら回復優先 advice は出ない")
    func deloadNoReadinessWhenNil() {
        let advices = Analytics.deloadAdvice(
            sessions: [], sets: [], readiness: nil, calendar: Self.calendar)
        #expect(!advices.contains { $0.title.contains("回復優先") })
    }

    @Test("currentWeekRange: 月曜開始の7日間 range")
    func weekRangeIsSevenDays() {
        let range = Analytics.currentWeekRange(calendar: Self.calendar)
        let cal = Self.calendar
        let startWeekday = cal.component(.weekday, from: range.lowerBound)
        #expect(startWeekday == 2)  // 月曜
        let duration = range.upperBound.timeIntervalSince(range.lowerBound)
        #expect(duration > 6 * 24 * 3600)
        #expect(duration < 7 * 24 * 3600)
    }

    // MARK: - readinessAdvice

    @Test("readinessAdvice: low band で warning を返す")
    func readinessAdviceLow() {
        let r = ReadinessScore(value: 30, band: .low, confidence: .high, hrvZ: -1.5, usedSignals: [.hrv])
        let advice = Analytics.readinessAdvice(readiness: r)
        #expect(advice?.severity == .warning)
    }

    @Test("readinessAdvice: high band で success を返す")
    func readinessAdviceHigh() {
        let r = ReadinessScore(value: 85, band: .high, confidence: .high, hrvZ: 1.5, usedSignals: [.hrv])
        let advice = Analytics.readinessAdvice(readiness: r)
        #expect(advice?.severity == .success)
    }

    @Test("readinessAdvice: normal / nil では advice なし")
    func readinessAdviceNormalNil() {
        let r = ReadinessScore(value: 60, band: .normal, confidence: .high, hrvZ: 0, usedSignals: [.hrv])
        #expect(Analytics.readinessAdvice(readiness: r) == nil)
        #expect(Analytics.readinessAdvice(readiness: nil) == nil)
    }

    // MARK: - autoregulationAdvice

    /// 同一種目で指定 RPE のセットを N セッション分作るヘルパー。
    private func makeRPESessions(
        context: ModelContext, exercise: Exercise, weight: Double, rpe: Double, sessions: Int
    ) throws {
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<sessions {
            let date = cal.date(byAdding: .day, value: -(sessions - offset) * 2, to: now)!
            let s = try repo.startSession(at: date)
            let set = try repo.addSet(to: s, exercise: exercise, weight: weight, reps: 8, completedAt: date)
            set.rpe = rpe
            s.endedAt = date
        }
    }

    @Test("autoregulationAdvice: 直近2回とも RPE9 以上なら減量を提案")
    func autoregHighRPEDecrease() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 9.5, sessions: 2)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.contains { $0.title.contains("下げ") })
    }

    @Test("autoregulationAdvice: 直近2回とも RPE6 以下なら増量を提案")
    func autoregLowRPEIncrease() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 6.0, sessions: 2)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.contains { $0.title.contains("上げ") || $0.title.contains("増やし") })
    }

    @Test("autoregulationAdvice: RPE が適正（8前後）なら提案なし")
    func autoregMidRPENone() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 7.5, sessions: 2)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.isEmpty)
    }

    @Test("autoregulationAdvice: RPE 未入力なら提案なし")
    func autoregNoRPENone() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<2 {
            let date = cal.date(byAdding: .day, value: -(2 - offset) * 2, to: now)!
            let s = try repo.startSession(at: date)
            try repo.addSet(to: s, exercise: bench, weight: 100, reps: 8, completedAt: date)  // rpe nil
            s.endedAt = date
        }
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.isEmpty)
    }

    @Test("autoregulationAdvice: 1 セッションだけならデータ不足で提案なし")
    func autoregSingleSessionNone() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 9.5, sessions: 1)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.isEmpty)
    }

    // MARK: - HealthSnapshot.readinessScore（予約フィールド）

    @Test("HealthSnapshot: readinessScore は既定 nil・代入で保持される")
    func healthSnapshotReadinessField() {
        let snap = HealthSnapshot(date: Date())
        #expect(snap.readinessScore == nil)
        snap.readinessScore = 72
        #expect(snap.readinessScore == 72)
    }

    // MARK: - combinedCoachingAdvice（統合パイプライン）

    @Test("combinedCoachingAdvice: 警告は好調メッセージより先に並ぶ")
    func combinedWarningsBeforeSuccess() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        // 直近5日連続トレ → ディロード警告が出る
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -offset, to: now)!
            let s = try repo.startSession(at: date)
            try repo.addSet(to: s, exercise: bench, weight: 60, reps: 5, completedAt: date)
            s.endedAt = date
        }
        // readiness high → 好調(success)
        let r = ReadinessScore(
            value: 85, band: .high, confidence: .high, hrvZ: 1.5, usedSignals: [.hrv])
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let sets = try context.fetch(FetchDescriptor<SetRecord>())
        // limit: .max で全件取得し「警告が好調より前」という順序性を検証する。
        // （デフォルト limit:3 だと、週境界に依存して警告が3件以上出た日に success が
        //   キャップ外へ押し出され、日付依存でフレーキーになるため）
        let advices = Analytics.combinedCoachingAdvice(
            sessions: sessions, sets: sets, records: [], readiness: r,
            limit: .max, referenceDate: now, calendar: cal)

        #expect(advices.first?.severity == .warning)
        #expect(advices.contains { $0.severity == .success })
        // 最後の警告は最初の好調より前に並ぶ
        let lastWarning = advices.lastIndex { $0.severity == .warning }
        let firstSuccess = advices.firstIndex { $0.severity == .success }
        if let lastWarning, let firstSuccess {
            #expect(lastWarning < firstSuccess)
        }
    }

    @Test("combinedCoachingAdvice: 同一種目で PR予測と停滞は同時に出ない")
    func combinedPRPlateauExclusive() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        // 横ばい 5 セッション → 停滞のみ（PR予測は排他で出ない）
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8, completedAt: date)
            session.endedAt = date
        }
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let sets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.combinedCoachingAdvice(
            sessions: [], sets: sets, records: records, readiness: nil,
            limit: 10, referenceDate: now, calendar: cal)

        #expect(advices.contains { $0.title.contains("停滞") })
        #expect(!advices.contains { $0.title.contains("PR") })
    }

    @Test("combinedCoachingAdvice: 大きい limit で全件返す（3件キャップを超える）")
    func combinedLimitReturnsAll() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        // 連続5日 + 横ばい → 休息警告 / 停滞 / 「新しい部位」など4件以上のアドバイスが出る状況
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -offset, to: now)!
            let s = try repo.startSession(at: date)
            try repo.addSet(to: s, exercise: bench, weight: 60, reps: 5, completedAt: date)
            s.endedAt = date
        }
        let r = ReadinessScore(
            value: 85, band: .high, confidence: .high, hrvZ: 1.5, usedSignals: [.hrv])
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let sets = try context.fetch(FetchDescriptor<SetRecord>())
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())

        let capped = Analytics.combinedCoachingAdvice(
            sessions: sessions, sets: sets, records: records, readiness: r,
            limit: 3, referenceDate: now, calendar: cal)
        let full = Analytics.combinedCoachingAdvice(
            sessions: sessions, sets: sets, records: records, readiness: r,
            limit: .max, referenceDate: now, calendar: cal)

        #expect(capped.count == 3)
        #expect(full.count > 3)
        // キャップ版は全件の先頭3件と同じ並び（id は毎回採番されるのでタイトル列で比較）
        #expect(capped.map(\.title) == full.prefix(3).map(\.title))
    }

    @Test("combinedCoachingAdvice: 漸進性過負荷（不足）が統合される")
    func combinedIncludesProgressiveOverload() {
        let cal = Self.calendar
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 31, hour: 12))!
        // 空セット → 全 mev>0 部位が MEV 未満 → MEV未達 warning
        let advices = Analytics.combinedCoachingAdvice(
            sessions: [], sets: [], records: [], readiness: nil,
            limit: 20, referenceDate: now, calendar: cal)
        #expect(advices.contains { $0.title == "MEV未達" })
    }

    @Test("combinedCoachingAdvice: profile が漸進判定に反映される（end-to-end）")
    func combinedProfileAffectsProgressive() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let s = try repo.startSession()
        // chest 23 セット: 中級 MAV22 を超える（漸進候補外）が上級 MAV26 は未達（漸進候補）。
        for _ in 0..<23 { try repo.addSet(to: s, exercise: bench, weight: 60, reps: 8) }
        let sets = try context.fetch(FetchDescriptor<SetRecord>())
        let now = Date()

        let mid = Analytics.combinedCoachingAdvice(
            sessions: [], sets: sets, records: [], readiness: nil,
            limit: 20, referenceDate: now, calendar: Self.calendar, profile: .default)
        let adv = Analytics.combinedCoachingAdvice(
            sessions: [], sets: sets, records: [], readiness: nil,
            limit: 20, referenceDate: now, calendar: Self.calendar,
            profile: TrainingProfile(experience: .advanced, goal: .hypertrophy))

        #expect(!mid.contains { $0.title == "漸進的に増やす" && $0.message.contains("胸") })
        #expect(adv.contains { $0.title == "漸進的に増やす" && $0.message.contains("胸") })
    }

    @Test("combinedCoachingAdvice: 回復済み部位の提案が統合される")
    func combinedIncludesRecovery() {
        let cal = Self.calendar
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 31, hour: 12))!
        // biceps を 48h 前に 3 セット → 回復済（base 36h）・2日前 → recoveryAdvice 発火
        let ex = Exercise(name: "カール", muscleGroups: [.biceps])
        let bicepsSets = (0..<3).map { _ in
            SetRecord(
                exercise: ex, weight: 20, reps: 10,
                completedAt: now.addingTimeInterval(-48 * 3600))
        }
        let advices = Analytics.combinedCoachingAdvice(
            sessions: [], sets: bicepsSets, records: [], readiness: nil,
            limit: 10, referenceDate: now, calendar: cal)
        #expect(advices.contains { $0.title == "回復済みの部位" })
    }

    @Test("combinedCoachingAdvice: bodyPhase を渡すとフェーズ提案がマージされる")
    func bodyPhaseMerged() {
        let cut = BodyPhaseResult(phase: .cut, kgPerMonth: -1.2)
        let withPhase = Analytics.combinedCoachingAdvice(
            sessions: [], sets: [], records: [], readiness: nil,
            limit: .max, bodyPhase: cut)
        let withoutPhase = Analytics.combinedCoachingAdvice(
            sessions: [], sets: [], records: [], readiness: nil,
            limit: .max, bodyPhase: nil)
        #expect(withPhase.contains { $0.title == "減量期" })
        #expect(!withoutPhase.contains { $0.title == "減量期" })
    }
}

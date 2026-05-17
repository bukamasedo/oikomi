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

    // MARK: - streakDays

    @Test("streakDays: 完了済みセッションがゼロなら0")
    func streakEmpty() {
        let result = Analytics.streakDays(sessions: [], calendar: Self.calendar)
        #expect(result == 0)
    }

    @Test("streakDays: 今日に1セッションのみなら1")
    func streakToday() {
        let session = WorkoutSession(startedAt: Date())
        session.endedAt = Date()
        let result = Analytics.streakDays(sessions: [session], calendar: Self.calendar)
        #expect(result == 1)
    }

    @Test("streakDays: 連続3日なら3")
    func streakThreeDays() {
        let now = Date()
        let cal = Self.calendar
        let sessions = (0...2).map { offset -> WorkoutSession in
            let date = cal.date(byAdding: .day, value: -offset, to: now)!
            let s = WorkoutSession(startedAt: date)
            s.endedAt = date
            return s
        }
        let result = Analytics.streakDays(sessions: sessions, referenceDate: now, calendar: cal)
        #expect(result == 3)
    }

    @Test("streakDays: 2日前で止まっていれば（昨日抜け）0")
    func streakBrokenAtYesterday() {
        let now = Date()
        let cal = Self.calendar
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: now)!
        let s = WorkoutSession(startedAt: twoDaysAgo)
        s.endedAt = twoDaysAgo
        let result = Analytics.streakDays(sessions: [s], referenceDate: now, calendar: cal)
        #expect(result == 0)
    }

    @Test("streakDays: 完了していないセッションは無視")
    func streakIgnoresInProgress() {
        let session = WorkoutSession(startedAt: Date())  // endedAt = nil
        let result = Analytics.streakDays(sessions: [session], calendar: Self.calendar)
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

    // MARK: - prPredictions

    @Test("prPredictions: 直近セッションが PR の 95% 以上なら予測アドバイス")
    func prPredictionFires() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()

        // 過去 PR: 80kg × 8 = est 1RM 101.33
        try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8)
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        #expect(records.count == 1)

        // 直近セッション: 79kg × 8 = est 1RM 100.07（PR の 98.7%）
        let session2 = try repo.startSession()
        try repo.addSet(to: session2, exercise: bench, weight: 79, reps: 8)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let predictions = Analytics.prPredictions(sets: allSets, records: records)

        #expect(!predictions.isEmpty)
        #expect(predictions.first?.title.contains("PR") == true)
    }

    @Test("prPredictions: 直近セッションが PR から大きく落ちていれば出さない")
    func prPredictionSkipsWhenFar() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        // PR: 100kg × 5 = est 1RM 116.67
        let s1 = try repo.startSession()
        try repo.addSet(to: s1, exercise: bench, weight: 100, reps: 5)
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())

        // 直近: 60kg × 5 = est 1RM 70（PR の 60%）
        let s2 = try repo.startSession()
        try repo.addSet(to: s2, exercise: bench, weight: 60, reps: 5)

        // s1 のセットは除外して直近 only にしたいが、両方持ったまま prPredictions に渡しても
        // 「最高値が PR の 95% 以上」の条件で評価される。PR は s1 由来 100kg-5rep、
        // 直近セッションの max は 70 → ratio 60% で出さない（threshold 95%）
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
            .filter { $0.session?.id == s2.id }
        let predictions = Analytics.prPredictions(sets: allSets, records: records)
        #expect(predictions.isEmpty)
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
}

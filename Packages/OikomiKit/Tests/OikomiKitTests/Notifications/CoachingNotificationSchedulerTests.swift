import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("CoachingNotificationScheduler")
@MainActor
struct CoachingNotificationSchedulerTests {

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
        return cal
    }()

    // MARK: - evaluateHRVDeload

    @Test("evaluateHRVDeload: nil 値は判定不能で false")
    func hrvNilReturnsFalse() {
        #expect(CoachingNotificationScheduler.evaluateHRVDeload(today: nil, trailing7DayAverage: 50) == false)
        #expect(CoachingNotificationScheduler.evaluateHRVDeload(today: 50, trailing7DayAverage: nil) == false)
        #expect(CoachingNotificationScheduler.evaluateHRVDeload(today: nil, trailing7DayAverage: nil) == false)
    }

    @Test("evaluateHRVDeload: 平均と同じ値は false")
    func hrvEqualReturnsFalse() {
        #expect(CoachingNotificationScheduler.evaluateHRVDeload(today: 50, trailing7DayAverage: 50) == false)
    }

    @Test("evaluateHRVDeload: -20% ちょうどで true（境界）")
    func hrvAtBoundaryReturnsTrue() {
        // 50 * 0.8 = 40
        #expect(CoachingNotificationScheduler.evaluateHRVDeload(today: 40, trailing7DayAverage: 50) == true)
    }

    @Test("evaluateHRVDeload: -10% は false (しきい値未達)")
    func hrvAbove80PercentReturnsFalse() {
        #expect(CoachingNotificationScheduler.evaluateHRVDeload(today: 45, trailing7DayAverage: 50) == false)
    }

    @Test("evaluateHRVDeload: -30% は true")
    func hrvBelow80PercentReturnsTrue() {
        #expect(CoachingNotificationScheduler.evaluateHRVDeload(today: 35, trailing7DayAverage: 50) == true)
    }

    @Test("evaluateHRVDeload: thresholdPercent をカスタムできる")
    func hrvCustomThreshold() {
        // -10% しきい値: 45 ≤ 50 * 0.9 = 45 → true (境界)
        #expect(
            CoachingNotificationScheduler.evaluateHRVDeload(
                today: 45,
                trailing7DayAverage: 50,
                thresholdPercent: 0.10
            ) == true)
        #expect(
            CoachingNotificationScheduler.evaluateHRVDeload(
                today: 46,
                trailing7DayAverage: 50,
                thresholdPercent: 0.10
            ) == false)
    }

    // MARK: - evaluatePRPrediction

    @Test("evaluatePRPrediction: 翌日のルーティンがなければ空配列")
    func prNoScheduledRoutinesReturnsEmpty() throws {
        let context = try Self.makeContext()
        let cal = Self.calendar
        // 月曜のルーティンしかなく、翌日が水曜のケース
        let exercise = Exercise(name: "Bench")
        context.insert(exercise)
        let routine = Routine(name: "Mon Push", scheduledWeekdays: [2])
        context.insert(routine)
        let entry = RoutineExercise(routine: routine, exercise: exercise, order: 0)
        context.insert(entry)
        // 翌日 = 水曜 (weekday 4)
        let tomorrow = nextDateWithWeekday(4, calendar: cal)

        let result = CoachingNotificationScheduler.evaluatePRPrediction(
            routines: [routine],
            sets: [],
            records: [],
            tomorrow: tomorrow,
            calendar: cal
        )
        #expect(result.isEmpty)
    }

    @Test("evaluatePRPrediction: 翌日のルーティンに該当種目があり、PR 圏内なら advice 1 件以上")
    func prInRangeReturnsAdvice() throws {
        let context = try Self.makeContext()
        let cal = Self.calendar
        let exercise = Exercise(name: "Bench")
        context.insert(exercise)
        // 翌日 = 火曜 (weekday 3) と仮定。ルーティンも火曜。
        let tomorrow = nextDateWithWeekday(3, calendar: cal)
        let tomorrowWeekday = cal.component(.weekday, from: tomorrow)
        let routine = Routine(name: "Push", scheduledWeekdays: [tomorrowWeekday])
        context.insert(routine)
        let entry = RoutineExercise(routine: routine, exercise: exercise, order: 0)
        context.insert(entry)

        // 上昇トレンドのセッションを 6 回作る
        var sets: [SetRecord] = []
        for i in 0..<6 {
            let session = WorkoutSession(startedAt: cal.date(byAdding: .day, value: -(6 - i) * 2, to: Date())!)
            session.endedAt = session.startedAt.addingTimeInterval(3600)
            context.insert(session)
            let weight = 60.0 + Double(i) * 2.5
            let set = SetRecord(
                exercise: exercise,
                session: session,
                order: 0,
                weight: weight,
                reps: 5,
                estimated1RM: OneRepMax.epley(weight: weight, reps: 5),
                completedAt: session.startedAt
            )
            context.insert(set)
            sets.append(set)
        }
        // 現 PR は控えめ (上昇トレンドの予測が PR を超える状況)
        let pr = PersonalRecord(exercise: exercise, weight: 60, reps: 5, estimated1RM: 70)
        context.insert(pr)
        try context.save()

        let result = CoachingNotificationScheduler.evaluatePRPrediction(
            routines: [routine],
            sets: sets,
            records: [pr],
            tomorrow: tomorrow,
            calendar: cal
        )
        #expect(!result.isEmpty)
        #expect(result.first?.title.contains("PR") == true)
    }

    @Test("evaluatePRPrediction: 翌日のルーティンに含まれない種目の PR はフィルタされる")
    func prFiltersOutOfRoutineExercises() throws {
        let context = try Self.makeContext()
        let cal = Self.calendar
        // 翌日 = 木曜 (weekday 5)
        let tomorrow = nextDateWithWeekday(5, calendar: cal)
        let tomorrowWeekday = cal.component(.weekday, from: tomorrow)

        let bench = Exercise(name: "Bench")
        let squat = Exercise(name: "Squat")
        context.insert(bench)
        context.insert(squat)

        // ルーティンには Bench だけが入っている
        let routine = Routine(name: "Push", scheduledWeekdays: [tomorrowWeekday])
        context.insert(routine)
        let entry = RoutineExercise(routine: routine, exercise: bench, order: 0)
        context.insert(entry)

        // PR は Squat について存在
        let pr = PersonalRecord(exercise: squat, weight: 100, reps: 5, estimated1RM: 116)
        context.insert(pr)
        try context.save()

        let result = CoachingNotificationScheduler.evaluatePRPrediction(
            routines: [routine],
            sets: [],
            records: [pr],
            tomorrow: tomorrow,
            calendar: cal
        )
        // Squat はルーティンに含まれないので、結果に含まれない
        #expect(result.isEmpty)
    }

    // MARK: - helpers

    /// 「次の指定 weekday の日付」を返す。テスト用ヘルパー。
    private func nextDateWithWeekday(_ weekday: Int, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.weekday = weekday
        return calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) ?? Date()
    }
}

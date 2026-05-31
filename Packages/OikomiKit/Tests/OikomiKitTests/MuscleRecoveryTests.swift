import Foundation
import Testing

@testable import OikomiKit

@Suite("MuscleRecovery")
struct MuscleRecoveryTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }()

    private var now: Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 5, day: 31, hour: 12))!
    }

    /// `hoursAgo` 時間前に `muscles` を `setCount` セット鍛えたワーキングセット群を作る（context 不要・スタンドアロン）。
    private func sets(
        _ muscles: [MuscleGroup], hoursAgo: Double, setCount: Int = 1,
        rpe: Double? = nil, isWarmup: Bool = false, isCompleted: Bool = true
    ) -> [SetRecord] {
        let date = now.addingTimeInterval(-hoursAgo * 3600)
        let ex = Exercise(name: "t", muscleGroups: muscles)
        return (0..<setCount).map { _ in
            SetRecord(
                exercise: ex, weight: 60, reps: 8, rpe: rpe,
                isWarmup: isWarmup, completedAt: date, isCompleted: isCompleted)
        }
    }

    private func row(_ rows: [MuscleRecoveryRow], _ muscle: MuscleGroup) -> MuscleRecoveryRow? {
        rows.first { $0.muscle == muscle }
    }

    @Test("report: 記録のない筋群は untrained・daysSince nil")
    func untrained() {
        let rows = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 10), referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .quads)?.state == .untrained)
        #expect(row(rows, .quads)?.daysSinceLastTrained == nil)
    }

    @Test("report: fullBody は含まれない / abs は含まれる")
    func trackedFilter() {
        let rows = MuscleRecovery.report(sets: [], referenceDate: now, calendar: Self.calendar)
        #expect(!rows.contains { $0.muscle == .fullBody })
        #expect(rows.contains { $0.muscle == .abs })
    }

    @Test("report: 直後は fatigued、ウィンドウ半ばは recovering、超過は recovered")
    func stateThresholds() {
        let f = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 6), referenceDate: now, calendar: Self.calendar)
        #expect(row(f, .chest)?.state == .fatigued)  // 6/48 = 0.125
        let r = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 30), referenceDate: now, calendar: Self.calendar)
        #expect(row(r, .chest)?.state == .recovering)  // 30/48 = 0.625
        let d = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 50), referenceDate: now, calendar: Self.calendar)
        #expect(row(d, .chest)?.state == .recovered)  // 50/48 >= 1
    }

    @Test("report: 高ボリュームは回復ウィンドウを延ばす")
    func loadExtendsWindow() {
        // chest 48h ago。6セット→window48→recovered。14セット→window72→未回復。
        let light = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, setCount: 6), referenceDate: now, calendar: Self.calendar)
        #expect(row(light, .chest)?.state == .recovered)
        let heavy = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, setCount: 14), referenceDate: now, calendar: Self.calendar)
        #expect(row(heavy, .chest)?.state != .recovered)
    }

    @Test("report: 高RPEは回復ウィンドウを延ばす")
    func rpeExtendsWindow() {
        let easy = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, rpe: nil), referenceDate: now, calendar: Self.calendar)
        #expect(row(easy, .chest)?.state == .recovered)
        let hard = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, rpe: 9), referenceDate: now, calendar: Self.calendar)
        #expect(row(hard, .chest)?.state == .recovering)  // window 54 → 48/54 = 0.889
    }

    @Test("report: 大筋群は小筋群より回復が遅い")
    func baseHoursBySize() {
        // 60h ago。quads base72 → 0.83 recovering。biceps base36 → recovered。
        let s = sets([.quads], hoursAgo: 60) + sets([.biceps], hoursAgo: 60)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .quads)?.state == .recovering)
        #expect(row(rows, .biceps)?.state == .recovered)
    }

    @Test("report: warmup と未完了セットは無視")
    func excludesWarmupAndIncomplete() {
        let s =
            sets([.chest], hoursAgo: 6, isWarmup: true)
            + sets([.chest], hoursAgo: 6, isCompleted: false)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .chest)?.state == .untrained)
    }

    @Test("report: 複合種目は関与する全筋群を鍛えた扱い")
    func compoundHitsAllMuscles() {
        let s = sets([.chest, .triceps, .shoulders], hoursAgo: 6)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .chest)?.state == .fatigued)
        #expect(row(rows, .triceps)?.state == .fatigued)
        #expect(row(rows, .shoulders)?.state == .fatigued)
    }

    @Test("report: untrained は末尾、残りは回復率降順")
    func sortOrder() {
        let s = sets([.chest], hoursAgo: 6) + sets([.biceps], hoursAgo: 60)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        let trained = Array(rows.prefix { $0.state != .untrained })
        #expect(rows.suffix(from: trained.count).allSatisfy { $0.state == .untrained })
        let fractions = trained.map(\.recoveryFraction)
        #expect(fractions == fractions.sorted(by: >))
    }

    @Test("report: daysSinceLastTrained をカレンダー日数で返す（now=5/31 12:00 基準）")
    func daysSince() {
        // 同日(6h前) → 0、前日(25h前=5/30 11:00) → 1、2日前(48h前=5/29 12:00) → 2
        let today = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 6), referenceDate: now, calendar: Self.calendar)
        #expect(row(today, .chest)?.daysSinceLastTrained == 0)
        let yesterday = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 25), referenceDate: now, calendar: Self.calendar)
        #expect(row(yesterday, .chest)?.daysSinceLastTrained == 1)
        let twoDays = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48), referenceDate: now, calendar: Self.calendar)
        #expect(row(twoDays, .chest)?.daysSinceLastTrained == 2)
    }
}

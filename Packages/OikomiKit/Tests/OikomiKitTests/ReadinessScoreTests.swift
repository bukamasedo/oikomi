import Foundation
import Testing

@testable import OikomiKit

@Suite("ReadinessScore")
struct ReadinessScoreTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }()

    /// 基準日から過去 `days` 日分、`baseline` 付近（±jitter）の系列を作り、最新日だけ `today` にする。
    private func series(today: Double, baseline: Double, jitter: Double, days: Int) -> [HealthTrendPoint] {
        let cal = Self.calendar
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 23))!
        var points: [HealthTrendPoint] = []
        for offset in 1..<days {
            let date = cal.date(byAdding: .day, value: -offset, to: now)!
            let v = baseline + (offset % 2 == 0 ? jitter : -jitter)
            points.append(HealthTrendPoint(date: date, value: v))
        }
        points.append(HealthTrendPoint(date: now, value: today))
        return points
    }

    private var referenceDate: Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 5, day: 23))!
    }

    @Test("compute: 信号が全く無ければ nil")
    func noSignalsReturnsNil() {
        let score = ReadinessScore.compute(
            hrvSeries: [], rhrSeries: [], sleepHours: nil,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score == nil)
    }

    @Test("compute: 睡眠のみ・6h は value 60・confidence low・ソース注記あり")
    func sleepOnly() {
        let score = ReadinessScore.compute(
            hrvSeries: [], rhrSeries: [], sleepHours: 6,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score?.value == 60)
        #expect(score?.confidence == .low)
        #expect(score?.band == .normal)
        #expect(score?.sourceNote != nil)
        #expect(score?.usedSignals == [.sleep])
    }

    @Test("compute: HRV が大きく低下していれば band は low")
    func lowHRVGivesLowBand() {
        // baseline≈60(±3), today=30 → z が強く負 → 低スコア
        let hrv = series(today: 30, baseline: 60, jitter: 3, days: 21)
        let score = ReadinessScore.compute(
            hrvSeries: hrv, rhrSeries: [], sleepHours: nil,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score?.band == .low)
        #expect((score?.hrvZ ?? 0) < -1)
    }

    @Test("compute: 3信号そろえば confidence high・ソース注記は nil")
    func threeSignalsHighConfidence() {
        let hrv = series(today: 62, baseline: 60, jitter: 3, days: 21)
        let rhr = series(today: 52, baseline: 52, jitter: 1, days: 21)
        let score = ReadinessScore.compute(
            hrvSeries: hrv, rhrSeries: rhr, sleepHours: 8,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score?.confidence == .high)
        #expect(score?.sourceNote == nil)
        #expect(score?.usedSignals.count == 3)
    }

    @Test("compute: 系列が 14 日未満なら HRV 成分は使わない")
    func insufficientHistorySkipsHRV() {
        let hrv = series(today: 30, baseline: 60, jitter: 3, days: 10)  // 10日 < 14
        let score = ReadinessScore.compute(
            hrvSeries: hrv, rhrSeries: [], sleepHours: 7,
            referenceDate: referenceDate, calendar: Self.calendar)
        // HRV は無視され、睡眠のみで算出される
        #expect(score?.usedSignals == [.sleep])
    }

    @Test("compute: 2信号（HRV+睡眠・RHRなし）は confidence medium・汎用ソース注記")
    func twoSignalsMediumConfidence() {
        let hrv = series(today: 62, baseline: 60, jitter: 3, days: 21)
        let score = ReadinessScore.compute(
            hrvSeries: hrv, rhrSeries: [], sleepHours: 8,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score?.confidence == .medium)
        #expect(score?.usedSignals == [.hrv, .sleep])
        // HRV はあるので「Apple Watch 未接続」ではなく汎用の参考値文になる
        #expect(score?.sourceNote == "一部のデータが不足しているため、参考値です。")
    }
}

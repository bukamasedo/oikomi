import Foundation
import Testing

@testable import OikomiKit

@Suite("BodyPhase")
struct BodyPhaseTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2
        return cal
    }()

    /// 起点日から day0,3,6,... と weight を与える系列を作る。
    private func series(start: Date, weights: [Double]) -> [HealthTrendPoint] {
        weights.enumerated().map { index, w in
            let date = Self.calendar.date(byAdding: .day, value: index * 3, to: start)!
            return HealthTrendPoint(date: date, value: w)
        }
    }

    private var start: Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
    }

    @Test("増加系列 → 増量期（kgPerMonth > 0）")
    func bulk() {
        // 8点・3日間隔で +0.2kg/点 ≒ +2kg/月
        let pts = series(start: start, weights: (0..<8).map { 70.0 + Double($0) * 0.2 })
        let result = BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar)
        #expect(result?.phase == .bulk)
        #expect((result?.kgPerMonth ?? 0) > 0)
    }

    @Test("減少系列 → 減量期（kgPerMonth < 0）")
    func cut() {
        let pts = series(start: start, weights: (0..<8).map { 70.0 - Double($0) * 0.2 })
        let result = BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar)
        #expect(result?.phase == .cut)
        #expect((result?.kgPerMonth ?? 0) < 0)
    }

    @Test("平坦系列 → 維持期")
    func maintenance() {
        let pts = series(start: start, weights: Array(repeating: 70.0, count: 8))
        let result = BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar)
        #expect(result?.phase == .maintenance)
    }

    @Test("サンプル不足（< 6 点）で nil")
    func insufficientSamples() {
        let pts = series(start: start, weights: [70, 71, 72, 73, 74])  // 5 点
        #expect(BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar) == nil)
    }

    @Test("phaseAdvice: 増量/減量は 1 件 info、維持/nil は空")
    func phaseAdvice() {
        let bulk = BodyPhase.phaseAdvice(BodyPhaseResult(phase: .bulk, kgPerMonth: 1.5))
        #expect(bulk.count == 1)
        #expect(bulk.first?.severity == .info)
        #expect(bulk.first?.title == "増量期")

        let cut = BodyPhase.phaseAdvice(BodyPhaseResult(phase: .cut, kgPerMonth: -1.2))
        #expect(cut.first?.title == "減量期")

        #expect(BodyPhase.phaseAdvice(BodyPhaseResult(phase: .maintenance, kgPerMonth: 0.1)).isEmpty)
        #expect(BodyPhase.phaseAdvice(nil).isEmpty)
    }
}

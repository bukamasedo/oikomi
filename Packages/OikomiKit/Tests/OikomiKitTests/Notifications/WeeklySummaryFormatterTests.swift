import Foundation
import Testing

@testable import OikomiKit

@Suite("WeeklySummaryFormatter")
struct WeeklySummaryFormatterTests {

    @Test("title: 一定の煽らない文言")
    func titleIsConstant() {
        let report = WeeklySummaryFormatter.Report(sessionDays: 3, totalVolume: 5000, topMuscles: [])
        #expect(WeeklySummaryFormatter.title(for: report) == "今週のトレーニングまとめ")
    }

    @Test("body: 実施なしの週は休養文言")
    func bodyZeroDaysIsRestMessage() {
        let report = WeeklySummaryFormatter.Report(sessionDays: 0, totalVolume: 0, topMuscles: [])
        let body = WeeklySummaryFormatter.body(for: report)
        #expect(body.contains("休養"))
    }

    @Test("body: 部位上位なしでも実施日数と総ボリュームが入る")
    func bodyWithoutTopMuscle() {
        let report = WeeklySummaryFormatter.Report(sessionDays: 2, totalVolume: 3000, topMuscles: [])
        let body = WeeklySummaryFormatter.body(for: report)
        #expect(body.contains("2 日"))
        #expect(body.contains("総ボリューム"))
    }

    @Test("body: 上位部位は本文に含まれる")
    func bodyIncludesTopMuscle() {
        let report = WeeklySummaryFormatter.Report(
            sessionDays: 3,
            totalVolume: 5000,
            topMuscles: [(.chest, 2500)]
        )
        let body = WeeklySummaryFormatter.body(for: report)
        #expect(body.contains(MuscleGroup.chest.displayName))
        #expect(body.contains("3 日"))
    }

    @Test("Report の Equatable は topMuscles 内の muscle / volume を含めて比較する")
    func reportEquatable() {
        let a = WeeklySummaryFormatter.Report(
            sessionDays: 3, totalVolume: 5000, topMuscles: [(.chest, 2500)]
        )
        let b = WeeklySummaryFormatter.Report(
            sessionDays: 3, totalVolume: 5000, topMuscles: [(.chest, 2500)]
        )
        let c = WeeklySummaryFormatter.Report(
            sessionDays: 3, totalVolume: 5000, topMuscles: [(.back, 2500)]
        )
        #expect(a == b)
        #expect(a != c)
    }
}

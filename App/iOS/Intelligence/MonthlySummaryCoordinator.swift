import Foundation
import OikomiKit
import SwiftData

/// 先月の振り返りの「カード表示判定」「既存ロード or 生成・保存」をまとめる。
@MainActor
enum MonthlySummaryCoordinator {

    /// 直近の「先月」を yyyy-MM で返す。
    static func lastMonth(now: Date = Date(), calendar: Calendar = .current) -> String {
        let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let comps = calendar.dateComponents([.year, .month], from: start)
        return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
    }

    /// 先月の振り返りカードを出すべきか（Pro + AI 可用 + 先月データが充実）。
    static func shouldOffer(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        snapshots: [HealthSnapshot]
    ) -> Bool {
        guard ProGate.canUseAICoaching else { return false }
        guard case .available = MonthlySummaryGenerator.availability() else { return false }
        let digest = MonthlyDigest.build(
            sessions: sessions, sets: sets, records: records, snapshots: snapshots,
            yearMonth: lastMonth())
        return digest?.isSubstantial == true
    }

    /// 既存サマリがあれば返し、無ければ生成・保存して返す。
    static func loadOrGenerate(
        context: ModelContext,
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        snapshots: [HealthSnapshot],
        bodyPhase: BodyPhaseResult?
    ) async throws -> MonthlySummary {
        let yearMonth = lastMonth()
        let repo = MonthlySummaryRepository(context: context)
        if let existing = try repo.summary(forYearMonth: yearMonth) { return existing }
        guard
            let digest = MonthlyDigest.build(
                sessions: sessions, sets: sets, records: records, snapshots: snapshots,
                yearMonth: yearMonth, bodyPhase: bodyPhase)
        else { throw MonthlySummaryError.unavailable }
        let payload = MonthlySummaryPrompt.make(from: digest)
        let content = try await MonthlySummaryGenerator().generate(payload: payload)
        return try repo.save(
            yearMonth: yearMonth,
            headline: content.headline,
            highlights: content.highlights,
            watchPoints: content.watchPoints,
            nextFocus: content.nextFocus)
    }
}

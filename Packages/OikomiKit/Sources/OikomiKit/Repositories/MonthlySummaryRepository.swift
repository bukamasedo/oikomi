import Foundation
import SwiftData

@MainActor
public final class MonthlySummaryRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 指定年月のサマリを返す。無ければ nil。
    public func summary(forYearMonth yearMonth: String) throws -> MonthlySummary? {
        var descriptor = FetchDescriptor<MonthlySummary>(
            predicate: #Predicate { $0.yearMonth == yearMonth })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// 全サマリを generatedAt 降順で返す。
    public func allSummaries() throws -> [MonthlySummary] {
        let descriptor = FetchDescriptor<MonthlySummary>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    /// 同 yearMonth があれば上書き、無ければ新規作成して保存する。
    @discardableResult
    public func save(
        yearMonth: String,
        headline: String,
        highlights: [String],
        watchPoints: [String],
        nextFocus: [String]
    ) throws -> MonthlySummary {
        let summary =
            try self.summary(forYearMonth: yearMonth)
            ?? {
                let new = MonthlySummary(yearMonth: yearMonth)
                context.insert(new)
                return new
            }()
        summary.headline = headline
        summary.highlights = highlights
        summary.watchPoints = watchPoints
        summary.nextFocus = nextFocus
        summary.generatedAt = Date()
        try context.save()
        return summary
    }
}

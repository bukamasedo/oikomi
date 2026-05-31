import Foundation
import SwiftData

/// Foundation Models が生成した月次振り返りの保存表現。CloudKit 互換（全プロパティにデフォルト値）。
@Model
public final class MonthlySummary {
    public var yearMonth: String = ""  // "2026-05"
    public var headline: String = ""
    public var highlights: [String] = []
    public var watchPoints: [String] = []
    public var nextFocus: [String] = []
    public var generatedAt: Date = Date()

    public init(
        yearMonth: String = "",
        headline: String = "",
        highlights: [String] = [],
        watchPoints: [String] = [],
        nextFocus: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.yearMonth = yearMonth
        self.headline = headline
        self.highlights = highlights
        self.watchPoints = watchPoints
        self.nextFocus = nextFocus
        self.generatedAt = generatedAt
    }
}

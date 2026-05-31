import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("MonthlySummaryRepository")
@MainActor
struct MonthlySummaryRepositoryTests {

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    @Test("保存して yearMonth で取得できる")
    func saveAndFetch() throws {
        let repo = MonthlySummaryRepository(context: try Self.makeContext())
        _ = try repo.save(
            yearMonth: "2026-05", headline: "良い月", highlights: ["PR更新"], watchPoints: [],
            nextFocus: ["脚を増やす"])
        let fetched = try repo.summary(forYearMonth: "2026-05")
        #expect(fetched?.headline == "良い月")
        #expect(try repo.summary(forYearMonth: "2026-04") == nil)
    }

    @Test("同じ yearMonth の再保存は上書き（重複生成しない）")
    func upsert() throws {
        let repo = MonthlySummaryRepository(context: try Self.makeContext())
        _ = try repo.save(yearMonth: "2026-05", headline: "v1", highlights: [], watchPoints: [], nextFocus: [])
        _ = try repo.save(yearMonth: "2026-05", headline: "v2", highlights: [], watchPoints: [], nextFocus: [])
        #expect(try repo.allSummaries().count == 1)
        #expect(try repo.summary(forYearMonth: "2026-05")?.headline == "v2")
    }

    @Test("履歴は generatedAt 降順")
    func historyOrder() throws {
        let repo = MonthlySummaryRepository(context: try Self.makeContext())
        _ = try repo.save(yearMonth: "2026-04", headline: "4月", highlights: [], watchPoints: [], nextFocus: [])
        _ = try repo.save(yearMonth: "2026-05", headline: "5月", highlights: [], watchPoints: [], nextFocus: [])
        let all = try repo.allSummaries()
        #expect(all.first?.yearMonth == "2026-05")
    }
}

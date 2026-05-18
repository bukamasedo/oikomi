import Foundation
import SwiftData

/// 完了済みワークアウトを CSV としてエクスポートする。
///
/// 仕様書 §10: Pro 限定機能。`ProGate.canExportData` でガードする。
/// 出力フォーマット: `date,exercise,weight,reps,duration_seconds,is_warmup,estimated_1rm`
public enum DataExporter {

    public enum ExportError: LocalizedError {
        case notEntitled

        public var errorDescription: String? {
            switch self {
            case .notEntitled:
                return ProGateError.dataExportRequiresPro.errorDescription
            }
        }
    }

    /// 完了済みセットを CSV 文字列で返す。`order` 昇順、session.startedAt 昇順でソート。
    @MainActor
    public static func exportCSV(context: ModelContext) throws -> String {
        guard ProGate.canExportData else { throw ExportError.notEntitled }

        let sessions = try context.fetch(
            FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.endedAt != nil },
                sortBy: [SortDescriptor(\.startedAt)]
            )
        )

        var lines: [String] = ["date,exercise,weight_kg,reps,duration_sec,is_warmup,estimated_1rm_kg"]
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        for session in sessions {
            for set in session.orderedSets where set.isCompleted {
                let date = isoFormatter.string(from: set.completedAt)
                let exercise = escapeCSV(set.exercise?.name ?? "")
                let weight = set.weight.map { "\($0)" } ?? ""
                let reps = set.reps.map { "\($0)" } ?? ""
                let duration = set.durationSeconds.map { "\($0)" } ?? ""
                let isWarmup = set.isWarmup ? "1" : "0"
                let oneRM = set.estimated1RM.map { String(format: "%.2f", $0) } ?? ""
                lines.append("\(date),\(exercise),\(weight),\(reps),\(duration),\(isWarmup),\(oneRM)")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    /// CSV を一時ファイルに書き出し、URL を返す（ShareLink に渡す用）。
    @MainActor
    public static func writeCSVToTemp(context: ModelContext) throws -> URL {
        let csv = try exportCSV(context: context)
        let dateStamp = DateFormatter()
        dateStamp.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "oikomi-export-\(dateStamp.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

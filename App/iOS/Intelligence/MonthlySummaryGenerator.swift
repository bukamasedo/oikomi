import Foundation
import FoundationModels
import OikomiKit

enum MonthlySummaryAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

enum MonthlySummaryError: Error {
    case unavailable
}

struct MonthlySummaryGenerator {

    /// 端末の Apple Intelligence 可用性。
    static func availability() -> MonthlySummaryAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason: "\(reason)")
        @unknown default:
            return .unavailable(reason: "unknown")
        }
    }

    /// プロンプトから月次サマリ本文を生成する。
    func generate(payload: MonthlySummaryPrompt.Payload) async throws -> MonthlySummaryContent {
        guard case .available = Self.availability() else { throw MonthlySummaryError.unavailable }
        let session = LanguageModelSession {
            payload.instructions
        }
        let response = try await session.respond(
            to: payload.prompt, generating: MonthlySummaryContent.self)
        return response.content
    }
}

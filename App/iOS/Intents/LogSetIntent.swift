import AppIntents
import Foundation
import SwiftData
import OikomiKit

/// Siri / ショートカット / Spotlight から呼べる「セット記録」インテント。
///
/// 仕様書 §4.3「App Intents / Siri: ベンチプレス 80kg 8レップ記録」の実装。
/// 進行中セッションがなければ自動で開始する。種目名は前方一致 / 部分一致で検索。
struct LogSetIntent: AppIntent {

    static let title: LocalizedStringResource = "セットを記録"
    static let description = IntentDescription("筋トレのセットを記録します。種目名・重量・レップ数を指定。")
    static let openAppWhenRun = false

    @Parameter(title: "種目名", description: "例: ベンチプレス")
    var exerciseName: String

    @Parameter(title: "重量 (kg)", description: "自重種目では 0 を指定")
    var weight: Double

    @Parameter(title: "レップ数")
    var reps: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = SharedModelContainer.mustGetContainer().mainContext

        let exercise = try findExercise(named: exerciseName, in: context)

        let sessionRepo = WorkoutSessionRepository(context: context)
        let session = try ensureActiveSession(repo: sessionRepo, in: context)

        let useBodyweight = exercise.measurementType == .bodyweightReps || weight == 0
        try sessionRepo.addSet(
            to: session,
            exercise: exercise,
            weight: useBodyweight ? nil : weight,
            reps: reps
        )

        let confirmation: LocalizedStringResource
        if useBodyweight {
            confirmation = "\(exercise.name) \(reps) レップを記録しました"
        } else {
            confirmation = "\(exercise.name) \(weight, format: .number) kg × \(reps) レップを記録しました"
        }
        return .result(dialog: IntentDialog(confirmation))
    }

    private func findExercise(named name: String, in context: ModelContext) throws -> Exercise {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // 完全一致 → 前方一致 → 部分一致 → 英語名で同じ順
        let descriptor = FetchDescriptor<Exercise>(sortBy: [.init(\.name)])
        let all = try context.fetch(descriptor)

        if let exact = all.first(where: { $0.name == normalized || $0.nameEn.caseInsensitiveCompare(normalized) == .orderedSame }) {
            return exact
        }
        if let prefix = all.first(where: { $0.name.hasPrefix(normalized) }) {
            return prefix
        }
        if let contains = all.first(where: { $0.name.contains(normalized) || $0.nameEn.localizedCaseInsensitiveContains(normalized) }) {
            return contains
        }
        throw IntentError.exerciseNotFound(query: normalized)
    }

    @MainActor
    private func ensureActiveSession(repo: WorkoutSessionRepository, in context: ModelContext) throws -> WorkoutSession {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endedAt == nil }
        )
        if let active = try context.fetch(descriptor).first {
            return active
        }
        return try repo.startSession()
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case exerciseNotFound(query: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .exerciseNotFound(let query):
            return "種目「\(query)」が見つかりませんでした"
        }
    }
}

/// Spotlight / Siri に自動で表示されるショートカット集合。
struct OikomiShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogSetIntent(),
            phrases: [
                "\(.applicationName)でセットを記録",
                "\(.applicationName)に記録",
            ],
            shortTitle: "セットを記録",
            systemImageName: "figure.strengthtraining.traditional"
        )
    }
}

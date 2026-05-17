import Foundation
import SwiftData

/// 自己ベスト記録（PersonalRecord）の更新を扱う。
///
/// セット保存時に呼ばれ、推定1RM が既存ベストを超えていれば更新／新規作成する。
@MainActor
public final class PersonalRecordRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 指定セットを評価して、必要なら自己ベストを更新する。
    ///
    /// - Returns: 新規 PR 達成時は更新された `PersonalRecord`、それ以外は nil
    @discardableResult
    public func updateIfNewBest(from set: SetRecord) throws -> PersonalRecord? {
        guard let exercise = set.exercise,
            let rm = set.estimated1RM,
            let weight = set.weight,
            let reps = set.reps,
            rm > 0
        else {
            return nil
        }

        let exerciseId = exercise.id
        var descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.exercise?.id == exerciseId },
            sortBy: [SortDescriptor(\.estimated1RM, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let current = try context.fetch(descriptor).first

        if let current, current.estimated1RM >= rm {
            return nil
        }

        if let current {
            current.weight = weight
            current.reps = reps
            current.estimated1RM = rm
            current.achievedAt = set.completedAt
            try context.save()
            return current
        }

        let record = PersonalRecord(
            exercise: exercise,
            weight: weight,
            reps: reps,
            estimated1RM: rm,
            achievedAt: set.completedAt
        )
        context.insert(record)
        try context.save()
        return record
    }
}

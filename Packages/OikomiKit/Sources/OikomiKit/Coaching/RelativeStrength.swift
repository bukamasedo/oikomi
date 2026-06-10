import Foundation

/// 1 種目の相対筋力（推定 1RM ÷ 体重）を表す行モデル。
public struct RelativeStrengthRow: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let exerciseName: String
    public let estimated1RM: Double  // kg
    public let ratio: Double  // estimated1RM / 体重

    public init(id: UUID, exerciseName: String, estimated1RM: Double, ratio: Double) {
        self.id = id
        self.exerciseName = exerciseName
        self.estimated1RM = estimated1RM
        self.ratio = ratio
    }
}

public enum RelativeStrength {
    /// 重量種目の PR から相対筋力（1RM/体重）を計算し、体重比降順で返す。
    /// 自重種目（estimated1RM <= 0）と体重未取得（bodyweightKg <= 0）は除外する。
    public static func report(
        records: [PersonalRecord],
        bodyweightKg: Double
    ) -> [RelativeStrengthRow] {
        guard bodyweightKg > 0 else { return [] }
        let rows: [RelativeStrengthRow] = records.compactMap { record in
            guard let exercise = record.exercise, record.estimated1RM > 0 else { return nil }
            return RelativeStrengthRow(
                id: record.id,
                exerciseName: exercise.localizedName,
                estimated1RM: record.estimated1RM,
                ratio: record.estimated1RM / bodyweightKg
            )
        }
        return rows.sorted { lhs, rhs in
            if lhs.ratio != rhs.ratio { return lhs.ratio > rhs.ratio }
            return lhs.exerciseName < rhs.exerciseName
        }
    }
}

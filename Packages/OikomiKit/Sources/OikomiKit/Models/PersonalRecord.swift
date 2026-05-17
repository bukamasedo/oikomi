import Foundation
import SwiftData

/// 種目別の自己ベスト記録。
@Model
public final class PersonalRecord {
    public var id: UUID = UUID()
    public var exercise: Exercise?
    public var weight: Double = 0
    public var reps: Int = 0
    public var estimated1RM: Double = 0
    public var achievedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        weight: Double = 0,
        reps: Int = 0,
        estimated1RM: Double = 0,
        achievedAt: Date = Date()
    ) {
        self.id = id
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.estimated1RM = estimated1RM
        self.achievedAt = achievedAt
    }
}

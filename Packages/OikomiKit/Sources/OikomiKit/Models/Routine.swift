import Foundation
import SwiftData

/// ユーザー定義のトレーニングルーティン。
@Model
public final class Routine {
    public var id: UUID = UUID()
    public var name: String = ""
    public var createdAt: Date = Date()
    public var lastUsedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    public var exercises: [RoutineExercise]? = []

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

extension Routine {
    public var orderedExercises: [RoutineExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }
}

/// ルーティン内の種目エントリ（順序・想定セット数を保持）
@Model
public final class RoutineExercise {
    public var id: UUID = UUID()
    public var routine: Routine?
    public var exercise: Exercise?
    public var order: Int = 0
    public var plannedSets: Int = 3
    public var plannedReps: Int = 8
    public var plannedWeight: Double?

    public init(
        id: UUID = UUID(),
        routine: Routine? = nil,
        exercise: Exercise? = nil,
        order: Int = 0,
        plannedSets: Int = 3,
        plannedReps: Int = 8,
        plannedWeight: Double? = nil
    ) {
        self.id = id
        self.routine = routine
        self.exercise = exercise
        self.order = order
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
    }
}

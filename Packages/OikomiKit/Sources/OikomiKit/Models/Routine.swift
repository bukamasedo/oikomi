import Foundation
import SwiftData

/// ユーザー定義のトレーニングルーティン。
@Model
public final class Routine {
    public var id: UUID = UUID()
    public var name: String = ""
    public var createdAt: Date = Date()
    public var lastUsedAt: Date?

    /// このルーティンが予定されている曜日。`Calendar.Component.weekday` の 1 (日) – 7 (土)。
    /// 空配列は「任意日」扱いで、PR 予測通知などの曜日ベース判定の対象外になる。
    /// 既存データは SwiftData の lightweight migration により空配列で復元される。
    public var scheduledWeekdays: [Int] = []

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    public var exercises: [RoutineExercise]? = []

    /// このルーティンから開始されたセッション（逆参照）。CloudKit 互換のため双方向。
    @Relationship(inverse: \WorkoutSession.routine)
    public var sessions: [WorkoutSession]? = []

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        scheduledWeekdays: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.scheduledWeekdays = scheduledWeekdays
    }
}

extension Routine {
    public var orderedExercises: [RoutineExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }

    /// 指定日にこのルーティンが予定されているか判定する。空配列の場合は常に false。
    public func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        guard !scheduledWeekdays.isEmpty else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return scheduledWeekdays.contains(weekday)
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
    /// このルーティン用のレスト秒数上書き。nil の場合は Exercise.defaultRestSeconds を採用。
    public var plannedRestSeconds: Int?

    public init(
        id: UUID = UUID(),
        routine: Routine? = nil,
        exercise: Exercise? = nil,
        order: Int = 0,
        plannedSets: Int = 3,
        plannedReps: Int = 8,
        plannedWeight: Double? = nil,
        plannedRestSeconds: Int? = nil
    ) {
        self.id = id
        self.routine = routine
        self.exercise = exercise
        self.order = order
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.plannedRestSeconds = plannedRestSeconds
    }
}

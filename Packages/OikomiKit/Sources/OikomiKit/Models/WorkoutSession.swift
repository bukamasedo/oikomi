import Foundation
import SwiftData

/// 1回のトレーニングセッション。
@Model
public final class WorkoutSession {
    public var id: UUID = UUID()
    public var startedAt: Date = Date()
    public var endedAt: Date?

    /// HKWorkout との紐付け（HealthKit に書き込んだ後にセット）
    public var healthKitWorkoutUUID: UUID?

    public var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \SetRecord.session)
    public var sets: [SetRecord]? = []

    @Relationship(deleteRule: .cascade, inverse: \HealthSnapshot.session)
    public var healthSnapshot: HealthSnapshot?

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        healthKitWorkoutUUID: UUID? = nil,
        notes: String? = nil,
        healthSnapshot: HealthSnapshot? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.notes = notes
        self.healthSnapshot = healthSnapshot
    }
}

extension WorkoutSession {
    public var durationSeconds: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    public var orderedSets: [SetRecord] {
        (sets ?? []).sorted { $0.order < $1.order }
    }
}

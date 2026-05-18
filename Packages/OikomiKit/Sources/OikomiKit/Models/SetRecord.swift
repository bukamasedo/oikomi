import Foundation
import SwiftData

/// セッション内の1セット記録。
@Model
public final class SetRecord {
    public var id: UUID = UUID()

    public var exercise: Exercise?
    public var session: WorkoutSession?

    /// セッション内の順序
    public var order: Int = 0

    /// 重量（kg）。自重種目は nil
    public var weight: Double?

    /// レップ数。時間計測種目は nil
    public var reps: Int?

    /// 時間計測種目（プランク等）の秒数
    public var durationSeconds: Int?

    /// 主観的運動強度（RPE: 1〜10）
    public var rpe: Double?

    public var isWarmup: Bool = false

    /// 記録時点での推定 1RM スナップショット
    public var estimated1RM: Double?

    public var restSeconds: Int?

    public var completedAt: Date = Date()

    /// 計画(未完了) vs 実績(完了)を区別する。
    /// 既存データは全て「即記録」フローで作成されているためデフォルト true で
    /// lightweight migration を破壊しない。`addPlannedSet` 経由のセットのみ false。
    public var isCompleted: Bool = true

    public init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        session: WorkoutSession? = nil,
        order: Int = 0,
        weight: Double? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        estimated1RM: Double? = nil,
        restSeconds: Int? = nil,
        completedAt: Date = Date(),
        isCompleted: Bool = true
    ) {
        self.id = id
        self.exercise = exercise
        self.session = session
        self.order = order
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.estimated1RM = estimated1RM
        self.restSeconds = restSeconds
        self.completedAt = completedAt
        self.isCompleted = isCompleted
    }
}

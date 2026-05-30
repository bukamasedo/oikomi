import Foundation
import SwiftData

/// セッション開始時の HealthKit データスナップショット。
///
/// 毎回 HealthKit を叩かないよう、セッション単位でキャッシュする。
/// AI コーチング（HRV ベースのディロード判定等）はこの値を参照する。
@Model
public final class HealthSnapshot {
    public var id: UUID = UUID()
    public var date: Date = Date()
    public var hrvSDNN: Double?
    public var sleepScore: Int?
    public var restingHeartRate: Int?
    /// コンディション総合スコア（0-100）のスナップショット。Spec 1 では予約のみ（populate は Spec 2）。
    public var readinessScore: Int?

    /// `MenstrualPhase.rawValue`（v1.1〜）
    public var menstrualPhaseRawValue: String?

    /// CloudKit 互換のため双方向リレーションを明示。実体側の cascade rule は WorkoutSession 側に記述。
    public var session: WorkoutSession?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        hrvSDNN: Double? = nil,
        sleepScore: Int? = nil,
        restingHeartRate: Int? = nil,
        readinessScore: Int? = nil,
        menstrualPhase: MenstrualPhase? = nil,
        session: WorkoutSession? = nil
    ) {
        self.id = id
        self.date = date
        self.hrvSDNN = hrvSDNN
        self.sleepScore = sleepScore
        self.restingHeartRate = restingHeartRate
        self.readinessScore = readinessScore
        self.menstrualPhaseRawValue = menstrualPhase?.rawValue
        self.session = session
    }
}

extension HealthSnapshot {
    public var menstrualPhase: MenstrualPhase? {
        get { menstrualPhaseRawValue.flatMap(MenstrualPhase.init(rawValue:)) }
        set { menstrualPhaseRawValue = newValue?.rawValue }
    }
}

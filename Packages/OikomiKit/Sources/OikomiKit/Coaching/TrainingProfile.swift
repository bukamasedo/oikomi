import Foundation

/// ユーザーの経験レベル × トレ目標。MEV/MAV 個人化と漸進性過負荷の入力。
public struct TrainingProfile: Sendable, Hashable {
    public let experience: ExperienceLevel
    public let goal: TrainingGoal

    public init(experience: ExperienceLevel, goal: TrainingGoal) {
        self.experience = experience
        self.goal = goal
    }

    /// 既定（中級者・筋肥大）。スケーリング係数がすべて 1.0 になり、既存の固定 MEV/MAV を完全維持する。
    public static let `default` = TrainingProfile(experience: .intermediate, goal: .hypertrophy)
}

/// 経験/目標プロファイルの UserDefaults アクセサ（`WeeklyTrainingTarget` と同パターン）。
public enum TrainingProfilePreference {
    public static let experienceKey = "OikomiExperienceLevel"
    public static let goalKey = "OikomiTrainingGoal"

    /// 現在のプロファイル。未設定キー・不正な rawValue は `.default` にフォールバック。
    ///
    /// 既定 store は `.standard`（iPhone のコーチング表示専用）。Watch / Widget から読む場合は
    /// `.sharedAppGroup` を明示的に渡すこと（`UnitPreference` 参照。今は iPhone のみが消費）。
    public static func current(defaults: UserDefaults = .standard) -> TrainingProfile {
        let experience =
            defaults.string(forKey: experienceKey).flatMap(ExperienceLevel.init(rawValue:))
            ?? TrainingProfile.default.experience
        let goal =
            defaults.string(forKey: goalKey).flatMap(TrainingGoal.init(rawValue:))
            ?? TrainingProfile.default.goal
        return TrainingProfile(experience: experience, goal: goal)
    }
}

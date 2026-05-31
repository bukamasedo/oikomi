import Foundation

// MARK: - CloudKit compatible enums
// CloudKit 互換のため String rawValue を使用し、Storage は rawValue で行う

public enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case abs
    case obliques
    case quads
    case hamstrings
    case glutes
    case calves
    case fullBody

    public var displayName: String {
        switch self {
        case .chest: return "胸"
        case .back: return "背中"
        case .shoulders: return "肩"
        case .biceps: return "上腕二頭筋"
        case .triceps: return "上腕三頭筋"
        case .forearms: return "前腕"
        case .abs: return "腹"
        case .obliques: return "腹斜筋"
        case .quads: return "大腿四頭筋"
        case .hamstrings: return "ハムストリング"
        case .glutes: return "臀部"
        case .calves: return "ふくらはぎ"
        case .fullBody: return "全身"
        }
    }
}

public enum Equipment: String, Codable, CaseIterable, Sendable {
    case barbell
    case dumbbell
    case machine
    case cable
    case bodyweight
    case kettlebell
    case band
    case other
}

public enum Location: String, Codable, CaseIterable, Sendable {
    case gym
    case home
}

public enum MeasurementType: String, Codable, CaseIterable, Sendable {
    case weightReps
    case bodyweightReps
    case time
    case distance
}

public enum MenstrualPhase: String, Codable, CaseIterable, Sendable {
    case menstrual
    case follicular
    case ovulation
    case luteal
}

public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced

    public var displayName: String {
        switch self {
        case .beginner: return "初心者"
        case .intermediate: return "中級者"
        case .advanced: return "上級者"
        }
    }
}

public enum TrainingGoal: String, Codable, CaseIterable, Sendable {
    case hypertrophy
    case strength
    case maintenance

    public var displayName: String {
        switch self {
        case .hypertrophy: return "筋肥大"
        case .strength: return "筋力"
        case .maintenance: return "維持"
        }
    }
}

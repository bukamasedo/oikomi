import Foundation

/// 1 週間あたりの推奨ワーキングセット数レンジ。
///
/// MEV (Minimum Effective Volume) = 維持に最低限必要なセット数。
/// MAV (Maximum Adaptive Volume) = 適応を引き出せる上限の目安。
///
/// Schoenfeld らのメタアナリシスを下敷きにした中央値ベースの初期値。
/// 個別の差は大きいため v1.1 でユーザーカスタマイズを追加する想定。
public struct WeeklySetTarget: Sendable, Hashable {
    public let mev: Int
    public let mav: Int

    public init(mev: Int, mav: Int) {
        self.mev = mev
        self.mav = mav
    }

    /// 対象部位として扱う（fullBody など除外用は (0, 0) を返す）。
    public var isTracked: Bool { mav > 0 }
}

extension MuscleGroup {
    /// 部位別の週セット数ターゲット。`MuscleSetCountRow.status` の判定に使う。
    public var weeklySetTarget: WeeklySetTarget {
        switch self {
        case .chest: return WeeklySetTarget(mev: 10, mav: 22)
        case .back: return WeeklySetTarget(mev: 12, mav: 25)
        case .shoulders: return WeeklySetTarget(mev: 8, mav: 20)
        case .biceps: return WeeklySetTarget(mev: 8, mav: 18)
        case .triceps: return WeeklySetTarget(mev: 8, mav: 18)
        case .forearms: return WeeklySetTarget(mev: 4, mav: 10)
        case .abs: return WeeklySetTarget(mev: 0, mav: 20)
        case .obliques: return WeeklySetTarget(mev: 0, mav: 10)
        case .quads: return WeeklySetTarget(mev: 10, mav: 20)
        case .hamstrings: return WeeklySetTarget(mev: 8, mav: 16)
        case .glutes: return WeeklySetTarget(mev: 8, mav: 16)
        case .calves: return WeeklySetTarget(mev: 8, mav: 16)
        case .fullBody: return WeeklySetTarget(mev: 0, mav: 0)
        }
    }
}

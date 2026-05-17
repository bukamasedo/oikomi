import Foundation
import SwiftData

/// ワークアウトセッション関連の書き込み操作を集約する。
///
/// 読み取りは SwiftUI 側で `@Query` を直接使う方が慣用的なので、
/// ここでは create / addSet / finish などの書き込み・更新系のみ提供する。
@MainActor
public final class WorkoutSessionRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 新規セッションを開始して保存する。
    @discardableResult
    public func startSession(at date: Date = Date()) throws -> WorkoutSession {
        let session = WorkoutSession(startedAt: date)
        context.insert(session)
        try context.save()
        return session
    }

    /// セット記録をセッションに追加する。
    ///
    /// 自重種目の場合は `weight` を nil、時間計測種目では `reps` を nil で渡す。
    @discardableResult
    public func addSet(
        to session: WorkoutSession,
        exercise: Exercise,
        weight: Double?,
        reps: Int?,
        durationSeconds: Int? = nil,
        isWarmup: Bool = false,
        completedAt: Date = Date()
    ) throws -> SetRecord {
        let nextOrder = (session.sets ?? []).map(\.order).max().map { $0 + 1 } ?? 0

        let estimated1RM: Double? = {
            guard let weight, weight > 0, let reps, reps > 0 else { return nil }
            return OneRepMax.epley(weight: weight, reps: reps)
        }()

        let set = SetRecord(
            exercise: exercise,
            session: session,
            order: nextOrder,
            weight: weight,
            reps: reps,
            durationSeconds: durationSeconds,
            isWarmup: isWarmup,
            estimated1RM: estimated1RM,
            completedAt: completedAt
        )
        context.insert(set)
        try context.save()
        return set
    }

    /// セッションを終了し、終了時刻を記録する。
    public func finishSession(_ session: WorkoutSession, at date: Date = Date()) throws {
        session.endedAt = date
        try context.save()
    }

    /// セッションを削除する（途中で破棄したい場合）。
    public func deleteSession(_ session: WorkoutSession) throws {
        context.delete(session)
        try context.save()
    }
}

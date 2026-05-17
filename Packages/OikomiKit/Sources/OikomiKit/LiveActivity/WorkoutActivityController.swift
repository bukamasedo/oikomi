import Foundation

#if os(iOS)
@preconcurrency import ActivityKit
#endif

/// Live Activity の開始 / 更新 / 終了を管理する。
///
/// セッション開始でアクティビティを request、セット記録・レストタイマー起動で update、
/// セッション終了で end する。プラットフォーム未対応では no-op。
@MainActor
public final class WorkoutActivityController {

    public static let shared = WorkoutActivityController()

    private init() {}

    #if os(iOS)
    private var current: Activity<WorkoutActivityAttributes>?

    /// セッション開始時に呼び出す。
    public func start(
        sessionId: UUID,
        routineName: String?,
        startedAt: Date,
        setCount: Int = 0
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = WorkoutActivityAttributes(
            sessionId: sessionId,
            routineName: routineName,
            startedAt: startedAt
        )
        let state = WorkoutActivityAttributes.ContentState(
            currentExerciseName: nil,
            setCount: setCount,
            restEndAt: nil
        )

        do {
            current = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil)
            )
        } catch {
            // 起動失敗（権限拒否等）は黙って受け流す
        }
    }

    /// 状態の更新。セット追加・レストタイマー開始/停止で呼ぶ。
    public func update(
        currentExerciseName: String?,
        setCount: Int,
        restEndAt: Date?
    ) async {
        guard let activity = current else { return }
        let state = WorkoutActivityAttributes.ContentState(
            currentExerciseName: currentExerciseName,
            setCount: setCount,
            restEndAt: restEndAt
        )
        await activity.update(
            ActivityContent(state: state, staleDate: nil)
        )
    }

    /// セッション終了時に呼ぶ。
    public func end() async {
        guard let activity = current else { return }
        let finalState = activity.content.state
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .default
        )
        current = nil
    }

    public var isActive: Bool { current != nil }

    #else
    public func start(sessionId: UUID, routineName: String?, startedAt: Date, setCount: Int = 0) {}
    public func update(currentExerciseName: String?, setCount: Int, restEndAt: Date?) async {}
    public func end() async {}
    public var isActive: Bool { false }
    #endif
}

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
        /// **Pro 限定機能**: Free プランでは何もしない（仕様書 §10）。
        public func start(
            sessionId: UUID,
            routineName: String?,
            startedAt: Date,
            setCount: Int = 0
        ) {
            guard ProGate.canUseLiveActivity else { return }
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

        /// レストタイマーをスキップしたとき、Live Activity の restEndAt だけクリアする。
        /// currentExerciseName / setCount は現在値を保持。
        public func clearRestEnd() async {
            guard let activity = current else { return }
            let currentState = activity.content.state
            let newState = WorkoutActivityAttributes.ContentState(
                currentExerciseName: currentState.currentExerciseName,
                setCount: currentState.setCount,
                restEndAt: nil
            )
            await activity.update(
                ActivityContent(state: newState, staleDate: nil)
            )
        }

        /// 相手デバイスから restTimerStart を受信したとき、Live Activity の restEndAt だけ更新する。
        /// currentExerciseName / setCount は現在値を保持。
        public func setRestEnd(_ endAt: Date) async {
            guard let activity = current else { return }
            let currentState = activity.content.state
            let newState = WorkoutActivityAttributes.ContentState(
                currentExerciseName: currentState.currentExerciseName,
                setCount: currentState.setCount,
                restEndAt: endAt
            )
            await activity.update(
                ActivityContent(state: newState, staleDate: nil)
            )
        }

        /// セッション終了時に呼ぶ。
        /// `.immediate` でロック画面 / Dynamic Island から即座に消す（`.default` は ~30 秒残るため
        /// 「終わったのに残っている」という違和感の原因になる）。
        public func end() async {
            guard let activity = current else { return }
            let finalState = activity.content.state
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            current = nil
        }

        public var isActive: Bool { current != nil }

        /// 現在進行中の Live Activity が紐付くセッション ID。未起動なら nil。
        /// 「自分の Activity だけ end する」判定に使う（誤って別セッションの Activity を end しない）。
        public var currentSessionId: UUID? { current?.attributes.sessionId }

        /// アプリ起動時に呼ぶ。ActivityKit に残存している全 Live Activity を走査し、
        /// `activeSessionIds` に含まれないものを即時 end する。
        ///
        /// クラッシュや強制終了で `end()` が呼ばれず孤児になった Activity を掃除する用途。
        /// 副次効果として、生存している Activity が見つかれば `current` に再バインドして
        /// プロセス再起動後の controller 整合性も回復する。
        public func cleanupOrphanedActivities(activeSessionIds: Set<UUID>) async {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                let sid = activity.attributes.sessionId
                if activeSessionIds.contains(sid) {
                    if current == nil {
                        current = activity
                    }
                } else {
                    await activity.end(
                        ActivityContent(state: activity.content.state, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                }
            }
        }

    #else
        public func start(sessionId: UUID, routineName: String?, startedAt: Date, setCount: Int = 0) {}
        public func update(currentExerciseName: String?, setCount: Int, restEndAt: Date?) async {}
        public func clearRestEnd() async {}
        public func setRestEnd(_ endAt: Date) async {}
        public func end() async {}
        public var isActive: Bool { false }
        public var currentSessionId: UUID? { nil }
        public func cleanupOrphanedActivities(activeSessionIds: Set<UUID>) async {}
    #endif
}

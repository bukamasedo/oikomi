import Foundation

#if os(iOS)
    import ActivityKit
#endif

/// Live Activity / Dynamic Island で表示する内容の定義。
///
/// 仕様書§4.1.4「ロック画面・Dynamic Island に現セット情報・レスト残り秒を常時表示」。
/// アプリ本体とウィジェット拡張の双方から import するため OikomiKit に配置。
#if os(iOS)
    public struct WorkoutActivityAttributes: ActivityAttributes {

        /// セッション開始時に確定する静的情報
        public let sessionId: UUID
        public let routineName: String?
        public let startedAt: Date

        public init(sessionId: UUID, routineName: String?, startedAt: Date) {
            self.sessionId = sessionId
            self.routineName = routineName
            self.startedAt = startedAt
        }

        /// 随時更新される動的状態
        public struct ContentState: Codable, Hashable {
            /// 現セットの種目名（次に記録する/直近記録した種目）
            public var currentExerciseName: String?
            /// セッション内の総セット数
            public var setCount: Int
            /// レストタイマー終了予定時刻（nil = レスト中でない）
            public var restEndAt: Date?

            public init(
                currentExerciseName: String? = nil,
                setCount: Int = 0,
                restEndAt: Date? = nil
            ) {
                self.currentExerciseName = currentExerciseName
                self.setCount = setCount
                self.restEndAt = restEndAt
            }
        }
    }
#endif

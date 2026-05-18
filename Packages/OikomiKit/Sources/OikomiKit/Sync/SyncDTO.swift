import Foundation

/// WatchConnectivity で送受信する転送オブジェクト群。
///
/// 設計方針:
/// - すべて `Codable` で JSON 化して WCSession のペイロードに乗せる
/// - SwiftData の `@Model` を直接送らず、依存しない DTO で送る（CloudKit と独立に動かすため）
/// - Exercise は端末ごとに UUID が異なるため、**name** をキーに参照する
/// - 全ペイロードを `SyncEnvelope` でラップして単一受信ハンドラで処理
public struct WorkoutSessionDTO: Codable, Sendable, Hashable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let routineId: UUID?
    public let notes: String?

    public init(
        id: UUID,
        startedAt: Date,
        endedAt: Date? = nil,
        routineId: UUID? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.routineId = routineId
        self.notes = notes
    }
}

public struct SetRecordDTO: Codable, Sendable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let exerciseName: String  // 識別キー（端末間で UUID が異なるため name で参照）
    public let order: Int
    public let weight: Double?
    public let reps: Int?
    public let durationSeconds: Int?
    public let isWarmup: Bool
    public let completedAt: Date
    /// 計画(未完了) vs 実績(完了)。後方互換のため Optional。nil は true として扱う。
    public let isCompleted: Bool?

    public init(
        id: UUID,
        sessionId: UUID,
        exerciseName: String,
        order: Int,
        weight: Double? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        isWarmup: Bool = false,
        completedAt: Date,
        isCompleted: Bool? = true
    ) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseName = exerciseName
        self.order = order
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.isWarmup = isWarmup
        self.completedAt = completedAt
        self.isCompleted = isCompleted
    }
}

/// 種目のお気に入り状態を伝える軽量 DTO。Exercise マスタ全体ではなく差分のみ送る。
public struct ExerciseFavoriteDTO: Codable, Sendable, Hashable {
    public let exerciseName: String
    public let isFavorite: Bool

    public init(exerciseName: String, isFavorite: Bool) {
        self.exerciseName = exerciseName
        self.isFavorite = isFavorite
    }
}

public struct RoutineDTO: Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let lastUsedAt: Date?
    public let exerciseNames: [String]  // 順序保持で種目名を並べる

    public init(
        id: UUID,
        name: String,
        createdAt: Date,
        lastUsedAt: Date? = nil,
        exerciseNames: [String]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.exerciseNames = exerciseNames
    }
}

/// WCSession に乗せる単一の封筒。送信側はこれを Codable で JSON 化して
/// `[String: Any]` の `data` キーに Data として詰める。
public struct SyncEnvelope: Codable, Sendable {

    public enum Kind: String, Codable, Sendable {
        case sessionUpsert        // セッション開始・終了・更新
        case setUpsert            // セット記録
        case routineUpsert        // ルーティン作成・編集
        case routineDeleted       // ルーティン削除
        case fullSyncRequest      // 受信側から「全部送って」依頼
        case fullSyncResponse     // 上記の応答
        case exerciseFavoriteUpdate  // 種目のお気に入りトグル
    }

    public let kind: Kind
    public let timestamp: Date
    public let sessions: [WorkoutSessionDTO]
    public let sets: [SetRecordDTO]
    public let routines: [RoutineDTO]
    public let deletedRoutineIds: [UUID]
    /// 後方互換のため Optional。古いバイナリは未送信なので nil で受信される。
    public let exerciseFavorites: [ExerciseFavoriteDTO]?

    public init(
        kind: Kind,
        timestamp: Date = Date(),
        sessions: [WorkoutSessionDTO] = [],
        sets: [SetRecordDTO] = [],
        routines: [RoutineDTO] = [],
        deletedRoutineIds: [UUID] = [],
        exerciseFavorites: [ExerciseFavoriteDTO]? = nil
    ) {
        self.kind = kind
        self.timestamp = timestamp
        self.sessions = sessions
        self.sets = sets
        self.routines = routines
        self.deletedRoutineIds = deletedRoutineIds
        self.exerciseFavorites = exerciseFavorites
    }
}

// MARK: - Model → DTO 変換ヘルパー（OikomiKit 内のみ）

extension WorkoutSession {
    /// SwiftData モデルから DTO を生成。
    public func makeDTO() -> WorkoutSessionDTO {
        WorkoutSessionDTO(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            routineId: routine?.id,
            notes: notes
        )
    }
}

extension SetRecord {
    public func makeDTO() -> SetRecordDTO? {
        guard let exercise else { return nil }
        guard let session else { return nil }
        return SetRecordDTO(
            id: id,
            sessionId: session.id,
            exerciseName: exercise.name,
            order: order,
            weight: weight,
            reps: reps,
            durationSeconds: durationSeconds,
            isWarmup: isWarmup,
            completedAt: completedAt,
            isCompleted: isCompleted
        )
    }
}

extension Routine {
    public func makeDTO() -> RoutineDTO {
        RoutineDTO(
            id: id,
            name: name,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            exerciseNames: orderedExercises.compactMap { $0.exercise?.name }
        )
    }
}

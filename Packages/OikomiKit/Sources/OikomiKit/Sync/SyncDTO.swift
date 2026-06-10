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

/// 種目マスタを端末間で複製するための定義 DTO。
///
/// ルーティン同期は種目を **name** で参照するが、カスタム種目（`isCustom == true`）は
/// 受信側に存在しない。これを `RoutineExerciseDTO` に同梱して送ることで、受信側が
/// 不足している種目を復元でき、ルーティンの種目が黙って脱落するのを防ぐ。
/// 旧バイナリは送らない（受信側では nil で decode され、従来どおり name 照合のみ）。
public struct ExerciseDefinitionDTO: Codable, Sendable, Hashable {
    public let name: String
    public let nameEn: String
    public let muscleGroupRawValues: [String]
    public let equipmentRawValue: String
    public let locationRawValues: [String]
    public let measurementTypeRawValue: String
    public let defaultRestSeconds: Int
    public let isCustom: Bool

    public init(
        name: String,
        nameEn: String,
        muscleGroupRawValues: [String],
        equipmentRawValue: String,
        locationRawValues: [String],
        measurementTypeRawValue: String,
        defaultRestSeconds: Int,
        isCustom: Bool
    ) {
        self.name = name
        self.nameEn = nameEn
        self.muscleGroupRawValues = muscleGroupRawValues
        self.equipmentRawValue = equipmentRawValue
        self.locationRawValues = locationRawValues
        self.measurementTypeRawValue = measurementTypeRawValue
        self.defaultRestSeconds = defaultRestSeconds
        self.isCustom = isCustom
    }
}

/// ルーティン内の種目エントリを表す DTO。`RoutineDTO.exercises` で送られる。
///
/// `RoutineExercise.id` は端末ごとに異なるため持たない（受信側は order でマッチング）。
public struct RoutineExerciseDTO: Codable, Sendable, Hashable {
    public let exerciseName: String  // 識別キー（端末間で UUID が異なるため name で参照）
    public let order: Int
    public let plannedSets: Int
    public let plannedReps: Int
    public let plannedWeight: Double?
    /// レスト秒数の上書き。旧バイナリの JSON にはキー欠落 → nil で decode され「種目デフォルトを使う」挙動になる。
    public let plannedRestSeconds: Int?
    /// 種目の完全な定義。受信側に同名種目が無い場合の復元に使う。
    /// 旧バイナリの JSON にはキー欠落 → nil で decode される。
    public let definition: ExerciseDefinitionDTO?

    public init(
        exerciseName: String,
        order: Int,
        plannedSets: Int,
        plannedReps: Int,
        plannedWeight: Double? = nil,
        plannedRestSeconds: Int? = nil,
        definition: ExerciseDefinitionDTO? = nil
    ) {
        self.exerciseName = exerciseName
        self.order = order
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.plannedRestSeconds = plannedRestSeconds
        self.definition = definition
    }
}

public struct RoutineDTO: Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let lastUsedAt: Date?
    /// 旧バイナリとの後方互換のため残す（順序保持で種目名のみ）。新バイナリは `exercises` を優先使用する。
    public let exerciseNames: [String]
    /// 種目の計画値（plannedSets/Reps/Weight）を含む新形式。古い JSON から decode すると nil。
    public let exercises: [RoutineExerciseDTO]?

    public init(
        id: UUID,
        name: String,
        createdAt: Date,
        lastUsedAt: Date? = nil,
        exerciseNames: [String],
        exercises: [RoutineExerciseDTO]? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.exerciseNames = exerciseNames
        self.exercises = exercises
    }
}

/// WCSession に乗せる単一の封筒。送信側はこれを Codable で JSON 化して
/// `[String: Any]` の `data` キーに Data として詰める。
public struct SyncEnvelope: Codable, Sendable {

    public enum Kind: String, Codable, Sendable {
        case sessionUpsert  // セッション開始・終了・更新
        case setUpsert  // セット記録
        case routineUpsert  // ルーティン作成・編集
        case routineDeleted  // ルーティン削除
        case fullSyncRequest  // 受信側から「全部送って」依頼
        case fullSyncResponse  // 上記の応答
        case exerciseFavoriteUpdate  // 種目のお気に入りトグル
        case bulkDelete  // 全データ削除（設定 → すべてのデータを削除）
        case restTimerCancel  // 片方の端末でレストをスキップ → 相手端末のローカル通知もキャンセル
        case restTimerStart  // 片方の端末でセット完了 → 相手端末のレストタイマーも起動
        case iconChange  // iPhone 設定でアプリアイコン変更 → Watch も追従
        case unitPreferenceUpdate  // iPhone↔Watch で重量単位 (kg/lb) 設定を同期。App Group は別デバイス間で共有されないため WC 経由が必須
    }

    public let kind: Kind
    public let timestamp: Date
    public let sessions: [WorkoutSessionDTO]
    public let sets: [SetRecordDTO]
    public let routines: [RoutineDTO]
    public let deletedRoutineIds: [UUID]
    /// 後方互換のため Optional。古いバイナリは未送信なので nil で受信される。
    public let exerciseFavorites: [ExerciseFavoriteDTO]?
    /// restTimerStart のみ使用。レスト終了時刻。
    public let restEndAt: Date?
    /// restTimerStart のみ使用。UI 表示用の総秒数（受信側で defaultRestSeconds を再計算しない）。
    public let restTotalSeconds: Int?
    /// restTimerStart のみ使用。直前に完了したセットの重量（kg 内部表現）。サブテキスト表示用。
    public let restCompletedWeightKg: Double?
    /// restTimerStart のみ使用。直前に完了したセットのレップ数。サブテキスト表示用。
    public let restCompletedReps: Int?
    /// iconChange のみ使用。`nil` = primary（デフォルト）に戻す。
    public let iconName: String?
    /// unitPreferenceUpdate / fullSyncResponse で使用。`WeightUnit.rawValue` を載せる。
    public let weightUnit: String?

    public init(
        kind: Kind,
        timestamp: Date = Date(),
        sessions: [WorkoutSessionDTO] = [],
        sets: [SetRecordDTO] = [],
        routines: [RoutineDTO] = [],
        deletedRoutineIds: [UUID] = [],
        exerciseFavorites: [ExerciseFavoriteDTO]? = nil,
        restEndAt: Date? = nil,
        restTotalSeconds: Int? = nil,
        restCompletedWeightKg: Double? = nil,
        restCompletedReps: Int? = nil,
        iconName: String? = nil,
        weightUnit: String? = nil
    ) {
        self.kind = kind
        self.timestamp = timestamp
        self.sessions = sessions
        self.sets = sets
        self.routines = routines
        self.deletedRoutineIds = deletedRoutineIds
        self.exerciseFavorites = exerciseFavorites
        self.restEndAt = restEndAt
        self.restTotalSeconds = restTotalSeconds
        self.restCompletedWeightKg = restCompletedWeightKg
        self.restCompletedReps = restCompletedReps
        self.iconName = iconName
        self.weightUnit = weightUnit
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
        let entries: [RoutineExerciseDTO] = orderedExercises.compactMap { routineEx in
            guard let exercise = routineEx.exercise else { return nil }
            // 種目定義を同梱し、受信側に同名種目が無くても復元できるようにする
            // （カスタム種目は受信側に存在しないため、これが無いと脱落する）。
            let definition = ExerciseDefinitionDTO(
                name: exercise.name,
                nameEn: exercise.nameEn,
                muscleGroupRawValues: exercise.muscleGroupRawValues,
                equipmentRawValue: exercise.equipmentRawValue,
                locationRawValues: exercise.locationRawValues,
                measurementTypeRawValue: exercise.measurementTypeRawValue,
                defaultRestSeconds: exercise.defaultRestSeconds,
                isCustom: exercise.isCustom
            )
            return RoutineExerciseDTO(
                exerciseName: exercise.name,
                order: routineEx.order,
                plannedSets: routineEx.plannedSets,
                plannedReps: routineEx.plannedReps,
                plannedWeight: routineEx.plannedWeight,
                plannedRestSeconds: routineEx.plannedRestSeconds,
                definition: definition
            )
        }
        return RoutineDTO(
            id: id,
            name: name,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            exerciseNames: entries.map(\.exerciseName),
            exercises: entries
        )
    }
}

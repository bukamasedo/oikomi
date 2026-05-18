import Foundation
import SwiftData

/// 種目（ベンチプレス等）のマスターデータ。
///
/// CloudKit 互換のため、すべてのプロパティに Optional or デフォルト値を持たせる。
/// enum は `String` rawValue で保存し、配列は `[String]` として永続化する。
@Model
public final class Exercise {
    public var id: UUID = UUID()
    public var name: String = ""
    public var nameEn: String = ""

    /// `MuscleGroup.rawValue` の配列
    public var muscleGroupRawValues: [String] = []

    /// `Equipment.rawValue`
    public var equipmentRawValue: String = Equipment.barbell.rawValue

    /// `Location.rawValue` の配列
    public var locationRawValues: [String] = [Location.gym.rawValue]

    /// `MeasurementType.rawValue`
    public var measurementTypeRawValue: String = MeasurementType.weightReps.rawValue

    public var defaultRestSeconds: Int = 90
    public var isCustom: Bool = false

    /// お気に入り登録。ExercisePicker で上段に固定表示するため。
    public var isFavorite: Bool = false

    @Relationship(inverse: \SetRecord.exercise)
    public var setRecords: [SetRecord]? = []

    @Relationship(inverse: \PersonalRecord.exercise)
    public var personalRecords: [PersonalRecord]? = []

    @Relationship(inverse: \RoutineExercise.exercise)
    public var routineEntries: [RoutineExercise]? = []

    public init(
        id: UUID = UUID(),
        name: String,
        nameEn: String = "",
        muscleGroups: [MuscleGroup] = [],
        equipment: Equipment = .barbell,
        locations: [Location] = [.gym],
        measurementType: MeasurementType = .weightReps,
        defaultRestSeconds: Int = 90,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.muscleGroupRawValues = muscleGroups.map(\.rawValue)
        self.equipmentRawValue = equipment.rawValue
        self.locationRawValues = locations.map(\.rawValue)
        self.measurementTypeRawValue = measurementType.rawValue
        self.defaultRestSeconds = defaultRestSeconds
        self.isCustom = isCustom
    }
}

extension Exercise {
    public var muscleGroups: [MuscleGroup] {
        get { muscleGroupRawValues.compactMap(MuscleGroup.init(rawValue:)) }
        set { muscleGroupRawValues = newValue.map(\.rawValue) }
    }

    public var equipment: Equipment {
        get { Equipment(rawValue: equipmentRawValue) ?? .barbell }
        set { equipmentRawValue = newValue.rawValue }
    }

    public var locations: [Location] {
        get { locationRawValues.compactMap(Location.init(rawValue:)) }
        set { locationRawValues = newValue.map(\.rawValue) }
    }

    public var measurementType: MeasurementType {
        get { MeasurementType(rawValue: measurementTypeRawValue) ?? .weightReps }
        set { measurementTypeRawValue = newValue.rawValue }
    }
}

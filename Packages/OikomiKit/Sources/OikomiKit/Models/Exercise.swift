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

    /// 表示用の種目名。端末の言語が英語で `nameEn` を持つ種目は英名を返す。
    ///
    /// 種目名は SwiftData に保存される「データ」であり、`Localizable.xcstrings` の
    /// 対象外。シード 873 種は `nameEn` を備えるためそれを使い、英名を持たない
    /// カスタム種目（`nameEn` 空）は日本語 `name` にフォールバックする。
    /// 検索・ソートは `name` を使い続け、表示のみここで切り替える。
    ///
    /// 言語判定はアプリが実際に解決しているローカライズ（`Bundle.main.preferredLocalizations`）
    /// に揃える。`String(localized:)` の解決基準と一致し、端末の優先言語を返す
    /// `Locale.current` を使うと UI 言語と種目名だけ食い違う恐れがあるため使わない。
    public var localizedName: String {
        let isEnglish = Bundle.main.preferredLocalizations.first?.hasPrefix("en") ?? false
        return isEnglish && !nameEn.isEmpty ? nameEn : name
    }

    /// 重量入力・記録が必要な種目か。
    /// 自重 (equipment == .bodyweight) や時間 / 距離計測は外部重量を持たない。
    /// 旧フォームで equipment と measurementType が不整合に作成された
    /// カスタム自重種目（.bodyweight + .weightReps）に対しても、equipment を
    /// 見ることで堅牢に false を返す（シードでは .bodyweight は必ず重量なし計測）。
    public var usesWeight: Bool {
        equipment != .bodyweight && measurementType == .weightReps
    }
}

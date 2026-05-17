import Foundation

/// 初回起動時に投入する種目マスタ。
///
/// v1.0 では仕様書 §4.1.4 で 100 種目を目指すが、まずは検証用に主要 6 種目から開始する。
/// 順次拡張していく。
public enum SeedData {

    public static let starterExercises: [SeedExercise] = [
        SeedExercise(
            name: "ベンチプレス",
            nameEn: "Bench Press",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .barbell,
            measurementType: .weightReps,
            defaultRestSeconds: 180
        ),
        SeedExercise(
            name: "スクワット",
            nameEn: "Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .barbell,
            measurementType: .weightReps,
            defaultRestSeconds: 180
        ),
        SeedExercise(
            name: "デッドリフト",
            nameEn: "Deadlift",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .barbell,
            measurementType: .weightReps,
            defaultRestSeconds: 180
        ),
        SeedExercise(
            name: "オーバーヘッドプレス",
            nameEn: "Overhead Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell,
            measurementType: .weightReps,
            defaultRestSeconds: 150
        ),
        SeedExercise(
            name: "懸垂",
            nameEn: "Pull-up",
            muscleGroups: [.back, .biceps],
            equipment: .bodyweight,
            measurementType: .bodyweightReps,
            defaultRestSeconds: 120
        ),
        SeedExercise(
            name: "ダンベルカール",
            nameEn: "Dumbbell Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell,
            measurementType: .weightReps,
            defaultRestSeconds: 90
        ),
    ]
}

public struct SeedExercise: Sendable {
    public let name: String
    public let nameEn: String
    public let muscleGroups: [MuscleGroup]
    public let equipment: Equipment
    public let measurementType: MeasurementType
    public let defaultRestSeconds: Int
    public let locations: [Location]

    public init(
        name: String,
        nameEn: String,
        muscleGroups: [MuscleGroup],
        equipment: Equipment,
        measurementType: MeasurementType,
        defaultRestSeconds: Int,
        locations: [Location] = [.gym]
    ) {
        self.name = name
        self.nameEn = nameEn
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.measurementType = measurementType
        self.defaultRestSeconds = defaultRestSeconds
        self.locations = locations
    }

    public func makeExercise() -> Exercise {
        Exercise(
            name: name,
            nameEn: nameEn,
            muscleGroups: muscleGroups,
            equipment: equipment,
            locations: locations,
            measurementType: measurementType,
            defaultRestSeconds: defaultRestSeconds,
            isCustom: false
        )
    }
}

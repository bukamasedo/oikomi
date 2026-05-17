import Foundation

/// 初回起動時に投入する種目マスタ。
///
/// 仕様書 §4.1.4「種目ライブラリ v1.0 で 100 種」の道のりで、まず主要 30 種を提供。
/// 部位バランス: 胸 5 / 背 5 / 肩 4 / 脚 6 / 腕 4 / 体幹 3 / 全身 3
public enum SeedData {

    public static let starterExercises: [SeedExercise] = chest + back + shoulders + legs + arms + core + fullBody

    // MARK: - 胸 (5)

    private static let chest: [SeedExercise] = [
        SeedExercise(name: "ベンチプレス", nameEn: "Bench Press",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "インクラインベンチプレス", nameEn: "Incline Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "ダンベルプレス", nameEn: "Dumbbell Press",
            muscleGroups: [.chest, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "ダンベルフライ", nameEn: "Dumbbell Fly",
            muscleGroups: [.chest],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "ディップス", nameEn: "Dips",
            muscleGroups: [.chest, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120),
    ]

    // MARK: - 背 (5)

    private static let back: [SeedExercise] = [
        SeedExercise(name: "デッドリフト", nameEn: "Deadlift",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 240),
        SeedExercise(name: "懸垂", nameEn: "Pull-up",
            muscleGroups: [.back, .biceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120),
        SeedExercise(name: "ラットプルダウン", nameEn: "Lat Pulldown",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "ベントオーバーロウ", nameEn: "Bent-over Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "シーテッドロウ", nameEn: "Seated Row",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
    ]

    // MARK: - 肩 (4)

    private static let shoulders: [SeedExercise] = [
        SeedExercise(name: "オーバーヘッドプレス", nameEn: "Overhead Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "ダンベルショルダープレス", nameEn: "Dumbbell Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "サイドレイズ", nameEn: "Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "リアレイズ", nameEn: "Rear Delt Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
    ]

    // MARK: - 脚 (6)

    private static let legs: [SeedExercise] = [
        SeedExercise(name: "スクワット", nameEn: "Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "フロントスクワット", nameEn: "Front Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "ルーマニアンデッドリフト", nameEn: "Romanian Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "レッグプレス", nameEn: "Leg Press",
            muscleGroups: [.quads, .glutes],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "ブルガリアンスクワット", nameEn: "Bulgarian Split Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "カーフレイズ", nameEn: "Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
    ]

    // MARK: - 腕 (4)

    private static let arms: [SeedExercise] = [
        SeedExercise(name: "ダンベルカール", nameEn: "Dumbbell Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "バーベルカール", nameEn: "Barbell Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "トライセプスプッシュダウン", nameEn: "Triceps Pushdown",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "ハンマーカール", nameEn: "Hammer Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
    ]

    // MARK: - 体幹 (3)

    private static let core: [SeedExercise] = [
        SeedExercise(name: "プランク", nameEn: "Plank",
            muscleGroups: [.abs, .obliques],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(name: "クランチ", nameEn: "Crunch",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60),
        SeedExercise(name: "ハンギングレッグレイズ", nameEn: "Hanging Leg Raise",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60),
    ]

    // MARK: - 全身・複合 (3)

    private static let fullBody: [SeedExercise] = [
        SeedExercise(name: "クリーン", nameEn: "Power Clean",
            muscleGroups: [.fullBody, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "ケトルベルスイング", nameEn: "Kettlebell Swing",
            muscleGroups: [.glutes, .hamstrings, .back],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "バーピー", nameEn: "Burpee",
            muscleGroups: [.fullBody],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
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

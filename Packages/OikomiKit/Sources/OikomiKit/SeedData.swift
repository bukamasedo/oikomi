import Foundation

/// 初回起動時に投入する種目マスタ。
///
/// 仕様書 §4.1.4「種目ライブラリ v1.0 で 100 種」の道のりで、まず主要 80 種を提供。
/// 部位バランス: 胸 12 / 背 12 / 肩 10 / 脚 14 / 腕 12 / 体幹 10 / 全身 6 / 前腕 4
public enum SeedData {

    public static let starterExercises: [SeedExercise] =
        chest + back + shoulders + legs + arms + core + fullBody + forearms

    // MARK: - 胸 (12)

    private static let chest: [SeedExercise] = [
        SeedExercise(name: "ベンチプレス", nameEn: "Bench Press",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "インクラインベンチプレス", nameEn: "Incline Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "デクラインベンチプレス", nameEn: "Decline Bench Press",
            muscleGroups: [.chest, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "ダンベルベンチプレス", nameEn: "Dumbbell Bench Press",
            muscleGroups: [.chest, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "インクラインダンベルプレス", nameEn: "Incline Dumbbell Press",
            muscleGroups: [.chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "ダンベルフライ", nameEn: "Dumbbell Fly",
            muscleGroups: [.chest],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "ケーブルクロスオーバー", nameEn: "Cable Crossover",
            muscleGroups: [.chest],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "ペックデック", nameEn: "Pec Deck",
            muscleGroups: [.chest],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "ディップス", nameEn: "Dips",
            muscleGroups: [.chest, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120),
        SeedExercise(name: "プッシュアップ", nameEn: "Push-up",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "インクラインプッシュアップ", nameEn: "Incline Push-up",
            muscleGroups: [.chest, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "ナロープッシュアップ", nameEn: "Narrow Push-up",
            muscleGroups: [.triceps, .chest],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
    ]

    // MARK: - 背 (12)

    private static let back: [SeedExercise] = [
        SeedExercise(name: "デッドリフト", nameEn: "Deadlift",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 240),
        SeedExercise(name: "懸垂", nameEn: "Pull-up",
            muscleGroups: [.back, .biceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120),
        SeedExercise(name: "チンアップ", nameEn: "Chin-up",
            muscleGroups: [.back, .biceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120),
        SeedExercise(name: "ラットプルダウン", nameEn: "Lat Pulldown",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "ベントオーバーロウ", nameEn: "Bent-over Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "ペンドレイロウ", nameEn: "Pendlay Row",
            muscleGroups: [.back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "シーテッドロウ", nameEn: "Seated Row",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "ダンベルロウ", nameEn: "Dumbbell Row",
            muscleGroups: [.back, .biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "Tバーロウ", nameEn: "T-Bar Row",
            muscleGroups: [.back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "フェイスプル", nameEn: "Face Pull",
            muscleGroups: [.back, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "シュラッグ", nameEn: "Shrug",
            muscleGroups: [.back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "ハイパーエクステンション", nameEn: "Hyperextension",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90),
    ]

    // MARK: - 肩 (10)

    private static let shoulders: [SeedExercise] = [
        SeedExercise(name: "オーバーヘッドプレス", nameEn: "Overhead Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "ダンベルショルダープレス", nameEn: "Dumbbell Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "アーノルドプレス", nameEn: "Arnold Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "サイドレイズ", nameEn: "Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "フロントレイズ", nameEn: "Front Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "リアレイズ", nameEn: "Rear Delt Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "ケーブルサイドレイズ", nameEn: "Cable Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "アップライトロウ", nameEn: "Upright Row",
            muscleGroups: [.shoulders, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "リバースフライ", nameEn: "Reverse Fly",
            muscleGroups: [.shoulders, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "パイクプッシュアップ", nameEn: "Pike Push-up",
            muscleGroups: [.shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
    ]

    // MARK: - 脚 (14)

    private static let legs: [SeedExercise] = [
        SeedExercise(name: "スクワット", nameEn: "Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "フロントスクワット", nameEn: "Front Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "ハイバースクワット", nameEn: "High-bar Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "ルーマニアンデッドリフト", nameEn: "Romanian Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "レッグプレス", nameEn: "Leg Press",
            muscleGroups: [.quads, .glutes],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "ハックスクワット", nameEn: "Hack Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(name: "ブルガリアンスクワット", nameEn: "Bulgarian Split Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "ランジ", nameEn: "Lunge",
            muscleGroups: [.quads, .glutes],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "ウォーキングランジ", nameEn: "Walking Lunge",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "レッグエクステンション", nameEn: "Leg Extension",
            muscleGroups: [.quads],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "レッグカール", nameEn: "Leg Curl",
            muscleGroups: [.hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "グッドモーニング", nameEn: "Good Morning",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "カーフレイズ", nameEn: "Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "シーテッドカーフレイズ", nameEn: "Seated Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
    ]

    // MARK: - 腕 (12)

    private static let arms: [SeedExercise] = [
        SeedExercise(name: "ダンベルカール", nameEn: "Dumbbell Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "バーベルカール", nameEn: "Barbell Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "ハンマーカール", nameEn: "Hammer Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "コンセントレーションカール", nameEn: "Concentration Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "プリーチャーカール", nameEn: "Preacher Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "インクラインカール", nameEn: "Incline Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "トライセプスプッシュダウン", nameEn: "Triceps Pushdown",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "ライイングトライセプスエクステンション", nameEn: "Lying Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(name: "オーバーヘッドエクステンション", nameEn: "Overhead Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "トライセプスキックバック", nameEn: "Triceps Kickback",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "クローズグリップベンチプレス", nameEn: "Close-grip Bench Press",
            muscleGroups: [.triceps, .chest],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(name: "リバースカール", nameEn: "Reverse Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
    ]

    // MARK: - 体幹 (10)

    private static let core: [SeedExercise] = [
        SeedExercise(name: "プランク", nameEn: "Plank",
            muscleGroups: [.abs, .obliques],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "サイドプランク", nameEn: "Side Plank",
            muscleGroups: [.obliques, .abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "クランチ", nameEn: "Crunch",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "ハンギングレッグレイズ", nameEn: "Hanging Leg Raise",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60),
        SeedExercise(name: "ロシアンツイスト", nameEn: "Russian Twist",
            muscleGroups: [.obliques, .abs],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "アブローラー", nameEn: "Ab Wheel Rollout",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "レッグレイズ", nameEn: "Leg Raise",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "デッドバグ", nameEn: "Dead Bug",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "バードドッグ", nameEn: "Bird Dog",
            muscleGroups: [.abs, .back],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(name: "Vアップ", nameEn: "V-Up",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
    ]

    // MARK: - 全身・コンディショニング (6)

    private static let fullBody: [SeedExercise] = [
        SeedExercise(name: "パワークリーン", nameEn: "Power Clean",
            muscleGroups: [.fullBody, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(name: "ケトルベルスイング", nameEn: "Kettlebell Swing",
            muscleGroups: [.glutes, .hamstrings, .back],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "バーピー", nameEn: "Burpee",
            muscleGroups: [.fullBody],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(name: "ファーマーズウォーク", nameEn: "Farmer's Walk",
            muscleGroups: [.fullBody, .forearms],
            equipment: .dumbbell, measurementType: .time, defaultRestSeconds: 120),
        SeedExercise(name: "サンドバッグスラム", nameEn: "Slam Ball",
            muscleGroups: [.fullBody],
            equipment: .other, measurementType: .bodyweightReps, defaultRestSeconds: 60),
        SeedExercise(name: "スレッドプッシュ", nameEn: "Sled Push",
            muscleGroups: [.fullBody, .quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 90),
    ]

    // MARK: - 前腕 (4)

    private static let forearms: [SeedExercise] = [
        SeedExercise(name: "リストカール", nameEn: "Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "リバースリストカール", nameEn: "Reverse Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(name: "デッドハング", nameEn: "Dead Hang",
            muscleGroups: [.forearms, .back],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 90),
        SeedExercise(name: "ピンチホールド", nameEn: "Pinch Hold",
            muscleGroups: [.forearms],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
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

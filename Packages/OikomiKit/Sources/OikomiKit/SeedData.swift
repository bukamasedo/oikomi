import Foundation

/// 初回起動時に投入する種目マスタ。
///
/// free-exercise-db (Public Domain / Unlicense, 873 種) からインポートしたデータを
/// Oikomi の SeedExercise 構造へマップしたもの。日本語名は自然なカタカナ表記。
/// 仕様書 §4.1.4 v1.0 で 100 種を目標としていたが、ユーザー要望により全 873 種を投入。
public enum SeedData {

    public static let starterExercises: [SeedExercise] = [
        SeedExercise(
            name: "サイクリング", nameEn: "Bicycling",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "サイクリングステーショナリー", nameEn: "Bicycling, Stationary",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "エリプティカルトレーナー", nameEn: "Elliptical Trainer",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "ジョギングトレッドミル", nameEn: "Jogging, Treadmill",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "プラウラースプリント", nameEn: "Prowler Sprint",
            muscleGroups: [.hamstrings, .calves, .chest, .glutes, .quads, .shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "リカンベントバイク", nameEn: "Recumbent Bike",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "縄跳び", nameEn: "Rope Jumping",
            muscleGroups: [.quads, .calves, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "ローイングステーショナリー", nameEn: "Rowing, Stationary",
            muscleGroups: [.quads, .biceps, .calves, .glutes, .hamstrings, .back],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "ランニングトレッドミル", nameEn: "Running, Treadmill",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "スケーティング", nameEn: "Skating",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "ステアマスター", nameEn: "Stairmaster",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "ステップミル", nameEn: "Step Mill",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "トレイルランニング/ウォーキング", nameEn: "Trail Running/Walking",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "ウォーキングトレッドミル", nameEn: "Walking, Treadmill",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "クリーン", nameEn: "Clean",
            muscleGroups: [.hamstrings, .calves, .forearms, .glutes, .back, .quads, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "クリーンデッドリフト", nameEn: "Clean Deadlift",
            muscleGroups: [.hamstrings, .forearms, .glutes, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "クリーンプル", nameEn: "Clean Pull",
            muscleGroups: [.quads, .forearms, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "クリーンシュラッグ", nameEn: "Clean Shrug",
            muscleGroups: [.back, .forearms, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "クリーン＆ジャーク", nameEn: "Clean and Jerk",
            muscleGroups: [.shoulders, .abs, .glutes, .hamstrings, .back, .quads, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "クリーンフロムブロック", nameEn: "Clean from Blocks",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .shoulders, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "フランケンシュタインスクワット", nameEn: "Frankenstein Squat",
            muscleGroups: [.quads, .abs, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ハングクリーン", nameEn: "Hang Clean",
            muscleGroups: [.quads, .calves, .forearms, .glutes, .hamstrings, .back, .shoulders],
            equipment: .barbell, measurementType: .time, defaultRestSeconds: 180),
        SeedExercise(
            name: "ハングクリーンビローニー", nameEn: "Hang Clean - Below the Knees",
            muscleGroups: [.quads, .calves, .forearms, .glutes, .hamstrings, .back, .shoulders],
            equipment: .barbell, measurementType: .time, defaultRestSeconds: 150),
        SeedExercise(
            name: "ハングスナッチ", nameEn: "Hang Snatch",
            muscleGroups: [.hamstrings, .abs, .calves, .forearms, .glutes, .back, .quads, .shoulders],
            equipment: .barbell, measurementType: .time, defaultRestSeconds: 180),
        SeedExercise(
            name: "ハングスナッチビローニー", nameEn: "Hang Snatch - Below Knees",
            muscleGroups: [.hamstrings, .abs, .calves, .forearms, .glutes, .back, .quads, .shoulders],
            equipment: .barbell, measurementType: .time, defaultRestSeconds: 180),
        SeedExercise(
            name: "ヒービングスナッチバランス", nameEn: "Heaving Snatch Balance",
            muscleGroups: [.quads, .abs, .forearms, .glutes, .hamstrings, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ジャークバランス", nameEn: "Jerk Balance",
            muscleGroups: [.shoulders, .glutes, .hamstrings, .quads, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ジャークディップスクワット", nameEn: "Jerk Dip Squat",
            muscleGroups: [.quads, .abs, .calves],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ニーリングジャンプスクワット", nameEn: "Kneeling Jump Squat",
            muscleGroups: [.glutes, .calves, .hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "マッスルスナッチ", nameEn: "Muscle Snatch",
            muscleGroups: [.hamstrings, .glutes, .back, .quads, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "オリンピックスクワット", nameEn: "Olympic Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "オーバーヘッドスクワット", nameEn: "Overhead Squat",
            muscleGroups: [.quads, .abs, .calves, .glutes, .hamstrings, .back, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "パワークリーンフロムブロック", nameEn: "Power Clean from Blocks",
            muscleGroups: [.hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "パワージャーク", nameEn: "Power Jerk",
            muscleGroups: [.quads, .abs, .calves, .glutes, .hamstrings, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "パワースナッチ", nameEn: "Power Snatch",
            muscleGroups: [.hamstrings, .calves, .glutes, .back, .quads, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "パワースナッチフロムブロック", nameEn: "Power Snatch from Blocks",
            muscleGroups: [.quads, .calves, .forearms, .glutes, .hamstrings, .back, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "プッシュプレス", nameEn: "Push Press",
            muscleGroups: [.shoulders, .quads, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "プッシュプレスビハインドネック", nameEn: "Push Press - Behind the Neck",
            muscleGroups: [.shoulders, .calves, .quads, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ラックデリバリー", nameEn: "Rack Delivery",
            muscleGroups: [.shoulders, .forearms, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ルーマニアンデッドリフトフロムディフィシット", nameEn: "Romanian Deadlift from Deficit",
            muscleGroups: [.hamstrings, .forearms, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スナッチ", nameEn: "Snatch",
            muscleGroups: [.quads, .biceps, .glutes, .hamstrings, .back, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スナッチバランス", nameEn: "Snatch Balance",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スナッチデッドリフト", nameEn: "Snatch Deadlift",
            muscleGroups: [.hamstrings, .forearms, .glutes, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スナッチシュラッグ", nameEn: "Snatch Shrug",
            muscleGroups: [.back, .forearms, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スナッチフロムブロック", nameEn: "Snatch from Blocks",
            muscleGroups: [.quads, .calves, .forearms, .glutes, .hamstrings, .back, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スプリットクリーン", nameEn: "Split Clean",
            muscleGroups: [.quads, .calves, .forearms, .glutes, .hamstrings, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スプリットジャーク", nameEn: "Split Jerk",
            muscleGroups: [.quads, .glutes, .hamstrings, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スプリットスナッチ", nameEn: "Split Snatch",
            muscleGroups: [.hamstrings, .calves, .forearms, .glutes, .back, .quads, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ワイドスタンススティッフレッグ", nameEn: "Wide Stance Stiff Legs",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "オルタネイトレッグダイアゴナルバウンド", nameEn: "Alternate Leg Diagonal Bound",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "バックワードメディシンボールスロー", nameEn: "Backward Medicine Ball Throw",
            muscleGroups: [.shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ベンチジャンプ", nameEn: "Bench Jump",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ベンチスプリント", nameEn: "Bench Sprint",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 90),
        SeedExercise(
            name: "ボックスジャンプマルチプルレスポンス", nameEn: "Box Jump (Multiple Response)",
            muscleGroups: [.hamstrings, .glutes, .calves, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ボックススキップ", nameEn: "Box Skip",
            muscleGroups: [.hamstrings, .glutes, .calves, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "カリオカクイックステップ", nameEn: "Carioca Quick Step",
            muscleGroups: [.glutes, .abs, .calves, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "キャッチとオーバーヘッドスロー", nameEn: "Catch and Overhead Throw",
            muscleGroups: [.back, .abs, .chest, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェストプッシュマルチプルレスポンス", nameEn: "Chest Push (multiple response)",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェストプッシュシングルレスポンス", nameEn: "Chest Push (single response)",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェストプッシュフロム3ポイントスタンス", nameEn: "Chest Push from 3 point stance",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェストプッシュウィズランリリース", nameEn: "Chest Push with Run Release",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .other, measurementType: .time, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "デプスジャンプリープ", nameEn: "Depth Jump Leap",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ダブルレッグヒップキック", nameEn: "Double Leg Butt Kick",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ドロッププッシュ", nameEn: "Drop Push",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ダンベルシーテッドボックスジャンプ", nameEn: "Dumbbell Seated Box Jump",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ファストスキッピング", nameEn: "Fast Skipping",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フロントボックスジャンプ", nameEn: "Front Box Jump",
            muscleGroups: [.hamstrings, .glutes, .calves, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "フロントコーンホップまたはハードルホップ", nameEn: "Front Cone Hops (or hurdle hops)",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ヘビーバッグスラスト", nameEn: "Heavy Bag Thrust",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ハードルホップ", nameEn: "Hurdle Hops",
            muscleGroups: [.hamstrings, .glutes, .calves],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "インクラインプッシュアップデプスジャンプ", nameEn: "Incline Push-Up Depth Jump",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "アイソメトリックチェストスクイーズ", nameEn: "Isometric Chest Squeezes",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ニータックジャンプ", nameEn: "Knee Tuck Jump",
            muscleGroups: [.hamstrings, .glutes, .calves, .quads],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ニーリングアームドリル", nameEn: "Kneeling Arm Drill",
            muscleGroups: [.shoulders, .abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ラテラルバウンド", nameEn: "Lateral Bound",
            muscleGroups: [.glutes, .calves, .hamstrings, .quads],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ラテラルボックスジャンプ", nameEn: "Lateral Box Jump",
            muscleGroups: [.glutes, .calves, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ラテラルコーンホップ", nameEn: "Lateral Cone Hops",
            muscleGroups: [.glutes, .calves, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "リニア3パートスタートテクニック", nameEn: "Linear 3-Part Start Technique",
            muscleGroups: [.hamstrings, .calves, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "リニアアクセラレーションウォールドリル", nameEn: "Linear Acceleration Wall Drill",
            muscleGroups: [.hamstrings, .calves, .glutes, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "リニアデプスジャンプ", nameEn: "Linear Depth Jump",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "メディシンボールチェストパス", nameEn: "Medicine Ball Chest Pass",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "メディシンボールフルツイスト", nameEn: "Medicine Ball Full Twist",
            muscleGroups: [.abs, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "メディシンボールスクープスロー", nameEn: "Medicine Ball Scoop Throw",
            muscleGroups: [.shoulders, .abs, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "マウンテンクライマー", nameEn: "Mountain Climbers",
            muscleGroups: [.quads, .chest, .hamstrings, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "ムービングクローシリーズ", nameEn: "Moving Claw Series",
            muscleGroups: [.hamstrings, .calves, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "オーバーヘッドスラム", nameEn: "Overhead Slam",
            muscleGroups: [.back],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プライオプッシュアップ", nameEn: "Plyo Push-up",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クイックリープ", nameEn: "Quick Leap",
            muscleGroups: [.quads, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "リターンプッシュフロムスタンス", nameEn: "Return Push from Stance",
            muscleGroups: [.shoulders, .chest, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ロケットジャンプ", nameEn: "Rocket Jump",
            muscleGroups: [.quads, .calves, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シザーズジャンプ", nameEn: "Scissors Jump",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドホップスプリント", nameEn: "Side Hop-Sprint",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 90),
        SeedExercise(
            name: "サイド立ち幅跳び", nameEn: "Side Standing Long Jump",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "サイドトゥーサイドボックスシャッフル", nameEn: "Side to Side Box Shuffle",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "シングルレッグヒップキック", nameEn: "Single Leg Butt Kick",
            muscleGroups: [.quads, .calves, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シングルレッグプッシュオフ", nameEn: "Single Leg Push-off",
            muscleGroups: [.quads, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "シングルコーンスプリントドリル", nameEn: "Single-Cone Sprint Drill",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 90),
        SeedExercise(
            name: "シングルレッグホッププログレッション", nameEn: "Single-Leg Hop Progression",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "シングルレッグラテラルホップ", nameEn: "Single-Leg Lateral Hop",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "シングルレッグストライドジャンプ", nameEn: "Single-Leg Stride Jump",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "スレッジハンマースイング", nameEn: "Sledgehammer Swings",
            muscleGroups: [.abs, .calves, .forearms, .back, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "スプリットジャンプ", nameEn: "Split Jump",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "立ち幅跳び", nameEn: "Standing Long Jump",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングツーアームオーバーヘッドスロー", nameEn: "Standing Two-Arm Overhead Throw",
            muscleGroups: [.shoulders, .chest, .back],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタージャンプ", nameEn: "Star Jump",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ストライドジャンプクロスオーバー", nameEn: "Stride Jump Crossover",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "スパインチェストスロー", nameEn: "Supine Chest Throw",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スパインワンアームオーバーヘッドスロー", nameEn: "Supine One-Arm Overhead Throw",
            muscleGroups: [.abs, .chest, .back, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スパインツーアームオーバーヘッドスロー", nameEn: "Supine Two-Arm Overhead Throw",
            muscleGroups: [.abs, .chest, .back, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バーティカルスイング", nameEn: "Vertical Swing",
            muscleGroups: [.hamstrings, .glutes, .quads, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "バンドグッドモーニング", nameEn: "Band Good Morning",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バンドグッドモーニングプルスルー", nameEn: "Band Good Morning (Pull Through)",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バーベルグルートブリッジ", nameEn: "Barbell Glute Bridge",
            muscleGroups: [.glutes, .calves, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルヒップスラスト", nameEn: "Barbell Hip Thrust",
            muscleGroups: [.glutes, .calves, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ベンチプレスパワーリフティング", nameEn: "Bench Press - Powerlifting",
            muscleGroups: [.triceps, .chest, .forearms, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ベンチプレスウィズチェーン", nameEn: "Bench Press with Chains",
            muscleGroups: [.triceps, .chest, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ボードプレス", nameEn: "Board Press",
            muscleGroups: [.triceps, .chest, .forearms, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ボックススクワット", nameEn: "Box Squat",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ボックススクワットウィズバンド", nameEn: "Box Squat with Bands",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "チェーンハンドルエクステンション", nameEn: "Chain Handle Extension",
            muscleGroups: [.triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "チェーンプレス", nameEn: "Chain Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "デッドリフトウィズバンド", nameEn: "Deadlift with Bands",
            muscleGroups: [.back, .forearms, .glutes, .hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "デッドリフトウィズチェーン", nameEn: "Deadlift with Chains",
            muscleGroups: [.back, .forearms, .glutes, .hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ディフィシットデッドリフト", nameEn: "Deficit Deadlift",
            muscleGroups: [.back, .forearms, .glutes, .hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ダンベルフロアプレス", nameEn: "Dumbbell Floor Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "フロアプレス", nameEn: "Floor Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "フロアプレスウィズチェーン", nameEn: "Floor Press with Chains",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "グルートハムレイズ", nameEn: "Glute Ham Raise",
            muscleGroups: [.hamstrings, .calves, .glutes],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "グッドモーニング", nameEn: "Good Morning",
            muscleGroups: [.hamstrings, .abs, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "グッドモーニングオフピン", nameEn: "Good Morning off Pins",
            muscleGroups: [.hamstrings, .abs, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ハンギングバーグッドモーニング", nameEn: "Hanging Bar Good Morning",
            muscleGroups: [.hamstrings, .abs, .glutes, .back],
            equipment: .barbell, measurementType: .time, defaultRestSeconds: 150),
        SeedExercise(
            name: "ヒップリフトウィズバンド", nameEn: "Hip Lift with Band",
            muscleGroups: [.glutes, .calves, .hamstrings],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ニーリングスクワット", nameEn: "Kneeling Squat",
            muscleGroups: [.glutes, .abs, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ピンプレス", nameEn: "Pin Presses",
            muscleGroups: [.triceps, .chest, .forearms, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ラックプルウィズバンド", nameEn: "Rack Pull with Bands",
            muscleGroups: [.back, .forearms, .glutes, .hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ラックプル", nameEn: "Rack Pulls",
            muscleGroups: [.back, .forearms, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "リバースバンドベンチプレス", nameEn: "Reverse Band Bench Press",
            muscleGroups: [.triceps, .chest, .forearms, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "リバースバンドボックススクワット", nameEn: "Reverse Band Box Squat",
            muscleGroups: [.quads, .glutes, .calves, .forearms, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "リバースバンドデッドリフト", nameEn: "Reverse Band Deadlift",
            muscleGroups: [.back, .glutes, .calves, .hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "リバースバンドパワースクワット", nameEn: "Reverse Band Power Squat",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "リバースバンドスモウデッドリフト", nameEn: "Reverse Band Sumo Deadlift",
            muscleGroups: [.hamstrings, .glutes, .calves, .forearms, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "シーテッドグッドモーニング", nameEn: "Seated Good Mornings",
            muscleGroups: [.back, .glutes],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スピードボックススクワット", nameEn: "Speed Box Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スクワットウィズバンド", nameEn: "Squat with Bands",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スクワットウィズチェーン", nameEn: "Squat with Chains",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スモウデッドリフト", nameEn: "Sumo Deadlift",
            muscleGroups: [.hamstrings, .glutes, .forearms, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スモウデッドリフトウィズバンド", nameEn: "Sumo Deadlift with Bands",
            muscleGroups: [.hamstrings, .glutes, .forearms, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スモウデッドリフトウィズチェーン", nameEn: "Sumo Deadlift with Chains",
            muscleGroups: [.hamstrings, .glutes, .forearms, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "3/4シットアップ", nameEn: "3/4 Sit-Up",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アブクランチマシン", nameEn: "Ab Crunch Machine",
            muscleGroups: [.abs],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "アブローラー", nameEn: "Ab Roller",
            muscleGroups: [.abs, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "アドバンストケトルベルウィンドミル", nameEn: "Advanced Kettlebell Windmill",
            muscleGroups: [.abs, .glutes, .hamstrings, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "エアバイク", nameEn: "Air Bike",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オルタネイトハンマーカール", nameEn: "Alternate Hammer Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "オルタネイトヒールタッチ", nameEn: "Alternate Heel Touchers",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オルタネイトインクラインダンベルカール", nameEn: "Alternate Incline Dumbbell Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "オルタネイティングケーブルショルダープレス", nameEn: "Alternating Cable Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "オルタネイティングデルトイドレイズ", nameEn: "Alternating Deltoid Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "オルタネイティングフロアプレス", nameEn: "Alternating Floor Press",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オルタネイティングハングクリーン", nameEn: "Alternating Hang Clean",
            muscleGroups: [.hamstrings, .biceps, .calves, .forearms, .glutes, .back],
            equipment: .kettlebell, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オルタネイティングケトルベルプレス", nameEn: "Alternating Kettlebell Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オルタネイティングケトルベルロウ", nameEn: "Alternating Kettlebell Row",
            muscleGroups: [.back, .biceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オルタネイティングリネゲードロウ", nameEn: "Alternating Renegade Row",
            muscleGroups: [.back, .abs, .biceps, .chest, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アンチグラビティプレス", nameEn: "Anti-Gravity Press",
            muscleGroups: [.shoulders, .back, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "アーノルドダンベルプレス", nameEn: "Arnold Dumbbell Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "アラウンドザワールド", nameEn: "Around The Worlds",
            muscleGroups: [.chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "バックフライウィズバンド", nameEn: "Back Flyes - With Bands",
            muscleGroups: [.shoulders, .back, .triceps],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バランスボード", nameEn: "Balance Board",
            muscleGroups: [.calves, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ボールレッグカール", nameEn: "Ball Leg Curl",
            muscleGroups: [.hamstrings, .calves, .glutes],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バンドアシステッドプルアップ", nameEn: "Band Assisted Pull-Up",
            muscleGroups: [.back, .abs, .forearms],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "バンドヒップアダクション", nameEn: "Band Hip Adductions",
            muscleGroups: [.glutes],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バンドプルアパート", nameEn: "Band Pull Apart",
            muscleGroups: [.shoulders, .back],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バンドスカルクラッシャー", nameEn: "Band Skull Crusher",
            muscleGroups: [.triceps],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バーベルアブロールアウト", nameEn: "Barbell Ab Rollout",
            muscleGroups: [.abs, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルアブロールアウトオンニー", nameEn: "Barbell Ab Rollout - On Knees",
            muscleGroups: [.abs, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ベンチプレス", nameEn: "Barbell Bench Press - Medium Grip",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "バーベルカール", nameEn: "Barbell Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "バーベルカールライイングアゲインストインクライン", nameEn: "Barbell Curls Lying Against An Incline",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "デッドリフト", nameEn: "Barbell Deadlift",
            muscleGroups: [.back, .calves, .forearms, .glutes, .hamstrings, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "フルスクワット", nameEn: "Barbell Full Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "バーベルギロチンベンチプレス", nameEn: "Barbell Guillotine Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "バーベルハックスクワット", nameEn: "Barbell Hack Squat",
            muscleGroups: [.quads, .calves, .forearms, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルインクラインベンチプレスミディアムグリップ", nameEn: "Barbell Incline Bench Press - Medium Grip",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "バーベルインクラインショルダーレイズ", nameEn: "Barbell Incline Shoulder Raise",
            muscleGroups: [.shoulders, .chest],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルランジ", nameEn: "Barbell Lunge",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルリアデルトロウ", nameEn: "Barbell Rear Delt Row",
            muscleGroups: [.shoulders, .biceps, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルロールアウトフロムベンチ", nameEn: "Barbell Rollout from Bench",
            muscleGroups: [.abs, .glutes, .hamstrings, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルシーテッドカーフレイズ", nameEn: "Barbell Seated Calf Raise",
            muscleGroups: [.calves],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "バーベルショルダープレス", nameEn: "Barbell Shoulder Press",
            muscleGroups: [.shoulders, .chest, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルシュラッグ", nameEn: "Barbell Shrug",
            muscleGroups: [.back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "バーベルシュラッグバックビハインド", nameEn: "Barbell Shrug Behind The Back",
            muscleGroups: [.back, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "バーベルサイドベンド", nameEn: "Barbell Side Bend",
            muscleGroups: [.abs, .back, .obliques],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "バーベルサイドスプリットスクワット", nameEn: "Barbell Side Split Squat",
            muscleGroups: [.quads, .calves, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スクワット", nameEn: "Barbell Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "バーベルスクワットトゥーベンチ", nameEn: "Barbell Squat To A Bench",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルステップアップ", nameEn: "Barbell Step Ups",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "バーベルウォーキングランジ", nameEn: "Barbell Walking Lunge",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .time, defaultRestSeconds: 150),
        SeedExercise(
            name: "バトリングロープ", nameEn: "Battling Ropes",
            muscleGroups: [.shoulders, .chest, .forearms],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ベンチディップス", nameEn: "Bench Dips",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ベンチプレスウィズバンド", nameEn: "Bench Press - With Bands",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ベントオーバーロウ", nameEn: "Bent Over Barbell Row",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "リアレイズ", nameEn: "Bent Over Dumbbell Rear Delt Raise With Head On Bench",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ベントオーバーロープーリーサイドラテラル", nameEn: "Bent Over Low-Pulley Side Lateral",
            muscleGroups: [.shoulders, .back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ベントオーバーワンアームロングバーロウ", nameEn: "Bent Over One-Arm Long Bar Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ベントオーバーツーアームロングバーロウ", nameEn: "Bent Over Two-Arm Long Bar Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ベントオーバーツーダンベルロウ", nameEn: "Bent Over Two-Dumbbell Row",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ベントオーバーツーダンベルロウウィズパームイン", nameEn: "Bent Over Two-Dumbbell Row With Palms In",
            muscleGroups: [.back, .biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ベントプレス", nameEn: "Bent Press",
            muscleGroups: [.abs, .glutes, .hamstrings, .back, .quads, .shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ベントアームバーベルプルオーバー", nameEn: "Bent-Arm Barbell Pullover",
            muscleGroups: [.back, .chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ベントアームダンベルプルオーバー", nameEn: "Bent-Arm Dumbbell Pullover",
            muscleGroups: [.chest, .back, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ベントニーヒップレイズ", nameEn: "Bent-Knee Hip Raise",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ボディトライセプスプレス", nameEn: "Body Tricep Press",
            muscleGroups: [.triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ボディアップ", nameEn: "Body-Up",
            muscleGroups: [.triceps, .abs, .forearms],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ボディウェイトフライ", nameEn: "Bodyweight Flyes",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ボディウェイトミッドロウ", nameEn: "Bodyweight Mid Row",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ボディウェイトスクワット", nameEn: "Bodyweight Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ボディウェイトウォーキングランジ", nameEn: "Bodyweight Walking Lunge",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 120),
        SeedExercise(
            name: "ボスボールケーブルクランチウィズサイドベンド", nameEn: "Bosu Ball Cable Crunch With Side Bends",
            muscleGroups: [.abs, .obliques],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ボトムアップ", nameEn: "Bottoms Up",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ボトムアップクリーンフロムハングポジション", nameEn: "Bottoms-Up Clean From The Hang Position",
            muscleGroups: [.forearms, .biceps, .shoulders],
            equipment: .kettlebell, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ボックススクワットウィズチェーン", nameEn: "Box Squat with Chains",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ブラッドフォード/ロッキープレス", nameEn: "Bradford/Rocky Presses",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ヒップリフトブリッジ", nameEn: "Butt Lift (Bridge)",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ヒップアップ", nameEn: "Butt-Ups",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バタフライ", nameEn: "Butterfly",
            muscleGroups: [.chest],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルチェストプレス", nameEn: "Cable Chest Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ケーブルクロスオーバー", nameEn: "Cable Crossover",
            muscleGroups: [.chest, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルクランチ", nameEn: "Cable Crunch",
            muscleGroups: [.abs],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルデッドリフト", nameEn: "Cable Deadlifts",
            muscleGroups: [.quads, .forearms, .glutes, .hamstrings, .back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ケーブルハンマーカールロープアタッチメント", nameEn: "Cable Hammer Curls - Rope Attachment",
            muscleGroups: [.biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルヒップアダクション", nameEn: "Cable Hip Adduction",
            muscleGroups: [.quads],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルインクラインプッシュダウン", nameEn: "Cable Incline Pushdown",
            muscleGroups: [.back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルインクライントライセプスエクステンション", nameEn: "Cable Incline Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルインターナルローテーション", nameEn: "Cable Internal Rotation",
            muscleGroups: [.shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ケーブルアイアンクロス", nameEn: "Cable Iron Cross",
            muscleGroups: [.chest],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブル柔道フリップ", nameEn: "Cable Judo Flip",
            muscleGroups: [.abs],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ケーブルライイングトライセプスエクステンション", nameEn: "Cable Lying Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルワンアームトライセプスエクステンション", nameEn: "Cable One Arm Tricep Extension",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルプリーチャーカール", nameEn: "Cable Preacher Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルリアデルトフライ", nameEn: "Cable Rear Delt Fly",
            muscleGroups: [.shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルリバースクランチ", nameEn: "Cable Reverse Crunch",
            muscleGroups: [.abs],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルロープオーバーヘッドトライセプスエクステンション", nameEn: "Cable Rope Overhead Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルロープリアデルトロウ", nameEn: "Cable Rope Rear-Delt Rows",
            muscleGroups: [.shoulders, .biceps, .back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ケーブルロシアンツイスト", nameEn: "Cable Russian Twists",
            muscleGroups: [.abs, .obliques],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ケーブルシーテッドクランチ", nameEn: "Cable Seated Crunch",
            muscleGroups: [.abs],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルシーテッドサイドレイズ", nameEn: "Cable Seated Lateral Raise",
            muscleGroups: [.shoulders, .back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルショルダープレス", nameEn: "Cable Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ケーブルシュラッグ", nameEn: "Cable Shrugs",
            muscleGroups: [.back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ケーブルリストカール", nameEn: "Cable Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "カーフプレス", nameEn: "Calf Press",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "カーフプレスオンレッグプレスマシン", nameEn: "Calf Press On The Leg Press Machine",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "カーフレイズオンダンベル", nameEn: "Calf Raise On A Dumbbell",
            muscleGroups: [.calves],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "カーフレイズ", nameEn: "Calf Raises - With Bands",
            muscleGroups: [.calves],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "カーフマシンショルダーシュラッグ", nameEn: "Calf-Machine Shoulder Shrug",
            muscleGroups: [.back],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "カードライバー", nameEn: "Car Drivers",
            muscleGroups: [.shoulders, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "チェアスクワット", nameEn: "Chair Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "チンアップ", nameEn: "Chin-Up",
            muscleGroups: [.back, .biceps, .forearms],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クリーン＆プレス", nameEn: "Clean and Press",
            muscleGroups: [.shoulders, .abs, .calves, .glutes, .hamstrings, .back, .quads, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "クロックプッシュアップ", nameEn: "Clock Push-Up",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クローズグリップバーベルベンチプレス", nameEn: "Close-Grip Barbell Bench Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "クローズグリップダンベルプレス", nameEn: "Close-Grip Dumbbell Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "クローズグリップEZバーカール", nameEn: "Close-Grip EZ Bar Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "クローズグリップEZバーカールウィズバンド", nameEn: "Close-Grip EZ-Bar Curl with Band",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "クローズグリップEZバープレス", nameEn: "Close-Grip EZ-Bar Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "クローズグリップフロントラットプルダウン", nameEn: "Close-Grip Front Lat Pulldown",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "クローズグリッププッシュアップオフオブダンベル", nameEn: "Close-Grip Push-Up off of a Dumbbell",
            muscleGroups: [.triceps, .abs, .chest, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クローズグリップスタンディングバーベルカール", nameEn: "Close-Grip Standing Barbell Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "コクーン", nameEn: "Cocoons",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "コンセントレーションカール", nameEn: "Concentration Curls",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "クロスボディハンマーカール", nameEn: "Cross Body Hammer Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "クロスオーバーウィズバンド", nameEn: "Cross Over - With Bands",
            muscleGroups: [.chest, .biceps, .shoulders],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クロスボディクランチ", nameEn: "Cross-Body Crunch",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クランチハンドオーバーヘッド", nameEn: "Crunch - Hands Overhead",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クランチレッグオンバランスボール", nameEn: "Crunch - Legs On Exercise Ball",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クランチ", nameEn: "Crunches",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "キューバンプレス", nameEn: "Cuban Press",
            muscleGroups: [.shoulders, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "デッドバグ", nameEn: "Dead Bug",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "デクラインバーベルベンチプレス", nameEn: "Decline Barbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "デクラインクローズグリップベンチトゥースカルクラッシャー", nameEn: "Decline Close-Grip Bench To Skull Crusher",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "デクラインクランチ", nameEn: "Decline Crunch",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "デクラインダンベルベンチプレス", nameEn: "Decline Dumbbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "デクラインダンベルフライ", nameEn: "Decline Dumbbell Flyes",
            muscleGroups: [.chest],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "デクラインダンベルトライセプスエクステンション", nameEn: "Decline Dumbbell Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "デクラインEZバートライセプスエクステンション", nameEn: "Decline EZ Bar Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "デクラインオブリーククランチ", nameEn: "Decline Oblique Crunch",
            muscleGroups: [.abs, .obliques],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "デクラインプッシュアップ", nameEn: "Decline Push-Up",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "デクラインリバースクランチ", nameEn: "Decline Reverse Crunch",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "デクラインスミスプレス", nameEn: "Decline Smith Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ディップマシン", nameEn: "Dip Machine",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ディップスチェストバージョン", nameEn: "Dips - Chest Version",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ディップス", nameEn: "Dips - Triceps Version",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ドンキーカーフレイズ", nameEn: "Donkey Calf Raises",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダブルケトルベルオルタネイティングハングクリーン", nameEn: "Double Kettlebell Alternating Hang Clean",
            muscleGroups: [.hamstrings, .biceps, .calves, .forearms, .glutes, .back, .quads],
            equipment: .kettlebell, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダブルケトルベルジャーク", nameEn: "Double Kettlebell Jerk",
            muscleGroups: [.shoulders, .calves, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダブルケトルベルプッシュプレス", nameEn: "Double Kettlebell Push Press",
            muscleGroups: [.shoulders, .calves, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダブルケトルベルスナッチ", nameEn: "Double Kettlebell Snatch",
            muscleGroups: [.shoulders, .glutes, .hamstrings, .quads],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 180,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダブルケトルベルウィンドミル", nameEn: "Double Kettlebell Windmill",
            muscleGroups: [.abs, .glutes, .hamstrings, .shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダウンワードフェイシングバランス", nameEn: "Downward Facing Balance",
            muscleGroups: [.glutes, .abs, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ドラッグカール", nameEn: "Drag Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ダンベルオルタネイトバイセプスカール", nameEn: "Dumbbell Alternate Bicep Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルベンチプレス", nameEn: "Dumbbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルベンチプレスウィズニュートラルグリップ", nameEn: "Dumbbell Bench Press with Neutral Grip",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルカール", nameEn: "Dumbbell Bicep Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルクリーン", nameEn: "Dumbbell Clean",
            muscleGroups: [.hamstrings, .calves, .forearms, .glutes, .back, .quads, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルフライ", nameEn: "Dumbbell Flyes",
            muscleGroups: [.chest],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルインクラインロウ", nameEn: "Dumbbell Incline Row",
            muscleGroups: [.back, .biceps, .forearms, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルインクラインショルダーレイズ", nameEn: "Dumbbell Incline Shoulder Raise",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルランジ", nameEn: "Dumbbell Lunges",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルライイングワンアームリアサイドレイズ", nameEn: "Dumbbell Lying One-Arm Rear Lateral Raise",
            muscleGroups: [.shoulders, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルライイングプロネーション", nameEn: "Dumbbell Lying Pronation",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルライイングリアサイドレイズ", nameEn: "Dumbbell Lying Rear Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルライイングスピネーション", nameEn: "Dumbbell Lying Supination",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルワンアームショルダープレス", nameEn: "Dumbbell One-Arm Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルワンアームトライセプスエクステンション", nameEn: "Dumbbell One-Arm Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルワンアームアップライトロウ", nameEn: "Dumbbell One-Arm Upright Row",
            muscleGroups: [.shoulders, .biceps, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルプローンインクラインカール", nameEn: "Dumbbell Prone Incline Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルレイズ", nameEn: "Dumbbell Raise",
            muscleGroups: [.shoulders, .biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルリアランジ", nameEn: "Dumbbell Rear Lunge",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルスケプション", nameEn: "Dumbbell Scaption",
            muscleGroups: [.shoulders, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルシーテッドワンレッグカーフレイズ", nameEn: "Dumbbell Seated One-Leg Calf Raise",
            muscleGroups: [.calves],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルショルダープレス", nameEn: "Dumbbell Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルシュラッグ", nameEn: "Dumbbell Shrug",
            muscleGroups: [.back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルサイドベンド", nameEn: "Dumbbell Side Bend",
            muscleGroups: [.abs, .obliques],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ダンベルスクワット", nameEn: "Dumbbell Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルスクワットトゥーベンチ", nameEn: "Dumbbell Squat To A Bench",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルステップアップ", nameEn: "Dumbbell Step Ups",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ダンベルトライセプスエクステンションプロネーテッドグリップ", nameEn: "Dumbbell Tricep Extension -Pronated Grip",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "EZバーカール", nameEn: "EZ-Bar Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "EZバースカルクラッシャー", nameEn: "EZ-Bar Skullcrusher",
            muscleGroups: [.triceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "エルボートゥーニー", nameEn: "Elbow to Knee",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "エレベーテッドバックランジ", nameEn: "Elevated Back Lunge",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "エレベーテッドケーブルロウ", nameEn: "Elevated Cable Rows",
            muscleGroups: [.back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "バランスボールクランチ", nameEn: "Exercise Ball Crunch",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "バランスボールプルイン", nameEn: "Exercise Ball Pull-In",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "エクステンデッドレンジワンアームケトルベルフロアプレス", nameEn: "Extended Range One-Arm Kettlebell Floor Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "エクスターナルローテーション", nameEn: "External Rotation",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "エクスターナルローテーションウィズバンド", nameEn: "External Rotation with Band",
            muscleGroups: [.shoulders],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "エクスターナルローテーションウィズケーブル", nameEn: "External Rotation with Cable",
            muscleGroups: [.shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フェイスプル", nameEn: "Face Pull",
            muscleGroups: [.shoulders, .back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "フィンガーカール", nameEn: "Finger Curls",
            muscleGroups: [.forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フラットベンチケーブルフライ", nameEn: "Flat Bench Cable Flyes",
            muscleGroups: [.chest],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フラットベンチレッグプルイン", nameEn: "Flat Bench Leg Pull-In",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フラットベンチライイングレッグレイズ", nameEn: "Flat Bench Lying Leg Raise",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フレクサーインクラインダンベルカール", nameEn: "Flexor Incline Dumbbell Curls",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フロアグルートハムレイズ", nameEn: "Floor Glute-Ham Raise",
            muscleGroups: [.hamstrings, .calves, .glutes],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フラッターキック", nameEn: "Flutter Kicks",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フリーハンドジャンプスクワット", nameEn: "Freehand Jump Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フロッグシットアップ", nameEn: "Frog Sit-Ups",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フロントスクワット", nameEn: "Front Barbell Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "フロントバーベルスクワットトゥーベンチ", nameEn: "Front Barbell Squat To A Bench",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "フロントケーブルレイズ", nameEn: "Front Cable Raise",
            muscleGroups: [.shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フロントレイズ", nameEn: "Front Dumbbell Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フロントインクラインダンベルレイズ", nameEn: "Front Incline Dumbbell Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フロントプレートレイズ", nameEn: "Front Plate Raise",
            muscleGroups: [.shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フロントレイズとプルオーバー", nameEn: "Front Raise And Pullover",
            muscleGroups: [.chest, .back, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "フロントスクワットクリーングリップ", nameEn: "Front Squat (Clean Grip)",
            muscleGroups: [.quads, .abs, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "フロントスクワットウィズツーケトルベル", nameEn: "Front Squats With Two Kettlebells",
            muscleGroups: [.quads, .calves, .glutes],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 180,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フロントツーダンベルレイズ", nameEn: "Front Two-Dumbbell Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "フルレンジオブモーションラットプルダウン", nameEn: "Full Range-Of-Motion Lat Pulldown",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ジロンダスターナムチン", nameEn: "Gironda Sternum Chins",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "グルートキックバック", nameEn: "Glute Kickback",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ゴブレットスクワット", nameEn: "Goblet Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ゴリラチン/クランチ", nameEn: "Gorilla Chin/Crunch",
            muscleGroups: [.abs, .biceps, .back],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハックスクワット", nameEn: "Hack Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ハンマーカール", nameEn: "Hammer Curls",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ハンマーグリップインクラインDBベンチプレス", nameEn: "Hammer Grip Incline DB Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ハンドスタンドプッシュアップ", nameEn: "Handstand Push-Ups",
            muscleGroups: [.shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハンギングレッグレイズ", nameEn: "Hanging Leg Raise",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハンギングパイク", nameEn: "Hanging Pike",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハイケーブルカール", nameEn: "High Cable Curls",
            muscleGroups: [.biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ヒップエクステンションウィズバンド", nameEn: "Hip Extension with Bands",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ヒップフレクションウィズバンド", nameEn: "Hip Flexion with Band",
            muscleGroups: [.quads],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハイパーエクステンションバックエクステンション", nameEn: "Hyperextensions (Back Extensions)",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ハイパーエクステンションウィズNoハイパーエクステンションベンチ", nameEn: "Hyperextensions With No Hyperextension Bench",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インクラインバーベルトライセプスエクステンション", nameEn: "Incline Barbell Triceps Extension",
            muscleGroups: [.triceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "インクラインベンチプル", nameEn: "Incline Bench Pull",
            muscleGroups: [.back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "インクラインケーブルチェストプレス", nameEn: "Incline Cable Chest Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "インクラインケーブルフライ", nameEn: "Incline Cable Flye",
            muscleGroups: [.chest, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "インクラインダンベルベンチウィズパームフェイシングイン", nameEn: "Incline Dumbbell Bench With Palms Facing In",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "インクラインダンベルカール", nameEn: "Incline Dumbbell Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "インクラインダンベルフライ", nameEn: "Incline Dumbbell Flyes",
            muscleGroups: [.chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "インクラインダンベルフライウィズツイスト", nameEn: "Incline Dumbbell Flyes - With A Twist",
            muscleGroups: [.chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "インクラインダンベルプレス", nameEn: "Incline Dumbbell Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "インクラインハンマーカール", nameEn: "Incline Hammer Curls",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "インクラインインナーバイセプスカール", nameEn: "Incline Inner Biceps Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "インクラインプッシュアップ", nameEn: "Incline Push-Up",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インクラインプッシュアップクローズグリップ", nameEn: "Incline Push-Up Close-Grip",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インクラインプッシュアップミディアム", nameEn: "Incline Push-Up Medium",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インクラインプッシュアップリバースグリップ", nameEn: "Incline Push-Up Reverse Grip",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インクラインプッシュアップワイド", nameEn: "Incline Push-Up Wide",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インターナルローテーションウィズバンド", nameEn: "Internal Rotation with Band",
            muscleGroups: [.shoulders],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インバーテッドロウ", nameEn: "Inverted Row",
            muscleGroups: [.back],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "インバーテッドロウウィズストラップ", nameEn: "Inverted Row with Straps",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "アイアンクロス", nameEn: "Iron Cross",
            muscleGroups: [.shoulders, .chest, .glutes, .hamstrings, .back, .quads],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "アイソメトリックネックエクササイズフロントとバック", nameEn: "Isometric Neck Exercise - Front And Back",
            muscleGroups: [.fullBody],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アイソメトリックネックエクササイズサイド", nameEn: "Isometric Neck Exercise - Sides",
            muscleGroups: [.fullBody],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アイソメトリックワイパー", nameEn: "Isometric Wipers",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "JMプレス", nameEn: "JM Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ジャックナイフシットアップ", nameEn: "Jackknife Sit-Up",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ジャンダシットアップ", nameEn: "Janda Sit-Up",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ジェファーソンスクワット", nameEn: "Jefferson Squats",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ケトルベルアーノルドプレス", nameEn: "Kettlebell Arnold Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルデッドクリーン", nameEn: "Kettlebell Dead Clean",
            muscleGroups: [.hamstrings, .calves, .glutes, .back, .quads],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルフィギュア8", nameEn: "Kettlebell Figure 8",
            muscleGroups: [.abs, .hamstrings, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルハングクリーン", nameEn: "Kettlebell Hang Clean",
            muscleGroups: [.hamstrings, .calves, .glutes, .back, .shoulders],
            equipment: .kettlebell, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルワンレッグドデッドリフト", nameEn: "Kettlebell One-Legged Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 180,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルパスビトウィーンレッグ", nameEn: "Kettlebell Pass Between The Legs",
            muscleGroups: [.abs, .glutes, .hamstrings, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルパイレートシップ", nameEn: "Kettlebell Pirate Ships",
            muscleGroups: [.shoulders, .abs],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルピストルスクワット", nameEn: "Kettlebell Pistol Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルシーテッドプレス", nameEn: "Kettlebell Seated Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルシーソープレス", nameEn: "Kettlebell Seesaw Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルスモウハイプル", nameEn: "Kettlebell Sumo High Pull",
            muscleGroups: [.back, .glutes, .hamstrings, .quads, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルスラスター", nameEn: "Kettlebell Thruster",
            muscleGroups: [.shoulders, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルターキッシュゲットアップランジスタイル", nameEn: "Kettlebell Turkish Get-Up (Lunge style)",
            muscleGroups: [.shoulders, .abs, .hamstrings, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルターキッシュゲットアップスクワットスタイル", nameEn: "Kettlebell Turkish Get-Up (Squat style)",
            muscleGroups: [.shoulders, .abs, .calves, .hamstrings, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ケトルベルウィンドミル", nameEn: "Kettlebell Windmill",
            muscleGroups: [.abs, .glutes, .hamstrings, .shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "キッピングマッスルアップ", nameEn: "Kipping Muscle Up",
            muscleGroups: [.back, .abs, .biceps, .forearms, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ニー/ヒップレイズオンパラレルバー", nameEn: "Knee/Hip Raise On Parallel Bars",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ニーリングケーブルクランチウィズオルタネイティングオブリークツイスト", nameEn: "Kneeling Cable Crunch With Alternating Oblique Twists",
            muscleGroups: [.abs, .obliques],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ニーリングケーブルトライセプスエクステンション", nameEn: "Kneeling Cable Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ニーリングハイプーリーロウ", nameEn: "Kneeling High Pulley Row",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ニーリングシングルアームハイプーリーロウ", nameEn: "Kneeling Single-Arm High Pulley Row",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ランドマイン180's", nameEn: "Landmine 180's",
            muscleGroups: [.abs, .glutes, .back, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ランドマインリニアジャマー", nameEn: "Landmine Linear Jammer",
            muscleGroups: [.shoulders, .abs, .calves, .chest, .hamstrings, .quads, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "サイドレイズウィズバンド", nameEn: "Lateral Raise - With Bands",
            muscleGroups: [.shoulders],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "レッグエクステンション", nameEn: "Leg Extensions",
            muscleGroups: [.quads],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "レッグリフト", nameEn: "Leg Lift",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "レッグプレス", nameEn: "Leg Press",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "レッグプルイン", nameEn: "Leg Pull-In",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "レッグオーバーフロアプレス", nameEn: "Leg-Over Floor Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "レバレッジチェストプレス", nameEn: "Leverage Chest Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "レバレッジデッドリフト", nameEn: "Leverage Deadlift",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "レバレッジデクラインチェストプレス", nameEn: "Leverage Decline Chest Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "レバレッジハイロウ", nameEn: "Leverage High Row",
            muscleGroups: [.back],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "レバレッジインクラインチェストプレス", nameEn: "Leverage Incline Chest Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "レバレッジアイソロウ", nameEn: "Leverage Iso Row",
            muscleGroups: [.back, .biceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "レバレッジショルダープレス", nameEn: "Leverage Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "レバレッジシュラッグ", nameEn: "Leverage Shrug",
            muscleGroups: [.back, .forearms],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ロンドンブリッジ", nameEn: "London Bridges",
            muscleGroups: [.back, .biceps, .forearms],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ローケーブルクロスオーバー", nameEn: "Low Cable Crossover",
            muscleGroups: [.chest, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ローケーブルトライセプスエクステンション", nameEn: "Low Cable Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ロープーリーロウトゥーネック", nameEn: "Low Pulley Row To Neck",
            muscleGroups: [.shoulders, .biceps, .back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ランジパススルー", nameEn: "Lunge Pass Through",
            muscleGroups: [.hamstrings, .calves, .glutes, .quads],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ランジスプリント", nameEn: "Lunge Sprint",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 120),
        SeedExercise(
            name: "ライイングケーブルカール", nameEn: "Lying Cable Curl",
            muscleGroups: [.biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングカンバードバーベルロウ", nameEn: "Lying Cambered Barbell Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングクローズグリップバーカールオンハイプーリー", nameEn: "Lying Close-Grip Bar Curl On High Pulley",
            muscleGroups: [.biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングクローズグリップバーベルトライセプスエクステンションビハインドヘッド",
            nameEn: "Lying Close-Grip Barbell Triceps Extension Behind The Head",
            muscleGroups: [.triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングクローズグリップバーベルトライセプスプレストゥーチン", nameEn: "Lying Close-Grip Barbell Triceps Press To Chin",
            muscleGroups: [.triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングダンベルトライセプスエクステンション", nameEn: "Lying Dumbbell Tricep Extension",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングフェイスダウンプレートネックレジスタンス", nameEn: "Lying Face Down Plate Neck Resistance",
            muscleGroups: [.fullBody],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングフェイスアッププレートネックレジスタンス", nameEn: "Lying Face Up Plate Neck Resistance",
            muscleGroups: [.fullBody],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングハイベンチバーベルカール", nameEn: "Lying High Bench Barbell Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングレッグカール", nameEn: "Lying Leg Curls",
            muscleGroups: [.hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングマシンスクワット", nameEn: "Lying Machine Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ライイングワンアームサイドレイズ", nameEn: "Lying One-Arm Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングリアデルトレイズ", nameEn: "Lying Rear Delt Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングスパインダンベルカール", nameEn: "Lying Supine Dumbbell Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ライイングTバーロウ", nameEn: "Lying T-Bar Row",
            muscleGroups: [.back, .biceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ライイングトライセプスプレス", nameEn: "Lying Triceps Press",
            muscleGroups: [.triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "マシンベンチプレス", nameEn: "Machine Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "マシンバイセプスカール", nameEn: "Machine Bicep Curl",
            muscleGroups: [.biceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "マシンプリーチャーカール", nameEn: "Machine Preacher Curls",
            muscleGroups: [.biceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "マシンショルダーミリタリープレス", nameEn: "Machine Shoulder (Military) Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "マシントライセプスエクステンション", nameEn: "Machine Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ミドルバックシュラッグ", nameEn: "Middle Back Shrug",
            muscleGroups: [.back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ミックスグリップチン", nameEn: "Mixed Grip Chin",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "モンスターウォーク", nameEn: "Monster Walk",
            muscleGroups: [.glutes],
            equipment: .band, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "マッスルアップ", nameEn: "Muscle Up",
            muscleGroups: [.back, .abs, .biceps, .forearms, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ナロースタンスハックスクワット", nameEn: "Narrow Stance Hack Squats",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ナロースタンスレッグプレス", nameEn: "Narrow Stance Leg Press",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ナロースタンススクワット", nameEn: "Narrow Stance Squats",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ナチュラルグルートハムレイズ", nameEn: "Natural Glute Ham Raise",
            muscleGroups: [.hamstrings, .calves, .glutes, .back],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ネックプレス", nameEn: "Neck Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "オブリーククランチ", nameEn: "Oblique Crunches",
            muscleGroups: [.abs, .obliques],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オブリーククランチオンフロア", nameEn: "Oblique Crunches - On The Floor",
            muscleGroups: [.abs, .obliques],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームチンアップ", nameEn: "One Arm Chin-Up",
            muscleGroups: [.back, .biceps, .forearms],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ワンアームダンベルベンチプレス", nameEn: "One Arm Dumbbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ワンアームダンベルプリーチャーカール", nameEn: "One Arm Dumbbell Preacher Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ワンアームフロアプレス", nameEn: "One Arm Floor Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ワンアームラットプルダウン", nameEn: "One Arm Lat Pulldown",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ワンアームプロネーテッドダンベルトライセプスエクステンション", nameEn: "One Arm Pronated Dumbbell Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ワンアームスピネーテッドダンベルトライセプスエクステンション", nameEn: "One Arm Supinated Dumbbell Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ワンレッグバーベルスクワット", nameEn: "One Leg Barbell Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ワンアームダンベルロウ", nameEn: "One-Arm Dumbbell Row",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ワンアームフラットベンチダンベルフライ", nameEn: "One-Arm Flat Bench Dumbbell Flye",
            muscleGroups: [.chest],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ワンアームハイプーリーケーブルサイドベンド", nameEn: "One-Arm High-Pulley Cable Side Bends",
            muscleGroups: [.abs, .obliques],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ワンアームインクラインサイドレイズ", nameEn: "One-Arm Incline Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ワンアームケトルベルクリーン", nameEn: "One-Arm Kettlebell Clean",
            muscleGroups: [.hamstrings, .glutes, .back, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルクリーン＆ジャーク", nameEn: "One-Arm Kettlebell Clean and Jerk",
            muscleGroups: [.shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 180,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルフロアプレス", nameEn: "One-Arm Kettlebell Floor Press",
            muscleGroups: [.chest, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルジャーク", nameEn: "One-Arm Kettlebell Jerk",
            muscleGroups: [.shoulders, .calves, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルミリタリープレストゥーサイド", nameEn: "One-Arm Kettlebell Military Press To The Side",
            muscleGroups: [.shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルパラプレス", nameEn: "One-Arm Kettlebell Para Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルプッシュプレス", nameEn: "One-Arm Kettlebell Push Press",
            muscleGroups: [.shoulders, .calves, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルロウ", nameEn: "One-Arm Kettlebell Row",
            muscleGroups: [.back, .biceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルスナッチ", nameEn: "One-Arm Kettlebell Snatch",
            muscleGroups: [.shoulders, .calves, .glutes, .hamstrings, .back, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 180,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルスプリットジャーク", nameEn: "One-Arm Kettlebell Split Jerk",
            muscleGroups: [.shoulders, .glutes, .hamstrings, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルスプリットスナッチ", nameEn: "One-Arm Kettlebell Split Snatch",
            muscleGroups: [.shoulders, .hamstrings, .quads],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 180,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームケトルベルスイング", nameEn: "One-Arm Kettlebell Swings",
            muscleGroups: [.hamstrings, .calves, .glutes, .back, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームロングバーロウ", nameEn: "One-Arm Long Bar Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ワンアームメディシンボールスラム", nameEn: "One-Arm Medicine Ball Slam",
            muscleGroups: [.abs, .back, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームオープンパームケトルベルクリーン", nameEn: "One-Arm Open Palm Kettlebell Clean",
            muscleGroups: [.hamstrings, .forearms, .glutes, .back, .quads, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームオーバーヘッドケトルベルスクワット", nameEn: "One-Arm Overhead Kettlebell Squats",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームサイドデッドリフト", nameEn: "One-Arm Side Deadlift",
            muscleGroups: [.quads, .abs, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ワンアームサイドラテラル", nameEn: "One-Arm Side Laterals",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ワンレッグドケーブルキックバック", nameEn: "One-Legged Cable Kickback",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "オープンパームケトルベルクリーン", nameEn: "Open Palm Kettlebell Clean",
            muscleGroups: [.hamstrings, .glutes, .back, .quads, .shoulders],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オーティスアップ", nameEn: "Otis-Up",
            muscleGroups: [.abs, .chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "オーバーヘッドケーブルカール", nameEn: "Overhead Cable Curl",
            muscleGroups: [.biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "パロフプレス", nameEn: "Pallof Press",
            muscleGroups: [.abs, .chest, .shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "パロフプレスウィズローテーション", nameEn: "Pallof Press With Rotation",
            muscleGroups: [.abs, .chest, .shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "パームダウンダンベルリストカールオーバーベンチ", nameEn: "Palms-Down Dumbbell Wrist Curl Over A Bench",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "パームダウンリストカールオーバーベンチ", nameEn: "Palms-Down Wrist Curl Over A Bench",
            muscleGroups: [.forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "パームアップバーベルリストカールオーバーベンチ", nameEn: "Palms-Up Barbell Wrist Curl Over A Bench",
            muscleGroups: [.forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "パームアップダンベルリストカールオーバーベンチ", nameEn: "Palms-Up Dumbbell Wrist Curl Over A Bench",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "パラレルバーディップ", nameEn: "Parallel Bar Dip",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "フィジオボールヒップブリッジ", nameEn: "Physioball Hip Bridge",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プランク", nameEn: "Plank",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プレートピンチ", nameEn: "Plate Pinch",
            muscleGroups: [.forearms],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "プレートツイスト", nameEn: "Plate Twist",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "プラットフォームハムストリングスライド", nameEn: "Platform Hamstring Slides",
            muscleGroups: [.hamstrings, .glutes],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "プリエダンベルスクワット", nameEn: "Plie Dumbbell Squat",
            muscleGroups: [.quads, .abs, .calves, .glutes, .hamstrings],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "プライオケトルベルプッシュアップ", nameEn: "Plyo Kettlebell Pushups",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "パワークリーン", nameEn: "Power Clean",
            muscleGroups: [.hamstrings, .calves, .forearms, .glutes, .back, .quads, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "パワーパーシャル", nameEn: "Power Partials",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "プリーチャーカール", nameEn: "Preacher Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "プリーチャーハンマーダンベルカール", nameEn: "Preacher Hammer Dumbbell Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "プレスシットアップ", nameEn: "Press Sit-Up",
            muscleGroups: [.abs, .chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "プローンマニュアルハムストリング", nameEn: "Prone Manual Hamstring",
            muscleGroups: [.hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "プルスルー", nameEn: "Pull Through",
            muscleGroups: [.glutes, .hamstrings, .back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "懸垂", nameEn: "Pullups",
            muscleGroups: [.back, .biceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プッシュアップトゥーサイドプランク", nameEn: "Push Up to Side Plank",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プッシュアップワイド", nameEn: "Push-Up Wide",
            muscleGroups: [.chest, .abs, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プッシュアップクローズトライセプスポジション", nameEn: "Push-Ups - Close Triceps Position",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プッシュアップウィズフィートエレベーテッド", nameEn: "Push-Ups With Feet Elevated",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プッシュアップウィズフィートオンバランスボール", nameEn: "Push-Ups With Feet On An Exercise Ball",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プッシュアップ", nameEn: "Pushups",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "プッシュアップクローズとワイドハンドポジション", nameEn: "Pushups (Close and Wide Hand Positions)",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "リバースバーベルカール", nameEn: "Reverse Barbell Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバースバーベルプリーチャーカール", nameEn: "Reverse Barbell Preacher Curls",
            muscleGroups: [.biceps, .forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバースケーブルカール", nameEn: "Reverse Cable Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバースクランチ", nameEn: "Reverse Crunch",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "リバースフライ", nameEn: "Reverse Flyes",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバースフライウィズエクスターナルローテーション", nameEn: "Reverse Flyes With External Rotation",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバースグリップベントオーバーロウ", nameEn: "Reverse Grip Bent-Over Rows",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "リバースグリップトライセプスプッシュダウン", nameEn: "Reverse Grip Triceps Pushdown",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバースハイパーエクステンション", nameEn: "Reverse Hyperextension",
            muscleGroups: [.hamstrings, .calves, .glutes],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 90),
        SeedExercise(
            name: "リバースマシンフライ", nameEn: "Reverse Machine Flyes",
            muscleGroups: [.shoulders],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバースプレートカール", nameEn: "Reverse Plate Curls",
            muscleGroups: [.biceps, .forearms],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リバーストライセプスベンチプレス", nameEn: "Reverse Triceps Bench Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "リングディップス", nameEn: "Ring Dips",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ロッキングスタンディングカーフレイズ", nameEn: "Rocking Standing Calf Raise",
            muscleGroups: [.calves],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ロッキープルアップ/プルダウン", nameEn: "Rocky Pull-Ups/Pulldowns",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ルーマニアンデッドリフト", nameEn: "Romanian Deadlift",
            muscleGroups: [.hamstrings, .calves, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ロープクライム", nameEn: "Rope Climb",
            muscleGroups: [.back, .biceps, .forearms, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ロープクランチ", nameEn: "Rope Crunch",
            muscleGroups: [.abs],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ロープストレートアームプルダウン", nameEn: "Rope Straight-Arm Pulldown",
            muscleGroups: [.back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ロシアンツイスト", nameEn: "Russian Twist",
            muscleGroups: [.abs, .back, .obliques],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スカプラプルアップ", nameEn: "Scapular Pull-Up",
            muscleGroups: [.back],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドバンドハムストリングカール", nameEn: "Seated Band Hamstring Curl",
            muscleGroups: [.hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドバーベルミリタリープレス", nameEn: "Seated Barbell Military Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "シーテッドバーベルツイスト", nameEn: "Seated Barbell Twist",
            muscleGroups: [.abs],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドベントオーバーワンアームダンベルトライセプスエクステンション", nameEn: "Seated Bent-Over One-Arm Dumbbell Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドベントオーバーリアデルトレイズ", nameEn: "Seated Bent-Over Rear Delt Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドベントオーバーツーアームダンベルトライセプスエクステンション", nameEn: "Seated Bent-Over Two-Arm Dumbbell Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドロウ", nameEn: "Seated Cable Rows",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "シーテッドケーブルショルダープレス", nameEn: "Seated Cable Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "シーテッドカーフレイズ", nameEn: "Seated Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドクローズグリップコンセントレーションバーベルカール", nameEn: "Seated Close-Grip Concentration Barbell Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドダンベルカール", nameEn: "Seated Dumbbell Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドダンベルインナーバイセプスカール", nameEn: "Seated Dumbbell Inner Biceps Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドダンベルパームダウンリストカール", nameEn: "Seated Dumbbell Palms-Down Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドダンベルパームアップリストカール", nameEn: "Seated Dumbbell Palms-Up Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドダンベルプレス", nameEn: "Seated Dumbbell Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "シーテッドフラットベンチレッグプルイン", nameEn: "Seated Flat Bench Leg Pull-In",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドヘッドハーネスネックレジスタンス", nameEn: "Seated Head Harness Neck Resistance",
            muscleGroups: [.fullBody],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドレッグカール", nameEn: "Seated Leg Curl",
            muscleGroups: [.hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドレッグタック", nameEn: "Seated Leg Tucks",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドワンアームダンベルパームダウンリストカール", nameEn: "Seated One-Arm Dumbbell Palms-Down Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドワンアームダンベルパームアップリストカール", nameEn: "Seated One-Arm Dumbbell Palms-Up Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドワンアームケーブルプーリーロウ", nameEn: "Seated One-arm Cable Pulley Rows",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "シーテッドパームアップバーベルリストカール", nameEn: "Seated Palm-Up Barbell Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドパームダウンバーベルリストカール", nameEn: "Seated Palms-Down Barbell Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドサイドサイドレイズ", nameEn: "Seated Side Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドトライセプスプレス", nameEn: "Seated Triceps Press",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーテッドツーアームパームアップロープーリーリストカール", nameEn: "Seated Two-Arm Palms-Up Low-Pulley Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シーソープレスオルタネイティングサイドプレス", nameEn: "See-Saw Press (Alternating Side Press)",
            muscleGroups: [.shoulders, .abs, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ショットガンロウ", nameEn: "Shotgun Row",
            muscleGroups: [.back, .biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ショルダープレスウィズバンド", nameEn: "Shoulder Press - With Bands",
            muscleGroups: [.shoulders, .triceps],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドプランク", nameEn: "Side Bridge",
            muscleGroups: [.abs, .shoulders],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 90,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドジャックナイフ", nameEn: "Side Jackknife",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドレイズ", nameEn: "Side Lateral Raise",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "サイドラテラルトゥーフロントレイズ", nameEn: "Side Laterals to Front Raise",
            muscleGroups: [.shoulders, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "サイドトゥーサイドチン", nameEn: "Side To Side Chins",
            muscleGroups: [.back, .biceps, .forearms, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "シングルダンベルレイズ", nameEn: "Single Dumbbell Raise",
            muscleGroups: [.shoulders, .forearms, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シングルレッググルートブリッジ", nameEn: "Single Leg Glute Bridge",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シングルアームケーブルクロスオーバー", nameEn: "Single-Arm Cable Crossover",
            muscleGroups: [.chest],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シングルアームリニアジャマー", nameEn: "Single-Arm Linear Jammer",
            muscleGroups: [.shoulders, .chest, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "シングルアームプッシュアップ", nameEn: "Single-Arm Push-Up",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シングルレッグハイボックススクワット", nameEn: "Single-Leg High Box Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "シングルレッグレッグエクステンション", nameEn: "Single-Leg Leg Extension",
            muscleGroups: [.quads],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "シットアップ", nameEn: "Sit-Up",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スレッドオーバーヘッドバックワードウォーク", nameEn: "Sled Overhead Backward Walk",
            muscleGroups: [.shoulders, .calves, .back, .quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 120),
        SeedExercise(
            name: "スレッドオーバーヘッドトライセプスエクステンション", nameEn: "Sled Overhead Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スレッドリバースフライ", nameEn: "Sled Reverse Flye",
            muscleGroups: [.shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スレッドロウ", nameEn: "Sled Row",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスインクラインショルダーレイズ", nameEn: "Smith Incline Shoulder Raise",
            muscleGroups: [.shoulders, .chest],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スミスマシンバックビハインドシュラッグ", nameEn: "Smith Machine Behind the Back Shrug",
            muscleGroups: [.back, .shoulders],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スミスマシンベンチプレス", nameEn: "Smith Machine Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンベントオーバーロウ", nameEn: "Smith Machine Bent Over Row",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンカーフレイズ", nameEn: "Smith Machine Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スミスマシンクローズグリップベンチプレス", nameEn: "Smith Machine Close-Grip Bench Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンデクラインプレス", nameEn: "Smith Machine Decline Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンハングパワークリーン", nameEn: "Smith Machine Hang Power Clean",
            muscleGroups: [.hamstrings, .glutes, .back, .quads, .shoulders],
            equipment: .machine, measurementType: .time, defaultRestSeconds: 180),
        SeedExercise(
            name: "スミスマシンヒップレイズ", nameEn: "Smith Machine Hip Raise",
            muscleGroups: [.abs],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スミスマシンインクラインベンチプレス", nameEn: "Smith Machine Incline Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンレッグプレス", nameEn: "Smith Machine Leg Press",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンワンアームアップライトロウ", nameEn: "Smith Machine One-Arm Upright Row",
            muscleGroups: [.shoulders, .biceps, .back],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンオーバーヘッドショルダープレス", nameEn: "Smith Machine Overhead Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンピストルスクワット", nameEn: "Smith Machine Pistol Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンリバースカーフレイズ", nameEn: "Smith Machine Reverse Calf Raises",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スミスマシンスクワット", nameEn: "Smith Machine Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスマシンスティッフレッグドデッドリフト", nameEn: "Smith Machine Stiff-Legged Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スミスマシンアップライトロウ", nameEn: "Smith Machine Upright Row",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スミスシングルレッグスプリットスクワット", nameEn: "Smith Single-Leg Split Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スナッチプル", nameEn: "Snatch Pull",
            muscleGroups: [.hamstrings, .calves, .glutes, .back, .quads],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スピードバンドオーバーヘッドトライセプス", nameEn: "Speed Band Overhead Triceps",
            muscleGroups: [.triceps],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スピードスクワット", nameEn: "Speed Squats",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スペルキャスター", nameEn: "Spell Caster",
            muscleGroups: [.abs, .glutes, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スパイダークロール", nameEn: "Spider Crawl",
            muscleGroups: [.abs, .chest, .shoulders, .triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スパイダーカール", nameEn: "Spider Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スプリットスクワットウィズダンベル", nameEn: "Split Squat with Dumbbells",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スクワットジャーク", nameEn: "Squat Jerk",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スクワットウィズプレートムーバー", nameEn: "Squat with Plate Movers",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スクワットウィズバンド（2）", nameEn: "Squats - With Bands",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングオルタネイティングダンベルプレス", nameEn: "Standing Alternating Dumbbell Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングバーベルカーフレイズ", nameEn: "Standing Barbell Calf Raise",
            muscleGroups: [.calves],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングバーベルプレスビハインドネック", nameEn: "Standing Barbell Press Behind Neck",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スタンディングベントオーバーワンアームダンベルトライセプスエクステンション",
            nameEn: "Standing Bent-Over One-Arm Dumbbell Triceps Extension",
            muscleGroups: [.triceps, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングベントオーバーツーアームダンベルトライセプスエクステンション",
            nameEn: "Standing Bent-Over Two-Arm Dumbbell Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングバイセプスケーブルカール", nameEn: "Standing Biceps Cable Curl",
            muscleGroups: [.biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングブラッドフォードプレス", nameEn: "Standing Bradford Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スタンディングケーブルチェストプレス", nameEn: "Standing Cable Chest Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングケーブルリフト", nameEn: "Standing Cable Lift",
            muscleGroups: [.abs, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングケーブルウッドチョップ", nameEn: "Standing Cable Wood Chop",
            muscleGroups: [.abs, .shoulders, .obliques],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングカーフレイズ", nameEn: "Standing Calf Raises",
            muscleGroups: [.calves],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングコンセントレーションカール", nameEn: "Standing Concentration Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングダンベルカーフレイズ", nameEn: "Standing Dumbbell Calf Raise",
            muscleGroups: [.calves],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングダンベルプレス", nameEn: "Standing Dumbbell Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングダンベルリバースカール", nameEn: "Standing Dumbbell Reverse Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングダンベルストレートアームフロントデルトレイズアバブヘッド",
            nameEn: "Standing Dumbbell Straight-Arm Front Delt Raise Above Head",
            muscleGroups: [.shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングダンベルトライセプスエクステンション", nameEn: "Standing Dumbbell Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングダンベルアップライトロウ", nameEn: "Standing Dumbbell Upright Row",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングフロントバーベルレイズオーバーヘッド", nameEn: "Standing Front Barbell Raise Over Head",
            muscleGroups: [.shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングインナーバイセプスカール", nameEn: "Standing Inner-Biceps Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングレッグカール", nameEn: "Standing Leg Curl",
            muscleGroups: [.hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングロープーリーデルトイドレイズ", nameEn: "Standing Low-Pulley Deltoid Raise",
            muscleGroups: [.shoulders, .forearms],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングロープーリーワンアームトライセプスエクステンション", nameEn: "Standing Low-Pulley One-Arm Triceps Extension",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ミリタリープレス", nameEn: "Standing Military Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スタンディングオリンピックプレートハンドスクイーズ", nameEn: "Standing Olympic Plate Hand Squeeze",
            muscleGroups: [.forearms, .biceps],
            equipment: .other, measurementType: .time, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングワンアームケーブルカール", nameEn: "Standing One-Arm Cable Curl",
            muscleGroups: [.biceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングワンアームダンベルカールオーバーインクラインベンチ", nameEn: "Standing One-Arm Dumbbell Curl Over Incline Bench",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングワンアームダンベルトライセプスエクステンション", nameEn: "Standing One-Arm Dumbbell Triceps Extension",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングオーバーヘッドバーベルトライセプスエクステンション", nameEn: "Standing Overhead Barbell Triceps Extension",
            muscleGroups: [.triceps, .shoulders],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングパームインワンアームダンベルプレス", nameEn: "Standing Palm-In One-Arm Dumbbell Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングパームインダンベルプレス", nameEn: "Standing Palms-In Dumbbell Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スタンディングパームアップバーベルバックビハインドリストカール", nameEn: "Standing Palms-Up Barbell Behind The Back Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングロープクランチ", nameEn: "Standing Rope Crunch",
            muscleGroups: [.abs],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "スタンディングタオルトライセプスエクステンション", nameEn: "Standing Towel Triceps Extension",
            muscleGroups: [.triceps],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ステップアップウィズニーレイズ", nameEn: "Step-up with Knee Raise",
            muscleGroups: [.glutes, .hamstrings, .quads],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スティッフレッグバーベルグッドモーニング", nameEn: "Stiff Leg Barbell Good Morning",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "スティッフレッグドバーベルデッドリフト", nameEn: "Stiff-Legged Barbell Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スティッフレッグドダンベルデッドリフト", nameEn: "Stiff-Legged Dumbbell Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ストレートバーベンチミッドロウ", nameEn: "Straight Bar Bench Mid Rows",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ストレートレイズオンインクラインベンチ", nameEn: "Straight Raises on Incline Bench",
            muscleGroups: [.shoulders, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ストレートアームダンベルプルオーバー", nameEn: "Straight-Arm Dumbbell Pullover",
            muscleGroups: [.chest, .back, .shoulders, .triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ストレートアームプルダウン", nameEn: "Straight-Arm Pulldown",
            muscleGroups: [.back],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "サスペンデッドフォールアウト", nameEn: "Suspended Fallout",
            muscleGroups: [.abs, .chest, .back, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "サスペンデッドプッシュアップ", nameEn: "Suspended Push-Up",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "サスペンデッドリバースクランチ", nameEn: "Suspended Reverse Crunch",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "サスペンデッドロウ", nameEn: "Suspended Row",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "サスペンデッドスプリットスクワット", nameEn: "Suspended Split Squat",
            muscleGroups: [.quads, .glutes, .calves, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "スヴェンドプレス", nameEn: "Svend Press",
            muscleGroups: [.chest, .forearms, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "Tバーロウウィズハンドル", nameEn: "T-Bar Row with Handle",
            muscleGroups: [.back, .biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "テイトプレス", nameEn: "Tate Press",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "サイアブダクター", nameEn: "Thigh Abductor",
            muscleGroups: [.glutes],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "サイアダクター", nameEn: "Thigh Adductor",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .machine, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "トラップバーデッドリフト", nameEn: "Trap Bar Deadlift",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "トライセプスキックバック", nameEn: "Tricep Dumbbell Kickback",
            muscleGroups: [.triceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "トライセプスオーバーヘッドエクステンションウィズロープ", nameEn: "Triceps Overhead Extension with Rope",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "トライセプスプッシュダウン", nameEn: "Triceps Pushdown",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "トライセプスプッシュダウンロープアタッチメント", nameEn: "Triceps Pushdown - Rope Attachment",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "トライセプスプッシュダウンVバーアタッチメント", nameEn: "Triceps Pushdown - V-Bar Attachment",
            muscleGroups: [.triceps],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "タッククランチ", nameEn: "Tuck Crunch",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ツーアームダンベルプリーチャーカール", nameEn: "Two-Arm Dumbbell Preacher Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ツーアームケトルベルクリーン", nameEn: "Two-Arm Kettlebell Clean",
            muscleGroups: [.shoulders, .calves, .glutes, .hamstrings, .back],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ツーアームケトルベルジャーク", nameEn: "Two-Arm Kettlebell Jerk",
            muscleGroups: [.shoulders, .calves, .quads, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ツーアームケトルベルミリタリープレス", nameEn: "Two-Arm Kettlebell Military Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ツーアームケトルベルロウ", nameEn: "Two-Arm Kettlebell Row",
            muscleGroups: [.back, .biceps],
            equipment: .kettlebell, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アンダーハンドケーブルプルダウン", nameEn: "Underhand Cable Pulldowns",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "アップライトバーベルロウ", nameEn: "Upright Barbell Row",
            muscleGroups: [.shoulders, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "アップライトケーブルロウ", nameEn: "Upright Cable Row",
            muscleGroups: [.back, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "アップライトロウウィズバンド", nameEn: "Upright Row - With Bands",
            muscleGroups: [.back, .shoulders],
            equipment: .band, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "Vバープルダウン", nameEn: "V-Bar Pulldown",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "Vバープルアップ", nameEn: "V-Bar Pullup",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ウェイテッドボールハイパーエクステンション", nameEn: "Weighted Ball Hyperextension",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ウェイテッドボールサイドベンド", nameEn: "Weighted Ball Side Bend",
            muscleGroups: [.abs, .obliques],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ウェイテッドベンチディップ", nameEn: "Weighted Bench Dip",
            muscleGroups: [.triceps, .chest, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ウェイテッドクランチ", nameEn: "Weighted Crunches",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ウェイテッドジャンプスクワット", nameEn: "Weighted Jump Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ウェイテッドプルアップ", nameEn: "Weighted Pull Ups",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ウェイテッドシッシースクワット", nameEn: "Weighted Sissy Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ウェイテッドシットアップウィズバンド", nameEn: "Weighted Sit-Ups - With Bands",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ウェイテッドスクワット", nameEn: "Weighted Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ワイドスタンスバーベルスクワット", nameEn: "Wide Stance Barbell Squat",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings, .back],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ワイドグリップバーベルベンチプレス", nameEn: "Wide-Grip Barbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ワイドグリップデクラインバーベルベンチプレス", nameEn: "Wide-Grip Decline Barbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ワイドグリップデクラインバーベルプルオーバー", nameEn: "Wide-Grip Decline Barbell Pullover",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ラットプルダウン", nameEn: "Wide-Grip Lat Pulldown",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ワイドグリッププルダウンビハインドネック", nameEn: "Wide-Grip Pulldown Behind The Neck",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .cable, measurementType: .weightReps, defaultRestSeconds: 120),
        SeedExercise(
            name: "ワイドグリップリアプルアップ", nameEn: "Wide-Grip Rear Pull-Up",
            muscleGroups: [.back, .biceps, .shoulders],
            equipment: .bodyweight, measurementType: .bodyweightReps, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワイドグリップスタンディングバーベルカール", nameEn: "Wide-Grip Standing Barbell Curl",
            muscleGroups: [.biceps],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ウィンドスプリント", nameEn: "Wind Sprints",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 120,
            locations: [.gym, .home]),
        SeedExercise(
            name: "リストローラー", nameEn: "Wrist Roller",
            muscleGroups: [.forearms, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "リストローテーションウィズストレートバー", nameEn: "Wrist Rotations with Straight Bar",
            muscleGroups: [.forearms],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ザーチャースクワット", nameEn: "Zercher Squats",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .barbell, measurementType: .weightReps, defaultRestSeconds: 150),
        SeedExercise(
            name: "ゾットマンカール", nameEn: "Zottman Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "ゾットマンプリーチャーカール", nameEn: "Zottman Preacher Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell, measurementType: .weightReps, defaultRestSeconds: 60),
        SeedExercise(
            name: "90/90ハムストリング", nameEn: "90/90 Hamstring",
            muscleGroups: [.hamstrings, .calves],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アダクター", nameEn: "Adductor",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アダクター/グロイン", nameEn: "Adductor/Groin",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オールフォーズクアッドストレッチ", nameEn: "All Fours Quad Stretch",
            muscleGroups: [.quads],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アンクルサークル", nameEn: "Ankle Circles",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アンクルオンニー", nameEn: "Ankle On The Knee",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アンテリアティビアリスSMR", nameEn: "Anterior Tibialis-SMR",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アームサークル", nameEn: "Arm Circles",
            muscleGroups: [.shoulders, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ビハインドヘッドチェストストレッチ", nameEn: "Behind Head Chest Stretch",
            muscleGroups: [.chest, .shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ブラキアリスSMR", nameEn: "Brachialis-SMR",
            muscleGroups: [.biceps],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "カーフストレッチエルボーアゲインストウォール", nameEn: "Calf Stretch Elbows Against Wall",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "カーフストレッチハンドアゲインストウォール", nameEn: "Calf Stretch Hands Against Wall",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "カーフSMR", nameEn: "Calves-SMR",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "キャットストレッチ", nameEn: "Cat Stretch",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェアレッグエクステンデッドストレッチ", nameEn: "Chair Leg Extended Stretch",
            muscleGroups: [.hamstrings, .glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェアロワーバックストレッチ", nameEn: "Chair Lower Back Stretch",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェアアッパーボディストレッチ", nameEn: "Chair Upper Body Stretch",
            muscleGroups: [.shoulders, .biceps, .chest],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェストとフロントオブショルダーストレッチ", nameEn: "Chest And Front Of Shoulder Stretch",
            muscleGroups: [.chest, .shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チェストストレッチオンバランスボール", nameEn: "Chest Stretch on Stability Ball",
            muscleGroups: [.chest],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チャイルドポーズ", nameEn: "Child's Pose",
            muscleGroups: [.back, .glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "チントゥーチェストストレッチ", nameEn: "Chin To Chest Stretch",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クロスオーバーリバースランジ", nameEn: "Crossover Reverse Lunge",
            muscleGroups: [.back, .abs, .glutes, .hamstrings, .quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダンサーストレッチ", nameEn: "Dancer's Stretch",
            muscleGroups: [.back, .glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダイナミックバックストレッチ", nameEn: "Dynamic Back Stretch",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ダイナミックチェストストレッチ", nameEn: "Dynamic Chest Stretch",
            muscleGroups: [.chest, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "エルボーサークル", nameEn: "Elbow Circles",
            muscleGroups: [.shoulders, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "エルボーバック", nameEn: "Elbows Back",
            muscleGroups: [.chest, .shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フットSMR", nameEn: "Foot-SMR",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フロッグホップ", nameEn: "Frog Hops",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "フロントレッグレイズ", nameEn: "Front Leg Raises",
            muscleGroups: [.hamstrings],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "グロインとバックストレッチ", nameEn: "Groin and Back Stretch",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "グロイナー", nameEn: "Groiners",
            muscleGroups: [.glutes],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハムストリングストレッチ", nameEn: "Hamstring Stretch",
            muscleGroups: [.hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハムストリングSMR", nameEn: "Hamstring-SMR",
            muscleGroups: [.hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ヒップサークルプローン", nameEn: "Hip Circles (prone)",
            muscleGroups: [.glutes],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハグボール", nameEn: "Hug A Ball",
            muscleGroups: [.back, .calves, .glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ハグニートゥーチェスト", nameEn: "Hug Knees To Chest",
            muscleGroups: [.back, .glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ITバンドとグルートストレッチ", nameEn: "IT Band and Glute Stretch",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "腸脛靭帯トラクトSMR", nameEn: "Iliotibial Tract-SMR",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インチワーム", nameEn: "Inchworm",
            muscleGroups: [.hamstrings],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インターミディエートグロインストレッチ", nameEn: "Intermediate Groin Stretch",
            muscleGroups: [.hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "インターミディエートヒップフレクサーとクアッドストレッチ", nameEn: "Intermediate Hip Flexor and Quad Stretch",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アイアンクロスストレッチ", nameEn: "Iron Crosses (stretch)",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ニーアクロスボディ", nameEn: "Knee Across The Body",
            muscleGroups: [.glutes, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ニーサークル", nameEn: "Knee Circles",
            muscleGroups: [.calves, .hamstrings, .quads],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ニーリングフォアアームストレッチ", nameEn: "Kneeling Forearm Stretch",
            muscleGroups: [.forearms],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ニーリングヒップフレクサー", nameEn: "Kneeling Hip Flexor",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ラティシマスドーシSMR", nameEn: "Latissimus Dorsi-SMR",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "レッグアップハムストリングストレッチ", nameEn: "Leg-Up Hamstring Stretch",
            muscleGroups: [.hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ルッキングアットシーリング", nameEn: "Looking At Ceiling",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ロワーバックカール", nameEn: "Lower Back Curl",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ロワーバックSMR", nameEn: "Lower Back-SMR",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ライイングベントレッググロイン", nameEn: "Lying Bent Leg Groin",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ライイングクロスオーバー", nameEn: "Lying Crossover",
            muscleGroups: [.glutes],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ライインググルート", nameEn: "Lying Glute",
            muscleGroups: [.glutes],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ライイングハムストリング", nameEn: "Lying Hamstring",
            muscleGroups: [.hamstrings, .calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ライイングプローンクアドリセプス", nameEn: "Lying Prone Quadriceps",
            muscleGroups: [.quads],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ミドルバックストレッチ", nameEn: "Middle Back Stretch",
            muscleGroups: [.back, .abs],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ネックSMR", nameEn: "Neck-SMR",
            muscleGroups: [.fullBody],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オンユアサイドクアッドストレッチ", nameEn: "On Your Side Quad Stretch",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オンユアバッククアッドストレッチ", nameEn: "On-Your-Back Quad Stretch",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンアームアゲインストウォール", nameEn: "One Arm Against Wall",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンハーフローカスト", nameEn: "One Half Locust",
            muscleGroups: [.quads, .abs, .biceps, .chest],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンハンデッドハング", nameEn: "One Handed Hang",
            muscleGroups: [.back, .biceps],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワンニートゥーチェスト", nameEn: "One Knee To Chest",
            muscleGroups: [.glutes, .hamstrings, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オーバーヘッドラット", nameEn: "Overhead Lat",
            muscleGroups: [.back, .triceps],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オーバーヘッドストレッチ", nameEn: "Overhead Stretch",
            muscleGroups: [.abs, .chest, .forearms, .back, .triceps],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "オーバーヘッドトライセプス", nameEn: "Overhead Triceps",
            muscleGroups: [.triceps, .back],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ペルビックティルトイントゥブリッジ", nameEn: "Pelvic Tilt Into Bridge",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ペロネアルストレッチ", nameEn: "Peroneals Stretch",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ペロネアルSMR", nameEn: "Peroneals-SMR",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ピリフォルミスSMR", nameEn: "Piriformis-SMR",
            muscleGroups: [.glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ポステリアティビアリスストレッチ", nameEn: "Posterior Tibialis Stretch",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ピラミッド", nameEn: "Pyramid",
            muscleGroups: [.back, .shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クアッドストレッチ", nameEn: "Quad Stretch",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "クアドリセプスSMR", nameEn: "Quadriceps-SMR",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "リアレッグレイズ", nameEn: "Rear Leg Raises",
            muscleGroups: [.quads],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "リンボイドSMR", nameEn: "Rhomboids-SMR",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ラウンドワールドショルダーストレッチ", nameEn: "Round The World Shoulder Stretch",
            muscleGroups: [.shoulders, .biceps, .chest],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ランナーストレッチ", nameEn: "Runner's Stretch",
            muscleGroups: [.hamstrings, .calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シザーキック", nameEn: "Scissor Kick",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドバイセプス", nameEn: "Seated Biceps",
            muscleGroups: [.biceps, .chest, .shoulders],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドカーフストレッチ", nameEn: "Seated Calf Stretch",
            muscleGroups: [.calves, .hamstrings, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドフロアハムストリングストレッチ", nameEn: "Seated Floor Hamstring Stretch",
            muscleGroups: [.hamstrings, .calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドフロントデルトイド", nameEn: "Seated Front Deltoid",
            muscleGroups: [.shoulders, .chest],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドグルート", nameEn: "Seated Glute",
            muscleGroups: [.glutes],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドハムストリング", nameEn: "Seated Hamstring",
            muscleGroups: [.hamstrings, .calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドハムストリングとカーフストレッチ", nameEn: "Seated Hamstring and Calf Stretch",
            muscleGroups: [.hamstrings, .calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シーテッドオーバーヘッドストレッチ", nameEn: "Seated Overhead Stretch",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ショルダーサークル", nameEn: "Shoulder Circles",
            muscleGroups: [.shoulders, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ショルダーレイズ", nameEn: "Shoulder Raise",
            muscleGroups: [.shoulders, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ショルダーストレッチ", nameEn: "Shoulder Stretch",
            muscleGroups: [.shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドレッグレイズ", nameEn: "Side Leg Raises",
            muscleGroups: [.glutes],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドライインググロインストレッチ", nameEn: "Side Lying Groin Stretch",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドネックストレッチ", nameEn: "Side Neck Stretch",
            muscleGroups: [.fullBody],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドリストプル", nameEn: "Side Wrist Pull",
            muscleGroups: [.shoulders, .forearms, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "サイドライイングフロアストレッチ", nameEn: "Side-Lying Floor Stretch",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "シットスクワット", nameEn: "Sit Squats",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スパイナルストレッチ", nameEn: "Spinal Stretch",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スプリットスクワット", nameEn: "Split Squats",
            muscleGroups: [.hamstrings, .calves, .glutes, .quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングバイセプスストレッチ", nameEn: "Standing Biceps Stretch",
            muscleGroups: [.biceps, .chest, .shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングエレベーテッドクアッドストレッチ", nameEn: "Standing Elevated Quad Stretch",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングガストロクネミウスカーフストレッチ", nameEn: "Standing Gastrocnemius Calf Stretch",
            muscleGroups: [.calves, .hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングハムストリングとカーフストレッチ", nameEn: "Standing Hamstring and Calf Stretch",
            muscleGroups: [.hamstrings],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングヒップサークル", nameEn: "Standing Hip Circles",
            muscleGroups: [.glutes],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングヒップフレクサー", nameEn: "Standing Hip Flexors",
            muscleGroups: [.quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングラテラルストレッチ", nameEn: "Standing Lateral Stretch",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングペルビックティルト", nameEn: "Standing Pelvic Tilt",
            muscleGroups: [.back, .glutes],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングソレウスとアキレスストレッチ", nameEn: "Standing Soleus And Achilles Stretch",
            muscleGroups: [.calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スタンディングトータッチ", nameEn: "Standing Toe Touches",
            muscleGroups: [.hamstrings, .calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ストマックバキューム", nameEn: "Stomach Vacuum",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "スーパーマン", nameEn: "Superman",
            muscleGroups: [.back, .glutes, .hamstrings],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ストラドル", nameEn: "The Straddle",
            muscleGroups: [.hamstrings, .glutes, .calves],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "トータッチ", nameEn: "Toe Touchers",
            muscleGroups: [.abs],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "トルソーローテーション", nameEn: "Torso Rotation",
            muscleGroups: [.abs],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "トライセプスサイドストレッチ", nameEn: "Tricep Side Stretch",
            muscleGroups: [.triceps, .shoulders],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "トライセプスストレッチ", nameEn: "Triceps Stretch",
            muscleGroups: [.triceps, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アッパーバックストレッチ", nameEn: "Upper Back Stretch",
            muscleGroups: [.back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アッパーバックレッググラブ", nameEn: "Upper Back-Leg Grab",
            muscleGroups: [.hamstrings, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アップワードストレッチ", nameEn: "Upward Stretch",
            muscleGroups: [.shoulders, .chest, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ウィンドミル", nameEn: "Windmills",
            muscleGroups: [.glutes, .hamstrings, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "ワールドグレイテストストレッチ", nameEn: "World's Greatest Stretch",
            muscleGroups: [.hamstrings, .calves, .glutes, .quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "リストサークル", nameEn: "Wrist Circles",
            muscleGroups: [.forearms],
            equipment: .bodyweight, measurementType: .time, defaultRestSeconds: 30,
            locations: [.gym, .home]),
        SeedExercise(
            name: "アトラスストーントレーナー", nameEn: "Atlas Stone Trainer",
            muscleGroups: [.back, .biceps, .forearms, .glutes, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "アトラスストーン", nameEn: "Atlas Stones",
            muscleGroups: [.back, .abs, .glutes, .biceps, .calves, .forearms, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "アクセルデッドリフト", nameEn: "Axle Deadlift",
            muscleGroups: [.back, .forearms, .glutes, .hamstrings, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "バックワードドラッグ", nameEn: "Backward Drag",
            muscleGroups: [.quads, .calves, .forearms, .glutes, .hamstrings, .back],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ベアクロールスレッドドラッグ", nameEn: "Bear Crawl Sled Drags",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "カーデッドリフト", nameEn: "Car Deadlift",
            muscleGroups: [.quads, .forearms, .glutes, .hamstrings, .back],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "サーカスベル", nameEn: "Circus Bell",
            muscleGroups: [.shoulders, .forearms, .glutes, .hamstrings, .back, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "コナンホイール", nameEn: "Conan's Wheel",
            muscleGroups: [.quads, .abs, .biceps, .calves, .forearms, .back, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "クルシフィックス", nameEn: "Crucifix",
            muscleGroups: [.shoulders, .forearms],
            equipment: .other, measurementType: .time, defaultRestSeconds: 180),
        SeedExercise(
            name: "ファーマーズウォーク", nameEn: "Farmer's Walk",
            muscleGroups: [.forearms, .abs, .glutes, .hamstrings, .back, .quads],
            equipment: .other, measurementType: .time, defaultRestSeconds: 180),
        SeedExercise(
            name: "フォワードドラッグウィズプレス", nameEn: "Forward Drag with Press",
            muscleGroups: [.chest, .calves, .glutes, .hamstrings, .quads, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ケグロード", nameEn: "Keg Load",
            muscleGroups: [.back, .abs, .biceps, .calves, .forearms, .glutes, .hamstrings, .quads, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ログリフト", nameEn: "Log Lift",
            muscleGroups: [.shoulders, .abs, .chest, .glutes, .hamstrings, .back, .quads, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "パワーステアー", nameEn: "Power Stairs",
            muscleGroups: [.hamstrings, .glutes, .calves, .back, .quads, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "リキシャーキャリー", nameEn: "Rickshaw Carry",
            muscleGroups: [.forearms, .abs, .calves, .glutes, .hamstrings, .back, .quads],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "リキシャーデッドリフト", nameEn: "Rickshaw Deadlift",
            muscleGroups: [.quads, .forearms, .glutes, .hamstrings, .back],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "サンドバッグロード", nameEn: "Sandbag Load",
            muscleGroups: [.quads, .abs, .biceps, .calves, .forearms, .glutes, .hamstrings, .back, .shoulders],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スレッドドラッグハーネス", nameEn: "Sled Drag - Harness",
            muscleGroups: [.quads, .calves, .glutes, .hamstrings],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "スレッドプッシュ", nameEn: "Sled Push",
            muscleGroups: [.quads, .calves, .chest, .glutes, .hamstrings, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "タイヤフリップ", nameEn: "Tire Flip",
            muscleGroups: [.quads, .calves, .chest, .forearms, .glutes, .hamstrings, .back, .shoulders, .triceps],
            equipment: .other, measurementType: .weightReps, defaultRestSeconds: 180),
        SeedExercise(
            name: "ヨークウォーク", nameEn: "Yoke Walk",
            muscleGroups: [.quads, .abs, .glutes, .calves, .hamstrings, .back],
            equipment: .other, measurementType: .time, defaultRestSeconds: 180),
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

import Foundation
import SwiftData

/// 種目（Exercise）の書き込み・初期投入を扱う。
///
/// 単純なリスト表示は SwiftUI 側で `@Query` を直接使う方が早いので、
/// ここでは「初回シード」「カスタム種目追加」など書き込み系のみ提供する。
@MainActor
public final class ExerciseRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// シード種目が未投入なら投入する。冪等。
    ///
    /// 起動時に呼び出す想定。既にデータがあれば何もしない。
    public func seedIfNeeded() throws {
        let descriptor = FetchDescriptor<Exercise>()
        let existing = try context.fetchCount(descriptor)
        guard existing == 0 else { return }

        for seed in SeedData.starterExercises {
            context.insert(seed.makeExercise())
        }
        try context.save()
    }

    /// SeedData の中で、ローカル DB に nameEn 一致のレコードが無いものを追加する。
    ///
    /// 起動時に呼び出す。冪等。SeedData.swift にシード種目を追記しただけで既存ユーザーにも
    /// 自動的に新種目が反映される。nameEn を dedup キーに使う（日本語名は表記揺れがあるため）。
    public func ensureSeedExercisesPresent() throws {
        let existing = try context.fetch(FetchDescriptor<Exercise>())
        let existingNameEn = Set(existing.map { $0.nameEn })

        var inserted = 0
        for seed in SeedData.starterExercises where !existingNameEn.contains(seed.nameEn) {
            context.insert(seed.makeExercise())
            inserted += 1
        }
        if inserted > 0 {
            try context.save()
            print("[Oikomi.seed] inserted \(inserted) new seed exercises")
        }
    }

    /// 種目ライブラリを free-exercise-db ベースの 873 種に一度だけ置き換える。
    ///
    /// 旧シード（120 種）の全削除 + 新シード一括投入を実施。`isCustom == true` の
    /// ユーザー作成種目は温存。SetRecord / PersonalRecord / RoutineExercise からの
    /// Exercise 参照は SwiftData のデフォルト nullify ルールに従い切れる（履歴データ
    /// 自体は残り続ける）。
    ///
    /// UserDefaults キー `oikomi.seed.fullLibraryV1.didMigrate` で多重実行を防ぐ。
    public func migrateToFullLibraryV1IfNeeded() throws {
        let key = "oikomi.seed.fullLibraryV1.didMigrate"
        if UserDefaults.standard.bool(forKey: key) { return }

        let oldSeeds = try context.fetch(
            FetchDescriptor<Exercise>(predicate: #Predicate { $0.isCustom == false })
        )
        for ex in oldSeeds {
            context.delete(ex)
        }
        for seed in SeedData.starterExercises {
            context.insert(seed.makeExercise())
        }
        try context.save()
        UserDefaults.standard.set(true, forKey: key)
        print(
            "[Oikomi.seed] migrated to full library v1: deleted \(oldSeeds.count), inserted \(SeedData.starterExercises.count)"
        )
    }

    /// 種目のお気に入り状態をトグルする。WCSync 経由で他デバイスにも同期される。
    public func toggleFavorite(_ exercise: Exercise) throws {
        exercise.isFavorite.toggle()
        try context.save()
        WCSyncBridge.shared.sendExerciseFavoriteUpdate(exerciseId: exercise.id, isFavorite: exercise.isFavorite)
    }

    /// カスタム種目を追加する。
    ///
    /// Free プランで `ProGate.freeCustomExerciseLimit` を超えると `ProGateError` を投げる。
    @discardableResult
    public func addCustomExercise(
        name: String,
        nameEn: String = "",
        muscleGroups: [MuscleGroup] = [],
        equipment: Equipment = .barbell,
        measurementType: MeasurementType = .weightReps,
        defaultRestSeconds: Int = 90
    ) throws -> Exercise {
        if !ProGate.canCreateUnlimitedCustomExercises {
            let existingCustomCount = try context.fetch(
                FetchDescriptor<Exercise>(predicate: #Predicate { $0.isCustom == true })
            ).count
            if existingCustomCount >= ProGate.freeCustomExerciseLimit {
                throw ProGateError.customExerciseLimitReached(
                    current: existingCustomCount,
                    limit: ProGate.freeCustomExerciseLimit
                )
            }
        }
        let exercise = Exercise(
            name: name,
            nameEn: nameEn,
            muscleGroups: muscleGroups,
            equipment: equipment,
            measurementType: measurementType,
            defaultRestSeconds: defaultRestSeconds,
            isCustom: true
        )
        context.insert(exercise)
        try context.save()
        return exercise
    }
}

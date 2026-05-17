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

    /// カスタム種目を追加する。
    @discardableResult
    public func addCustomExercise(
        name: String,
        nameEn: String = "",
        muscleGroups: [MuscleGroup] = [],
        equipment: Equipment = .barbell,
        measurementType: MeasurementType = .weightReps,
        defaultRestSeconds: Int = 90
    ) throws -> Exercise {
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

import Foundation
import SwiftData

/// OikomiKit のパブリックエントリポイント。
public enum OikomiKit {
    public static let version = "0.1.0-dev"

    /// SwiftData のスキーマ定義。
    ///
    /// このスキーマを `ModelContainer` に渡して各 UI ターゲットで共有する。
    /// CloudKit 互換のため、`@Attribute(.unique)` は使わない。
    public static let schemaModels: [any PersistentModel.Type] = [
        Exercise.self,
        WorkoutSession.self,
        SetRecord.self,
        Routine.self,
        RoutineExercise.self,
        HealthSnapshot.self,
        PersonalRecord.self,
    ]
}

import Foundation
import SwiftData

/// アプリ全体で共有する ModelContainer のシングルトンアクセス。
///
/// SwiftUI 外（App Intents / Widget / Background Task）からも SwiftData にアクセスする必要があるため、
/// 起動時に `OikomiApp` が `bootstrap()` で初期化する。
///
/// CloudKit との互換性確保のため、`OikomiKit.schemaModels` を使う。
@MainActor
public enum SharedModelContainer {

    public static private(set) var container: ModelContainer?

    /// アプリ起動時に呼び出して初期化する。複数回呼ばれても初回のみ作成。
    @discardableResult
    public static func bootstrap(
        isStoredInMemoryOnly: Bool = false,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none
    ) throws -> ModelContainer {
        if let existing = container {
            return existing
        }
        let schema = Schema(OikomiKit.schemaModels)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: cloudKitDatabase
        )
        let new = try ModelContainer(for: schema, configurations: [configuration])
        container = new
        return new
    }

    /// 必須化されたアクセサ。`bootstrap()` 前に呼ぶとクラッシュ。
    public static func mustGetContainer() -> ModelContainer {
        guard let container else {
            fatalError("SharedModelContainer.bootstrap() を呼ぶ前にアクセスされました")
        }
        return container
    }
}

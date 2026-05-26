import Foundation
import SwiftData

/// アプリ全体で共有する ModelContainer のシングルトンアクセス。
///
/// SwiftUI 外（App Intents / Widget / Background Task）からも SwiftData にアクセスする必要があるため、
/// 起動時に `OikomiApp` が `bootstrap()` で初期化する。
///
/// CloudKit 有効時はマルチデバイス（iPhone / Apple Watch / Mac / iPad）で自動同期する。
/// Container 不在などで初期化に失敗した場合は、安全側として `.none` でリトライしてアプリは起動可能にする。
@MainActor
public enum SharedModelContainer {

    public static private(set) var container: ModelContainer?

    /// CloudKit 有効化のユーザー設定キー。
    /// 仕様書 §7.1: 設定 → iCloud 同期トグル（Pro 機能想定）。
    /// デフォルトは true（ユーザーが既に Apple Developer Program に加入し iCloud 容器を作成済みの想定）。
    public static let cloudKitEnabledKey = "OikomiCloudKitEnabled"

    /// アプリ本体とウィジェットエクステンションで SwiftData ストアを共有するための App Group ID。
    /// entitlements に `com.apple.security.application-groups` で同 ID を登録している前提。
    /// これが無いとウィジェットは別サンドボックスの空 store を見てしまう。
    public static let appGroupID = "group.com.shuhirouchi.oikomi"

    /// App Group コンテナ内に置く SwiftData ストアファイルの URL。
    /// 取得できない場合（App Group が entitlements に無い等）は nil を返す。
    public static func storeURL() -> URL? {
        let fm = FileManager.default
        guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        let supportDir = container.appendingPathComponent("Library/Application Support", isDirectory: true)
        try? fm.createDirectory(at: supportDir, withIntermediateDirectories: true)
        return supportDir.appendingPathComponent("default.store")
    }

    /// 初期化を試みた最終モード。UI 側でユーザーに現状を表示するため。
    public static private(set) var activeCloudKitMode: CloudKitMode = .disabled

    public enum CloudKitMode: String, Sendable {
        case enabled  // .automatic で起動成功
        case disabled  // ユーザー設定 or フォールバックで .none で起動
        case fallback  // CloudKit 起動失敗 → .none にフォールバック
    }

    /// アプリ起動時に呼び出して初期化する。複数回呼ばれても初回のみ作成。
    @discardableResult
    public static func bootstrap(
        isStoredInMemoryOnly: Bool = false
    ) throws -> ModelContainer {
        if let existing = container {
            return existing
        }

        // watchOS は CloudKit のサイレントプッシュ用 background mode を扱えず、
        // 起動時に "BUG IN CLIENT OF CLOUDKIT" assertion で停止する。
        // Watch は WCSession 経由で iPhone と即時同期し、iPhone が CloudKit へ
        // 書き込むことで他デバイスへ伝播する分業構成にする。
        #if os(watchOS)
            let defaultEnabled = false
        #else
            let defaultEnabled = true
        #endif
        let userWantsCloudKit = UserDefaults.standard.object(forKey: cloudKitEnabledKey) as? Bool ?? defaultEnabled

        // Pro 限定機能（仕様書 §10）。bootstrap は同期文脈のため、SubscriptionManager が
        // 前回 refreshEntitlement 時に書き込んだキャッシュ値を参照する。
        // 初回起動 / Pro 未契約は false → ローカル動作。購入後の次回起動から iCloud が有効化。
        let cachedProActive = UserDefaults.standard.bool(forKey: SubscriptionManager.lastKnownProActiveKey)
        let wantCloudKit = userWantsCloudKit && cachedProActive

        // App Group コンテナ内の URL を取得。
        // テスト (isStoredInMemoryOnly) や entitlements 未付与環境では nil → SwiftData デフォルト URL にフォールバック。
        let sharedURL = isStoredInMemoryOnly ? nil : storeURL()

        if wantCloudKit && !isStoredInMemoryOnly {
            // まず CloudKit 有効で試す。
            // 失敗した Schema を再利用すると "invalid reuse after initialization failure" になるため、
            // 各試行で新しい Schema を生成する。
            do {
                let cloudSchema = Schema(OikomiKit.schemaModels)
                let configuration: ModelConfiguration
                if let sharedURL {
                    configuration = ModelConfiguration(
                        schema: cloudSchema,
                        url: sharedURL,
                        cloudKitDatabase: .automatic
                    )
                } else {
                    configuration = ModelConfiguration(
                        schema: cloudSchema,
                        isStoredInMemoryOnly: false,
                        cloudKitDatabase: .automatic
                    )
                }
                let new = try ModelContainer(for: cloudSchema, configurations: [configuration])
                container = new
                activeCloudKitMode = .enabled
                return new
            } catch {
                // 失敗ログを記録、ユーザー設定を維持しつつ .none にフォールバック
                print("CloudKit ModelContainer 起動失敗 → ローカル動作で続行: \(error)")
                activeCloudKitMode = .fallback
            }
        } else {
            activeCloudKitMode = .disabled
        }

        // フォールバック / .none ローカル用は別 Schema インスタンスで開く
        let localSchema = Schema(OikomiKit.schemaModels)
        let configuration: ModelConfiguration
        if let sharedURL {
            configuration = ModelConfiguration(
                schema: localSchema,
                url: sharedURL,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                schema: localSchema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                cloudKitDatabase: .none
            )
        }
        let new = try ModelContainer(for: localSchema, configurations: [configuration])
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

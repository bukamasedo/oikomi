import Foundation
import Observation

/// レストタイマー UI の真実のソース。iOS/watchOS の全タブ・全画面で同じ値を参照する。
///
/// 設計:
/// - `WCSyncBridge.dataDidChangeNotification` を購読し、リモート起動 (相手デバイスでの
///   セット完了) も、自分のローカル `start(...)` も同じ State に集約する。
/// - 旧実装は `WorkoutTabView` のローカル `@State restEndAt` だったため、タブ切替で
///   `RestTimerCard` が描画範囲外に出ると見えなくなった。`ContentView` (TabView の親) に
///   `safeAreaInset` で常駐する版を置けるようにするための受け皿。
/// - 単一の真実のソースなので、ローカル start とリモート start で「先勝ち」処理は
///   不要。最後に書かれた値が常に最新（WCSyncBridge 側で stale ガード済）。
@MainActor
@Observable
public final class RestTimerStore {

    public static let shared = RestTimerStore()

    /// レスト終了の絶対時刻。nil = タイマー無し。
    public private(set) var endAt: Date?

    /// レストタイマーの初期総秒数（進捗リング正規化用）。
    public private(set) var totalSeconds: Int = 60

    /// 直前完了セットの重量 (kg 内部表現)。サブテキスト「80kg × 5」表示用。
    public private(set) var completedWeightKg: Double?

    /// 直前完了セットのレップ数。
    public private(set) var completedReps: Int?

    private init() {}

    /// アプリ起動時に 1 度だけ呼ぶ。WCSyncBridge 発の Notification を購読し、
    /// 受信時に `handleSync` を MainActor で実行する。
    /// 単体テストでは購読せず、`handleSync` を直接呼んで検証する。
    public func registerWCSyncListener() {
        // `queue: .main` により closure は必ず main thread で同期実行される。
        // Notification 自体は非 Sendable なので、Sendable な素プリミティブ
        // (String? / Date? / Int? / Double?) に分解してから `MainActor.assumeIsolated`
        // で MainActor isolated な handleSync を呼ぶ。
        // `Task { @MainActor in ... }` 経由だと `note` キャプチャ周りで data race
        // 警告が出やすく、また実行が次の run loop まで遅延するため避ける。
        NotificationCenter.default.addObserver(
            forName: WCSyncBridge.dataDidChangeNotification,
            object: nil,
            queue: .main
        ) { note in
            let kind = note.userInfo?["kind"] as? String
            let endAt = note.userInfo?["endAt"] as? Date
            let totalSeconds = note.userInfo?["totalSeconds"] as? Int
            let weight = note.userInfo?["completedWeightKg"] as? Double
            let reps = note.userInfo?["completedReps"] as? Int
            MainActor.assumeIsolated {
                RestTimerStore.shared.handleSync(
                    kind: kind,
                    endAt: endAt,
                    totalSeconds: totalSeconds,
                    completedWeightKg: weight,
                    completedReps: reps
                )
            }
        }
    }

    /// レストタイマーを起動する。ローカルでセット完了したとき、または UI 側で
    /// 何らかの理由で直接立ち上げたいときに呼ぶ。
    public func start(
        endAt: Date,
        totalSeconds: Int,
        completedWeightKg: Double? = nil,
        completedReps: Int? = nil
    ) {
        self.endAt = endAt
        self.totalSeconds = max(1, totalSeconds)
        self.completedWeightKg = completedWeightKg
        self.completedReps = completedReps
    }

    /// レストタイマーをクリアする。スキップ / 完了取消 / セッション終了で呼ぶ。
    public func cancel() {
        endAt = nil
        completedWeightKg = nil
        completedReps = nil
    }

    /// 終了時刻を過ぎていれば自動でクリアする。シーンが foreground 復帰した時などに
    /// 呼んで、寝かせている間に終わったタイマーを掃除する。
    public func expireIfPast(now: Date = Date()) {
        guard let endAt, endAt <= now else { return }
        cancel()
        _ = endAt
    }

    /// Notification 経由でなくても直接呼べる sync ハンドラ。
    /// 単体テストや、Notification 経路を持たない呼び出し (例: 同一プロセス内の他コンポーネント)
    /// から使う。
    public func handleSync(
        kind: String?,
        endAt: Date?,
        totalSeconds: Int?,
        completedWeightKg: Double?,
        completedReps: Int?
    ) {
        guard let kind else { return }
        if kind == SyncEnvelope.Kind.restTimerCancel.rawValue {
            cancel()
            return
        }
        guard kind == SyncEnvelope.Kind.restTimerStart.rawValue,
            let endAt,
            endAt > Date()
        else { return }
        start(
            endAt: endAt,
            totalSeconds: totalSeconds ?? self.totalSeconds,
            completedWeightKg: completedWeightKg,
            completedReps: completedReps
        )
    }
}

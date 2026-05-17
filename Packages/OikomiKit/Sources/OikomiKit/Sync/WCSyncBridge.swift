import Foundation
import SwiftData

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// iPhone ↔ Apple Watch のリアルタイム同期ブリッジ。
///
/// CloudKit のサイレントプッシュは数十秒〜数分の遅延がある（Apple のサーバー側
/// スロットリング）。WatchConnectivity で「データ変更通知」を即座に送ることで、
/// 受信側が SwiftData / CloudKit の最新化を能動的にトリガーし、< 1秒で反映できる。
///
/// 役割:
/// - 送信: 任意の write 直後に notifyChange() で軽量 ping を送る
/// - 受信: ping を受け取った side で NotificationCenter.oikomiDataDidChange を post
///   → SwiftUI 側で必要なら ModelContext を refresh
///
/// CloudKit を OFF にしている場合は WC のみで通知が伝わる。`OikomiOnboardingCompleted`
/// 設定があるなど、receiver 側の状態は問わない。
@MainActor
public final class WCSyncBridge: NSObject {

    public static let shared = WCSyncBridge()

    /// 受信側で「データ変更を反映してください」を伝えるための NotificationCenter 通知名。
    public static let dataDidChangeNotification = Notification.Name("OikomiDataDidChange")

    #if canImport(WatchConnectivity)
    private var sessionDelegate: WCSessionDelegateAdapter?
    #endif

    /// アプリ起動時に呼ぶ。WCSession の activate + delegate 設定。
    public func activate() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let adapter = WCSessionDelegateAdapter()
        sessionDelegate = adapter
        let session = WCSession.default
        session.delegate = adapter
        session.activate()
        #endif
    }

    /// データ変更通知を相手デバイスに送る。状態に応じて自動でルートを選択：
    /// - 相手が reachable（両方フォアグラウンド / Watch 装着中）→ sendMessage（即時）
    /// - そうでない場合 → transferUserInfo（バックグラウンド配信、起動時にまとめて受信）
    public func notifyChange(kind: ChangeKind = .general) {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let payload: [String: Any] = [
            "type": "oikomi.dataChanged",
            "kind": kind.rawValue,
            "timestamp": Date().timeIntervalSince1970,
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                // 配送失敗時はフォールバック
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
        #endif
    }

    /// 変更の種別（受信側で UI 更新の優先度を判断する用途）
    public enum ChangeKind: String, Sendable {
        case general
        case sessionStarted
        case sessionFinished
        case setRecorded
        case routineChanged
    }

    /// 受信時に内部から呼ばれる。NotificationCenter に投げて UI 側に通知。
    fileprivate func didReceiveChange(kind: ChangeKind) {
        NotificationCenter.default.post(
            name: Self.dataDidChangeNotification,
            object: nil,
            userInfo: ["kind": kind.rawValue]
        )
    }
}

#if canImport(WatchConnectivity)
/// NSObject 制約を満たすための薄いアダプタ。Sendable 警告を避けるため WCSyncBridge から分離。
private final class WCSessionDelegateAdapter: NSObject, WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        // 起動完了。エラーがあっても致命ではない（CloudKit のフォールバックがある）
        if let error {
            print("WCSession activation failed: \(error)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // iPhone 側だけ複数 Watch の切替を考慮して再 activate
        WCSession.default.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handlePayload(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handlePayload(userInfo)
    }

    private func handlePayload(_ payload: [String: Any]) {
        guard payload["type"] as? String == "oikomi.dataChanged" else { return }
        let kindRaw = payload["kind"] as? String ?? "general"
        let kind = WCSyncBridge.ChangeKind(rawValue: kindRaw) ?? .general
        Task { @MainActor in
            WCSyncBridge.shared.didReceiveChange(kind: kind)
        }
    }
}
#endif

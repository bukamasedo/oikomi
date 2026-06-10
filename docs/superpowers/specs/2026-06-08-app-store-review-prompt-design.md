# App Store レビュー依頼（StoreKit `requestReview`）設計

- 日付: 2026-06-08
- 対象: Oikomi v0.x
- 関連: 仕様書 §5.4（外部依存なし／StoreKit 標準のみ）

## 目的

ユーザーがアプリをある程度使い込んだ「ポジティブな瞬間」に、App Store のレビュー依頼ダイアログ（`requestReview`）を控えめに提示し、レビュー獲得につなげる。

## 前提・制約

- iOS の `requestReview` は **OS 側で表示回数を年3回までに自動制限**する。アプリは「呼ぶ瞬間」を選ぶだけで、最終的な表示可否は OS が決める。
- Oikomi は **Apple Watch でセッションを完了する**のが主動線。「iPhone でセッション完了した瞬間」に出すフックでは Watch 完了分を取りこぼす。
- 外部依存は入れない（StoreKit 標準のみ）。Watch 側からはレビュー依頼しない（iPhone に集約）。
- 対象 OS は iOS 26+ のため、最新の SwiftUI `@Environment(\.requestReview)` アクションを使う（`SKStoreReviewController` は使わない）。

## トリガー

**完了セッション数（`endedAt != nil`）がマイルストーンに到達したとき**、iPhone のホーム表示時に判定する。SwiftData は CloudKit/ローカルで同期済みのため、Watch で完了したワークアウトも iPhone を開いた時点でカウントに含まれる。

- マイルストーン: `[3, 15, 40]`（最初の依頼は **3回目の完了セッション**後）
- 同一ユーザーへの連投を避けるため、**前回依頼から 90 日未満は出さない**（アプリ側の自前間引き）。OS の年3回制限はその上の最終バックストップ。

## 設計

### 1. ロジック層 — `OikomiKit/Review/ReviewRequestGate`（純粋・テスト容易）

UI に依存しない判定ロジック。状態は `UserDefaults` に保存。

```swift
public enum ReviewRequestGate {
    static let milestones = [3, 15, 40]
    static let minInterval: TimeInterval = 90 * 24 * 60 * 60  // 90 日

    static let lastConsumedMilestoneKey = "OikomiReview_LastConsumedMilestone"
    static let lastRequestDateKey = "OikomiReview_LastRequestDate"

    /// 今依頼すべきマイルストーンを返す。なければ nil。
    /// 条件: count >= m かつ m > lastConsumedMilestone を満たす最大の m があり、
    /// かつ 前回依頼から minInterval 以上経過している（初回は無条件 OK）。
    public static func milestoneDue(
        completedSessionCount: Int,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> Int?

    /// 依頼を出した後に呼ぶ。消化マイルストーンと日時を記録する。
    public static func markRequested(
        milestone: Int,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    )
}
```

判定の流れ:
1. `lastConsumed = defaults.integer(forKey: lastConsumedMilestoneKey)`（既定 0）
2. `milestones` のうち `m <= count && m > lastConsumed` を満たす**最大の m** を選ぶ。無ければ `nil`。
3. `lastRequestDate` があり `now - lastRequestDate < minInterval` なら `nil`。
4. それ以外は `m` を返す。
5. 呼び出し側が `requestReview()` を呼んだ後 `markRequested(milestone: m)` で `lastConsumedMilestone = m` / `lastRequestDate = now` を保存。

「呼んだが OS が表示しなかった」場合もマイルストーンは消化する（Apple 推奨の「呼んで OS に委ねる、リトライしない」方針）。

### 2. セッション数の取得 — `WorkoutSessionRepository`

完了セッション数を返すメソッドを用意（既存になければ追加）:
```swift
func completedSessionCount() throws -> Int  // endedAt != nil の件数（FetchDescriptor の count）
```

### 3. UI 層 — `HomeView`（薄く）

```swift
@Environment(\.requestReview) private var requestReview
// .task { } 内（ホーム表示時、1 launch につき過剰発火しないよう軽量に）
let count = (try? repo.completedSessionCount()) ?? 0
if let m = ReviewRequestGate.milestoneDue(completedSessionCount: count) {
    requestReview()
    ReviewRequestGate.markRequested(milestone: m)
}
```

## テスト（OikomiKit ユニット、テスト先行）

`ReviewRequestGate` の純粋ロジックを `UserDefaults`(テスト用 suite) と固定 `now` で網羅:
- 3 未満 → nil
- ちょうど 3 / 3 超 → 3 を返す
- 3 消化後・15 未満 → nil（再依頼なし）
- 15 到達 → 15 を返す（ただし 90 日未満なら nil）
- 90 日経過後に次マイルストーン → 返す
- `markRequested` 後に状態が保存され、同条件で再度 nil になる
- 一気に 40 まで到達 → 最大の未消化マイルストーン 40 を返す

## スコープ外（YAGNI）

- 設定画面からの「レビューを書く」手動導線（App Store URL 直開き）は今回は作らない（必要なら別途）。
- A/B やリモート設定によるマイルストーン調整。
- Watch からのレビュー依頼。

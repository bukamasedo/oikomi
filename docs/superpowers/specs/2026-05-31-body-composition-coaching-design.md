# 体組成連動コーチング（A3）設計書

> Spec 2「Volume & Recovery Intelligence」の最終サブスペック。
> 確定スコープ: **相対筋力（1RM/体重）** と **増量/減量フェーズ判定** の軽量2機能。
> **自重種目への体重結合は本スペック対象外**（別サブスペック / 後回し）。

作成日: 2026-05-31

---

## 1. 背景と狙い

体組成データ（体重 `bodyMass` / 体脂肪率 / 除脂肪体重 LBM）は `HealthStore.dailySeries`(days:90) で取得し、分析タブ「ボディ」セクションで**グラフ表示のみ**に使われている。コーチングには一切利用されていない（`combinedCoachingAdvice` は体組成を見ていない）。

A3 は、このキャプチャ済みデータをコーチングに接続する。狙いは「ヘルスデータ駆動の筋トレ記録」という製品コンセプト（CLAUDE.md）の核心 — 体組成を筋力・トレーニング文脈に結びつける。

### スコープの分割（重要）

A3 が想定する 3 機能のうち、本スペックは**軽量な 2 つ**に限定する:

| 機能 | 重さ | 本スペック |
|---|---|---|
| 相対筋力（1RM ÷ 体重） | 軽 | ✅ 含む |
| 増量/減量フェーズ判定（体重トレンド） | 軽 | ✅ 含む |
| 自重種目への体重結合（実効負荷・PR・ボリューム計上） | 重 | ❌ 対象外 |

**自重結合を外す理由**: 体重スナップショットのデータ捕捉、種目ごとのレバレッジ係数を含む実効負荷モデル、それをボリューム/1RM/PR の全分析スタックに通す改修が必要で、波及とリスクが最大。係数自体も不正確。体組成連動の中核価値（相対筋力・増量減量の文脈）は軽量 2 機能でほぼ得られるため、自重結合は別サブスペックに分離して後回しにする。

---

## 2. 機能 1: 相対筋力（1RM / 体重）

### 2.1 エンジン（純粋関数）

**新規 `Packages/OikomiKit/Sources/OikomiKit/Coaching/RelativeStrength.swift`**

```swift
public struct RelativeStrengthRow: Sendable, Hashable, Identifiable {
    public let id: UUID            // 種目 ID（PersonalRecord.exercise.id）
    public let exerciseName: String
    public let estimated1RM: Double // kg
    public let ratio: Double        // estimated1RM / 体重
}

public enum RelativeStrength {
    /// 重量種目の PR から「1RM / 体重」を計算し、体重比降順で返す。
    /// 自重種目（estimated1RM <= 0）と体重未取得（bodyweightKg <= 0）は除外。
    public static func report(
        records: [PersonalRecord],
        bodyweightKg: Double
    ) -> [RelativeStrengthRow]
}
```

ロジック:
- `bodyweightKg <= 0` なら `[]`（体重データなし → graceful）。
- 各 `PersonalRecord` について `record.exercise` があり `record.estimated1RM > 0` のものだけ採用。
- `ratio = estimated1RM / bodyweightKg`。
- `ratio` 降順（同値は `exerciseName` 昇順）でソートして返す。表示件数の絞り込み（上位5件）は UI 側で `prefix` する。

### 2.2 露出（UI）

分析タブ「ボディ」セクション（`BodyAnalysisSection`）に**相対筋力カード**を追加。既存 `metricCard` と同じ見た目のカードに、`RelativeStrength.report` の上位 5 件をリスト表示する（「ベンチプレス 1.25×」のように体重比を強調）。

- 現体重は `HealthStore.shared.todayValue(for: .bodyMass)`（async・Pro連動）から取得。
- PR データは `AnalysisTabView` の既存 `@Query` から `records: [PersonalRecord]` として渡す。
- 体重未取得 / PR なし → カードは「体重と PR を記録すると体重比が表示されます」程度のプレースホルダ。
- **表示のみ**（コーチング提案は出さない。マイルストーン演出は後回し）。

---

## 3. 機能 2: 増量/減量フェーズ判定

### 3.1 エンジン（純粋関数）

**新規 `Packages/OikomiKit/Sources/OikomiKit/Coaching/BodyPhase.swift`**

```swift
public enum BodyPhase: String, Sendable, CaseIterable {
    case bulk         // 増量期
    case cut          // 減量期
    case maintenance  // 維持期
    public var displayName: String  // 増量期 / 減量期 / 維持期
}

public struct BodyPhaseResult: Sendable, Hashable {
    public let phase: BodyPhase
    public let kgPerMonth: Double    // 体重変化率（符号付き）
}

public enum BodyPhase {  // 同名 namespace に static を集約
    /// 体重系列の傾きからフェーズを判定。サンプル不足なら nil。
    public static func detect(
        bodyMassSeries: [HealthTrendPoint],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> BodyPhaseResult?

    /// フェーズに応じた文脈コーチングを 0〜1 件返す。
    public static func phaseAdvice(_ result: BodyPhaseResult?) -> [CoachingAdvice]
}
```

> 実装メモ: `enum BodyPhase` のケース定義と static メソッド群を同一 enum に同居させる（Swift は同一 enum 宣言を 1 箇所にまとめる）。上記は説明上分割しているが、ファイル内では 1 つの `public enum BodyPhase { ... }` にまとめる。

`detect` ロジック:
- `bodyMassSeries` を `value > 0` でフィルタし日付昇順に整列。`count >= minSamples`(=6) でなければ `nil`。
- 各点を `(x: 最初の点からの経過日数, y: kg)` に変換（不規則な計測間隔に対応）。
- `Analytics.linearRegression` で傾き `slope`(kg/日) を求め、`kgPerMonth = slope * 30`。
- 分類: `kgPerMonth > +monthlyThresholdKg`(=0.5) → `.bulk` / `< -0.5` → `.cut` / それ以外 → `.maintenance`。
- 定数 `minSamples = 6`, `monthlyThresholdKg = 0.5` は `private static let`。

`phaseAdvice` ロジック:
- `result == nil` → `[]`。
- `.bulk` → `.info`「増量期（+X kg/月）。PR を伸ばしやすい時期です。」
- `.cut` → `.info`「減量期（-X kg/月）。筋力を維持できていれば成功です。」
- `.maintenance` → `[]`（ノイズ回避）。
- `X` は `abs(kgPerMonth)` を小数1桁。`impact` は `.info` 帯（既存 info 提案と整合する値、例: 110）。

### 3.2 露出（UI）

- **分析タブ「ボディ」**: 体重カードのヘッダに**フェーズバッジ**（増量期/減量期/維持期）。既に取得済みの `weightSeries`（kg）から `BodyPhase.detect` を直接呼んで表示。
- **ホーム / 全コーチング一覧**: `combinedCoachingAdvice` 経由でフェーズ提案を統合（下記 §4）。

---

## 4. データフローと統合点

### 4.1 `HealthStore` ラッパー（新規）

`readinessSnapshot` と同型の薄いラッパーを追加:

```swift
public func bodyPhase(
    referenceDate: Date = Date(),
    calendar: Calendar = .current
) async -> BodyPhaseResult? {
    guard ProGate.canReadHealthData else { return nil }
    let series = await dailySeries(for: .bodyMass, days: 30)
    return BodyPhase.detect(bodyMassSeries: series, referenceDate: referenceDate, calendar: calendar)
}
```

### 4.2 `combinedCoachingAdvice` 拡張

`Analytics.combinedCoachingAdvice` に省略可能引数 `bodyPhase: BodyPhaseResult? = nil` を追加し、生成器マージに `BodyPhase.phaseAdvice(bodyPhase)` を加える（readiness と同じ「計算済みを渡す」方式。後方互換: 既定 nil で既存呼び出しは不変）。

ソート / `limit` プレフィックスは既存のまま（warning 優先 → impact 降順）。

### 4.3 `HomeView`

`refreshHealthSignals`（readiness を取得している既存メソッド）で、readiness と並行して `bodyPhase` も取得し `@State` に保持。`allCoaching` computed property の `combinedCoachingAdvice(... readiness: readiness, bodyPhase: bodyPhase, ...)` に渡す。

### 4.4 ゲーティングと graceful degradation

- ボディの体組成読み取りは既存 `canReadHealthData`（Pro）。
- コーチング統合は既存 `canUseAICoaching`（Pro、`HomeView.allCoaching` の先頭ガード）。
- 体組成データなし（Apple Watch / 体組成計なし、または HealthKit 未許可）→ `todayValue`/`dailySeries` が空 → 相対筋力カードはプレースホルダ、フェーズバッジ非表示、`phaseAdvice` は空。クラッシュ・誤提案なし。

---

## 5. テスト（TDD・OikomiKit）

**新規 `RelativeStrengthTests.swift`**
- 体重比 = 1RM/体重 が正しい（例: 100kg / 80kg = 1.25）。
- 体重比降順でソートされる。
- `estimated1RM <= 0`（自重種目）は除外。
- `bodyweightKg <= 0` で空配列。

**新規 `BodyPhaseTests.swift`**
- 上昇系列 → `.bulk`、下降系列 → `.cut`、平坦系列 → `.maintenance`。
- `kgPerMonth` の符号・概算値が妥当。
- サンプル `< 6` 点で `nil`。
- `phaseAdvice`: bulk/cut → 1 件 `.info`、maintenance/nil → 空。

**`AnalyticsTests.swift` 追記**
- `combinedCoachingAdvice` に `bodyPhase`(.cut 等) を渡すとフェーズ提案がマージされる。`bodyPhase: nil`（既定）では出ない（後方互換）。

---

## 6. 変更ファイル一覧

| 区分 | パス | 内容 |
|---|---|---|
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/RelativeStrength.swift` | 相対筋力の純粋関数 |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/BodyPhase.swift` | フェーズ判定 + phaseAdvice |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift` | `bodyPhase(...)` ラッパー |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift` | `combinedCoachingAdvice` に `bodyPhase` 引数 + マージ |
| 改修 | `App/iOS/Views/Analysis/BodyAnalysisSection.swift` | 相対筋力カード + フェーズバッジ |
| 改修 | `App/iOS/Views/Analysis/AnalysisTabView.swift` | `BodyAnalysisSection` に `records` を渡す |
| 改修 | `App/iOS/Views/HomeView.swift` | `bodyPhase` 取得 + `combinedCoachingAdvice` へ受け渡し |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/RelativeStrengthTests.swift` | テスト |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/BodyPhaseTests.swift` | テスト |
| 改修 | `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift` | フェーズ統合テスト追記 |

---

## 7. スコープ外（本スペックでやらない）

- **自重種目への体重結合**（体重スナップショット捕捉、実効負荷モデル、PR/ボリューム計上）→ 別サブスペック / 後回し。
- 相対筋力のマイルストーン演出（体重比 1.0×/1.5× 達成通知など）→ 後回し。
- 主要コンパウンド（BIG3）の特別扱い → PR 種目一覧で十分。
- オンボーディングでの体組成・目標捕捉。
- 端末間同期の追加（既存 `.sharedAppGroup` / CloudKit のまま）。

---

## 8. CLAUDE.md / 仕様整合

- ビジネスロジックは `OikomiKit`（純粋関数）に集約、UI は表示のみ。
- 新規 `@Model` なし（モデル変更なし → `swift-data-modeler` 不要、VersionedSchema 不要）。
- HealthKit アクセスは既存 `HealthStore` ラッパー経由。
- オンデバイス計算のみ（外部 LLM / Foundation Models 不使用。NLP は Spec 3 / v1.2）。
- コーチング文言は既存パターン同様、日本語ハードコード（自然な表現）。

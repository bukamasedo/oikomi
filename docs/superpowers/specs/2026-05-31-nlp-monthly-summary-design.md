# NLP 月次振り返り（Spec 3）設計書

> コーチング拡充の最終 Spec（方向性 D）。Apple Intelligence / Foundation Models（オンデバイス）で、
> Spec 1/2 が生む構造化データを **月次の自然言語振り返り**に変換する。SPEC.md L220/L441/L191 準拠。
> 対応機種で点灯する **Pro ボーナス**（非対応機種は数式コーチングのまま）。

作成日: 2026-05-31

---

## 1. 背景と狙い

Spec 1（Readiness）・Spec 2（Volume & Recovery）はすべて**オンデバイス数式**で、Apple Intelligence 非対応機種でもフル動作する（SPEC L191）。Spec 3 はその上に、**対応機種でのみ点灯するボーナス**として、月初に「先月の振り返り」を自然言語で生成する。

- 一次データは Spec 1/2 の構造化出力（readiness, CoachingAdvice, volume, PR, bodyPhase, recovery）。
- 生成は **Foundation Models（`SystemLanguageModel` / `LanguageModelSession`）オンデバイスのみ**。外部 LLM 不使用（SPEC L287）。
- Pro 機能（`canUseAICoaching`）。非対応機種・AI 無効・Free・データ希薄 → **何も出さない**（数式コーチングがベースライン）。

## 2. アーキテクチャ分割（watchOS 汚染回避）

Apple Intelligence は iPhone 専用（Apple Watch 非対応）。`OikomiKit` は watchOS とも共有するため、`import FoundationModels` を共有パッケージに置くと watch ビルドを壊し得る。よって **LLM 呼び出しと `@Generable` 型は iOS アプリターゲットに隔離**し、テスト可能なビジネスロジックは OikomiKit に置く。HealthKit を `#if canImport(HealthKit)` で隔離している既存方針と同思想。

| レイヤー | 置き場所 | FoundationModels 依存 |
|---|---|---|
| 月次ダイジェスト（純粋関数） | `OikomiKit/Coaching/MonthlyDigest.swift` | なし |
| プロンプト生成（純粋関数） | `OikomiKit/Coaching/MonthlySummaryPrompt.swift` | なし |
| 永続化 `@Model` + Repository | `OikomiKit/Models/MonthlySummary.swift` 他 | なし |
| `@Generable` 出力型 + FM 生成ラッパー | `App/iOS/Intelligence/` | **あり（iOS のみ）** |
| 月次振り返り UI（カード/画面/履歴） | `App/iOS/Views/` | あり |

## 3. コンポーネント

### 3.1 `MonthlyTrainingDigest`（純粋・OikomiKit）

月の構造化サマリ。Sendable な値型。`MonthlyDigest.build(...)` が生成する純粋関数。

```swift
public struct MonthlyTrainingDigest: Sendable, Hashable {
    public let yearMonth: String          // "2026-05"
    public let sessionCount: Int
    public let trainingDays: Int
    public let totalVolumeKg: Double
    public let muscleVolume: [MonthlyMuscleVolume]   // 部位別 月間セット数 + 状態
    public let personalRecords: [MonthlyPR]          // 今月達成した PR
    public let readiness: MonthlyReadiness?          // 平均・低/普通/高の内訳（取得できた場合）
    public let bodyPhase: BodyPhaseResult?           // 月末時点のフェーズ（呼び出し側が注入）

    public var isSubstantial: Bool { sessionCount >= 4 }  // 薄い月は振り返らない
}
```

補助型 `MonthlyMuscleVolume {muscle, sets}` / `MonthlyPR {exerciseName, weight, reps, estimated1RM}` / `MonthlyReadiness {average, lowDays, normalDays, highDays}`。`underTrainedMuscles: [MuscleGroup]` は週平均（月セット数 ÷ 月の週数）が MEV 未満の tracked 部位。

> YAGNI: 「伸びた種目/停滞種目」は PR 一覧が進捗を表し、単月の停滞判定はノイズが大きいため digest から外す。

```swift
public enum MonthlyDigest {
    /// 指定年月のデータからダイジェストを構築。対象月に完了セッションが無ければ nil。
    /// bodyPhase は端末依存（HealthKit）のため呼び出し側で取得して渡す。
    public static func build(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        snapshots: [HealthSnapshot],
        yearMonth: String,
        profile: TrainingProfile = .default,
        bodyPhase: BodyPhaseResult? = nil,
        calendar: Calendar = .current
    ) -> MonthlyTrainingDigest?
}
```

集計は既存ヘルパーを再利用: 部位別月間セット数は `Analytics.setCountByMuscleGroup(sets:in:)`（warmup/未完了/fullBody を除外）、MEV は `MuscleGroup.weeklySetTarget(for: profile).mev`、readiness は `HealthSnapshot.readinessScore`、フェーズは注入された `BodyPhaseResult`。月境界フィルタは `calendar` で行う。

### 3.2 `MonthlySummaryPrompt`（純粋・OikomiKit）

digest を Foundation Models 用の (instructions, prompt) 文字列に変換する純粋関数。LLM を呼ばないのでテスト可能（主要事実がプロンプトに含まれることを検証）。

```swift
public enum MonthlySummaryPrompt {
    public struct Payload: Sendable, Hashable {
        public let instructions: String   // 役割・トーン・制約（日本語/簡潔/具体/誇張禁止/医療助言禁止）
        public let prompt: String          // digest を事実列挙したユーザープロンプト
    }
    public static func make(from digest: MonthlyTrainingDigest, weightUnit: WeightUnit = .kg) -> Payload
}
```

`instructions` 例の要旨: 「あなたは筋トレのコーチ。以下の月次データだけを根拠に、日本語で簡潔な振り返りを書く。数値を誇張せず、データにない事実を作らない。医療・診断的助言はしない。」

### 3.3 `MonthlySummary` `@Model`（OikomiKit）+ Repository

生成結果を保存し履歴をさかのぼれる。**`swift-data-modeler` サブエージェントで作成**。CloudKit 互換（全プロパティ Optional/デフォルト、`@Attribute(.unique)` 不使用、relationship なし）。プロジェクトはフラットスキーマ（VersionedSchema 未使用）で、本件は**純粋な新規エンティティ追加**＝SwiftData 軽量マイグレーションが自動処理、明示的 `SchemaMigrationPlan` 不要。`OikomiKit.schemaModels` に `MonthlySummary.self` を登録する。

```swift
@Model public final class MonthlySummary {
    public var yearMonth: String = ""        // "2026-05"
    public var headline: String = ""
    public var highlights: [String] = []      // Exercise の [String] と同じ CloudKit 互換パターン
    public var watchPoints: [String] = []
    public var nextFocus: [String] = []
    public var generatedAt: Date = Date()
}
```

`MonthlySummaryRepository`（OikomiKit/Repositories）: `summary(forYearMonth:) -> MonthlySummary?` / `save(...)` / `allSummaries()`（履歴・新しい順）。重複生成は yearMonth 既存チェックで回避。

### 3.4 `MonthlySummaryContent`（`@Generable`・iOS）

Foundation Models の guided generation 出力。`@Guide` で件数・言語を制約。

```swift
@Generable struct MonthlySummaryContent {
    @Guide(description: "1文の総括（日本語）") var headline: String
    @Guide(description: "良かった点。2〜3個", .count(2...3)) var highlights: [String]
    @Guide(description: "気になる点。1〜3個", .count(1...3)) var watchPoints: [String]
    @Guide(description: "来月のフォーカス。1〜2個", .count(1...2)) var nextFocus: [String]
}
```

> `@Guide` の制約 API（`.count(_:)` 等）の正確なシグネチャは実装時に FoundationModels SDK で確認する。取得後 `MonthlySummary` の各フィールドへ素の String/[String] として写経する。

### 3.5 `MonthlySummaryGenerator`（iOS・FM ラッパー）

```swift
enum MonthlySummaryAvailability { case available, unavailable(reason: String) }

struct MonthlySummaryGenerator {
    static func availability() -> MonthlySummaryAvailability   // SystemLanguageModel.default.availability を写像
    func generate(payload: MonthlySummaryPrompt.Payload) async throws -> MonthlySummaryContent
}
```

`generate` は `LanguageModelSession(model:instructions:)` を作り `session.respond(to: payload.prompt, generating: MonthlySummaryContent.self)` を呼ぶ。可用性は `SystemLanguageModel.default.availability`（`.available` / `.unavailable(.deviceNotEligible | .appleIntelligenceNotEnabled | .modelNotReady)`）。

## 4. データフロー

```
月の SetRecord/Session/PR/HealthSnapshot
  → MonthlyDigest.build(yearMonth:)            [純粋・OikomiKit]  → MonthlyTrainingDigest?
  → MonthlySummaryPrompt.make(from:)           [純粋・OikomiKit]  → (instructions, prompt)
  → MonthlySummaryGenerator.generate()         [iOS・FM]          → MonthlySummaryContent
  → MonthlySummaryRepository.save(...)         [OikomiKit]        → MonthlySummary @Model
  → 月次振り返り画面 / 履歴で表示
```

## 5. 生成トリガー・フォールバック・ゲーティング

- **遅延生成（バックグラウンドなし）**: 新しい月に入り、先月の `MonthlySummary` が未生成 かつ 先月 digest が `isSubstantial`（セッション ≥ 4）かつ FM `.available` かつ Pro のとき、**ホームに「先月の振り返り」カード**を表示。タップ → 生成（ローディング）→ 保存 → 月次振り返り画面。以後はキャッシュ表示。
- **履歴**: 分析タブから「振り返り履歴」へ。`allSummaries()` を新しい順に一覧 → タップで詳細。
- **フォールバック / 非表示条件**（いずれかで カード・画面を出さない、クラッシュ/誤生成なし）:
  - FM 非対応機種 / AI 無効 / モデル未準備（`availability != .available`）
  - Pro 未契約（`canUseAICoaching == false`）
  - 先月データ希薄（`isSubstantial == false`）
- 生成失敗（throw）: エラー表示＋再試行ボタン。保存しない。

## 6. テスト（OikomiKit 純粋部）

- `MonthlyDigest.build`: 月境界フィルタ（前月/翌月のデータ除外）、集計（セッション数・総ボリューム・部位別・今月 PR 抽出・readiness 平均・bodyPhase）、対象月セッション 0 で nil、`isSubstantial` 閾値。
- `MonthlySummaryPrompt.make`: digest の主要事実（PR 種目名・数値・部位・フェーズ）が prompt 文字列に含まれる。instructions に制約文言が含まれる。
- `MonthlySummary` / `MonthlySummaryRepository`: 保存・yearMonth 取得・重複回避・履歴順。
- FM 呼び出し・@Generable・UI・可用性分岐は端末依存のため自動テスト対象外（手動確認）。

## 7. 変更/新規ファイル

| 区分 | パス | 内容 |
|---|---|---|
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlyDigest.swift` | digest 型 + build |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlySummaryPrompt.swift` | prompt 生成 |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Models/MonthlySummary.swift` | @Model（swift-data-modeler） |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Repositories/MonthlySummaryRepository.swift` | CRUD |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/OikomiKit.swift` | `schemaModels` に登録 |
| 新規 | `App/iOS/Intelligence/MonthlySummaryContent.swift` | @Generable |
| 新規 | `App/iOS/Intelligence/MonthlySummaryGenerator.swift` | FM ラッパー + 可用性 |
| 新規 | `App/iOS/Views/MonthlySummaryView.swift` | 月次振り返り詳細画面 |
| 新規 | `App/iOS/Views/MonthlySummaryHistoryView.swift` | 履歴一覧 |
| 改修 | `App/iOS/Views/HomeView.swift` | 「先月の振り返り」カード（条件付き） |
| 改修 | `App/iOS/Views/AnalysisTabView.swift` | 履歴へのエントリ |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/MonthlyDigestTests.swift` | テスト |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryPromptTests.swift` | テスト |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryRepositoryTests.swift` | テスト |

## 8. スコープ外

- 週次/オンデマンド生成、`BGTaskScheduler` による事前生成。
- ストリーミング表示（まず一括表示）。
- 音声読み上げ（Workout Buddy とは別物）、英語化（v2.0）。
- 数式コーチングの置き換え（NLP はあくまで上乗せ）。

## 9. CLAUDE.md / SPEC 整合

- ビジネスロジック（digest/prompt/永続化）は OikomiKit、UI と端末依存 LLM 呼び出しはアプリ側。
- `@Model` 追加は `swift-data-modeler` 経由（CLAUDE.md 規律 4）。フラットスキーマへの純粋追加のため `schemaModels` 登録のみ。
- オンデバイス Foundation Models のみ（外部 LLM 不使用）。
- コーチング/サマリ文言は日本語（LLM 出力も日本語固定）。
- SPEC L220/L441/L191/L287 と一致。仕様変更は不要（既存記述の実装）。

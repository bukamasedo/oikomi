# 設計書: コーチング拡充 Spec 1 — レディネス & オートレギュレーション中核

- 日付: 2026-05-30
- 対象: `OikomiKit/Coaching`（純粋関数）＋ `HealthSnapshot` モデル＋ `TodayConditionCard`（最小UI）
- ステータス: 設計合意済み・実装計画(writing-plans)待ち
- 関連: 本書は3スペック構成の第1弾。Spec 2（ボリューム＆リカバリー知能）/ Spec 3（自然言語コーチング = Foundation Models）は末尾「後続スペックへの申し送り」を参照。

---

## 1. 背景とゴール

### 1.1 なぜやるか
コーチングは Oikomi の Pro 収益の核（SPEC上、Live Activity を Free 開放した結果、Pro 価値は「HRV × AI コーチング」に収束）。現状のコーチングは以下の弱点を持つ:

- **取得済みなのに未使用の信号が多い**: `SetRecord.rpe`(1-10)、睡眠スコア、安静時心拍、体組成はいずれも記録/取得されているがコーチングに流入していない。ディロード判定は **HRV 単独**。
- **HRV 統計が素朴**: 単純平均比較（直近3日 vs 14日ベースライン、`current <= baseline × 0.85`）で、HRVガイドトレーニングの標準である分散考慮（z-score / 変動係数）が無い → 誤発火しやすい。
- **PR 予測が浅い**: Epley 固定・点推定・線形回帰のみ。RPE 補正なし、停滞検出なし、信頼区間なし。

### 1.2 Spec 1 のゴール
v1.0 コーチングを以下に引き上げる（すべてオンデバイス数式、Foundation Models 不使用）:

1. **A2 + C3 — コンディション総合スコア（レディネス）**: HRV(z-score) を主軸に睡眠・安静時心拍を統合した 0-100 スコアへ一本化。ディロード/強度提案の土台にする。
2. **A1 — RPE オートレギュレーション（セッション間）**: 直近の RPE から次回推奨重量を ± して提案。
3. **C1 — PR 予測の高度化**: レップ域別1RM式・RIR補正・停滞検出・信頼レンジ。

---

## 2. スコープ

### 2.1 含む（In Scope）
- `Coaching/ReadinessScore.swift`（新規・純粋関数）
- `Coaching/Analytics.swift` の改修（`hrvDeloadAdvice`→`readinessAdvice`、`autoregulationAdvice` 追加、`prPredictions` 改修）
- `Coaching/OneRepMax.swift` の拡張（`estimate(weight:reps:rpe:)`）
- `Models/HealthSnapshot.swift` に `readinessScore: Int?` 追加＋ `VersionedSchema` 移行
- `Health/HealthStore.swift` に `baselineStats(...)` ヘルパー追加
- `TodayConditionCard` に総合スコア表示＋データソース注記（最小UI）
- 既存の `CoachingAdvice → Home CoachingChip` パイプラインへの新アドバイス流入
- `docs/SPEC.md` §4.2.2 の先行更新

### 2.2 含まない（Out of Scope — 後続スペック）
- **B（その場に出す）**: Apple Watch コーチング、PR リアルタイムお祝い、セッション後サマリ、トレ前レディネス画面、チップの操作化（適用/スヌーズ/フィードバック）。
- **Spec 2**: 部位別リカバリー、MEV/MAV 個人化・漸進性過負荷、体組成連動。
- **Spec 3 / D**: Foundation Models 自然言語サマリ。
- **戒め（§5.4 / Tier 5）に該当するもの全般**: チャットコーチ、フォーム動画、外部 LLM、ソーシャル。本スペックは「提案/スコア」の範囲に留まり、対話エージェントは作らない。

---

## 3. 現状（実装の事実確認）

調査で確認した、設計の前提となる事実:

- **Pro ゲーティングは購読状態のみで決まる**。`ProGate` の各フラグは `SubscriptionManager.shared.isProActive`（StoreKit entitlements）由来。**端末能力（Apple Intelligence / ペア Watch / HealthKit）をゲートに AND していない**。HealthKit 可用性は Pro ゲート通過後に `HealthStore` 内で確認し、欠損時は nil/[] を返す（クラッシュしない）。
- **Foundation Models / Apple Intelligence はリポジトリ全体で使用ゼロ**（v1.2 ロードマップのみ）。現状の全コーチングは純粋数式で、**iOS 26 が動く全機種で同一に動作**する。
- **Apple Watch のハード要件は無い**。iPhone 単体で記録・履歴・全 Pro コーチングが動く。`WCSyncBridge` の同期は未接続時 no-op。
- **HRV(SDNN) と安静時心拍は Apple Watch 計測**。Watch 無し（他ソース無し）だと HealthKit にサンプルが無く `todayValue→nil` / `dailySeries→[]`。睡眠は iPhone/サードパーティ由来でも入りうる最有力の残存信号。
- **既存の劣化は概ねグレースフルだが「黙って消える」**: HRV が無いと `TodayConditionCard` は「—」、HRV ディロード助言は `guard !hrvSeries.isEmpty` で無言スキップ。**「非Pro」と「Proだがデータ無し」をUIが区別していない**のが唯一の broken-looking 面。
- **未実装の確認**: `readiness`/`z-score`/`標準偏差`/`ReadinessScore` 等の語はコードに存在しない。`SetRecord.rpe` は定義のみでコーチング未消費。

---

## 4. 設計

### 4.1 レディネススコア（A2 + C3）

新規 `OikomiKit/Coaching/ReadinessScore.swift`。純粋関数＋値型のみ（テスト容易）。

#### 4.1.1 HRV 統計化（C3）
- **ローリングベースライン**: HRV(SDNN) の直近ウィンドウ（最大60日、最低14日）から平均 `mean` と標準偏差 `sd` を算出。
- **z-score**: `z = (today − mean) / sd`（`sd == 0` の保護あり）。
- **平常域**: `mean ± 0.5sd`。下回れば「抑制（回復優先）」、上回れば「超回復」。
- **データ不足フォールバック**: ベースライン有効サンプルが14日未満なら HRV 成分を「利用不可」とし、後述の信号欠損処理に委ねる（既存の単純平均比較は廃止）。
- 安静時心拍も同様に z-score 化し、**符号反転**（高いほど悪い）して扱う。

#### 4.1.2 総合スコア（0-100）と一本化（Q1: HRV主）
- 3つのサブスコアを 0-100 に正規化:
  - HRV: z を 0-100 にマップ（z=0 → 約50を中心にスケール）。
  - 睡眠: 既に 0-100（`HealthStore` の `sleepScore`）。※4.1.4 の検証注記あり。
  - 安静時心拍: 反転 z を 0-100 にマップ。
- **重み（HRV主）**: HRV 0.5 / 睡眠 0.3 / 安静時心拍 0.2（`enum` 化した定数。将来 goal 別に変更可）。
- 出力値型:
  ```
  ReadinessScore {
    value: Int            // 0-100（利用可能信号のみで算出）
    band: Band            // .low / .normal / .high
    confidence: Confidence // .high / .medium / .low
    contributors: [Contributor]  // どの信号が何点寄与したか（ソースラベル用）
    hrvZ: Double?         // デバッグ/将来の自然言語サマリ用
  }
  ```
- **band 閾値**: 定数化（暫定 `low < 40 <= normal < 70 <= high`）。実装時にテストで調整。

#### 4.1.3 ディロード助言への統合
- 既存 `Analytics.hrvDeloadAdvice` を `readinessAdvice(readiness:)` に置換。
  - `band == .low` → 「今日は回復優先。約80%の重量で組みましょう」（`severity: .warning`）
  - `band == .high` → 「コンディション良好。PR 狙える日です」（`severity: .success`、PR予測と連動）
  - `band == .normal` → 助言なし（nil）
- `deloadAdvice` の他2信号（連続トレ日数 ≥5、週ボリューム比 >130%）はそのまま残し、readiness と統合（合算 `[CoachingAdvice]` を impact 降順）。
- **readiness が算出不能（全信号欠損）の場合は従来通り、連続日数・ボリューム比だけで判定**（＝現状動作を保証）。

#### 4.1.4 部分入力・データ可用性の明示（調査由来の強化）
- **nil を 0 扱いしない**。利用可能な信号だけで重みを再配分して算出（例: HRV/RHR 欠損で睡眠のみ → 睡眠 100% に再正規化）。`hrvAverage` の `guard !values.isEmpty` パターンに倣う。
- `confidence` を `band` とは独立に持つ:
  - 3信号揃い → `.high`
  - 1〜2信号 → `.medium`
  - 信号無し → スコア自体を nil（readinessAdvice はスキップ）
- `contributors` から**データソースラベル**を生成（例: 「睡眠のみで算出」「Apple Watch 未接続のため HRV なし」）。これを 4.5 の `TodayConditionCard` で表示し、「黙って消える」を解消する。
- **睡眠スコアの検証 TODO**: 現行 `sleepScore` は `asleep時間 / 8h × 100` の素朴な代理指標（`HealthStore.swift` 付近）。Watch 無しユーザーでは睡眠が支配的入力になりうるため、これ単独でレディネスを駆動する前に妥当性をテストで確認する（理由併記）。

#### 4.1.5 永続化
- セッション開始時に `ReadinessScore` を算出し `HealthSnapshot.readinessScore: Int?` に保存。
- 現状「死蔵」の per-session snapshot を「HRV が低い日にどう動けたか」の相関に使えるようにする布石（実利用は Spec 2 以降でも可）。

### 4.2 RPE オートレギュレーション（A1・セッション間）

新規 `Analytics.autoregulationAdvice(sets:routines:targetRPE:)`。

- 各種目について直近の完了ワーキングセット（`isCompleted && !isWarmup`）の `rpe` を参照。
- **目標 RPE = 8（RIR 2）** をデフォルト定数（将来 goal 別に拡張）。
- 判定（直近2セッション以上にデータがある種目のみ）:
  - 一貫して **RPE ≥ 9**（重すぎ）→ 次回推奨重量を **減**（目標RPEに寄せて概ね −5%、丸めは既存の重量丸め規則に従う）
  - 一貫して **RPE ≤ 6**（軽すぎ）→ **増**（漸進性過負荷、+2.5〜5%）
  - それ以外 → 助言なし
- 出力は `CoachingAdvice` チップ: 「次回ベンチは 60→62.5kg が目安」。
- **読み取り提案のみ**。`RoutineExercise.plannedWeight` への自動書き込み（=「適用」操作）は B スペック。
- **Graceful skip**: `rpe == nil` または直近データ不足の種目は対象外。**HRV/Watch に非依存**で動くため、Watch 無し・非AI機種の Pro ユーザーにもフル価値。

### 4.3 PR 予測の高度化（C1）

`Analytics.prPredictions` を改修し、`OneRepMax` を拡張。

#### 4.3.1 レップ域別1RM式 + RIR 補正
新規 `OneRepMax.estimate(weight:reps:rpe:) -> Double`:
- **実効レップ** `effectiveReps = reps + max(0, 10 − rpe)`（`rpe == nil` なら `reps` のまま＝現状互換）。RPE8(RIR2) のセットは「あと2レップ可能」として限界推定を補正。
- **式選択**: `effectiveReps` 1〜5 → Epley、6〜12 → Brzycki、>12 → 推定を返しつつ低信頼フラグ（呼び出し側で重みを下げる）。
- 既存の `epley` / `brzycki` プリミティブは温存（`best(from:)` の Epley 固定箇所は本関数経由に）。

#### 4.3.2 回帰・停滞・信頼区間
- `prPredictions` は**生セット**（weight, reps, rpe）から `estimate(...)` で系列を再構成（従来の保存済み `estimated1RM` 依存を脱し、RIR 補正を効かせる）。
- セッション毎の最大 `estimate` を時系列化し、最後の `windowSize`(=10) を最小二乗回帰。
- 既存ゲート維持: `minSamples`(=5) / `minR2`(=0.3) / `slope > 0` / 予測値 > 現PR。
- **停滞検出**: 上記を満たさず、かつ傾き≈0（ノイズ域）＋十分なサンプル → 新アドバイス「○○が停滞気味。レップ域・頻度・種目の変更を検討」（`severity: .info`/`.warning`）。
- **信頼レンジ**: 回帰の予測標準誤差からマージンを出し「推定 87.5kg（±2.5）」表示。
- **⚠️ 比較の整合**: 現 PR ベースライン `PersonalRecord.estimated1RM` は Epley 保存値。予測側を新方式にするため、**比較時は現 PR も同じ `estimate(...)` 方式で再算出**し apples-to-apples にする。

### 4.4 ゲーティング方針（端末能力との関係）

- 新コーチング（readiness / autoregulation / PR）は**既存パターン踏襲**: `ProGate.canUseAICoaching`（= `isProActive`）で一本化。新フラグは増やさない（Pro 価値を「HRV × AI コーチング」に束ねる方針と一致）。
- HRV/睡眠/RHR を使う部分は実質 `isProActive AND HealthKit権限 AND データ有り`。ただし今日の「無言の—」ではなく、4.1.4 の `confidence`/ソースラベルで**理由を明示**する。
- **autoregulation と PR 予測は HealthKit 非依存**なので、HRV 欠損で決してブロックしない。Watch 無し・非AI機種の Pro ユーザーにも価値が届く。

### 4.5 露出（最小UI・論点2=a）

- 新アドバイスは既存 `CoachingAdvice → Home CoachingChip` に**そのまま流れる**（新規 UI なし）。
- `TodayConditionCard`（既に HRV/睡眠/RHR の生値を表示）に:
  - **総合スコア（0-100）** を追加表示。
  - `confidence` が `.high` でない時は**データソース注記**（例: 「睡眠のみで算出・Apple Watch 未接続」）を一行表示。
- Watch/AI 画面・操作化・セッション後サマリは B / 後続スペック。

---

## 5. アーキテクチャ / 変更ファイル

| 区分 | ファイル | 変更 |
|---|---|---|
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/ReadinessScore.swift` | 総合スコア + z-score 統計（純粋関数・値型） |
| 改修 | `Coaching/Analytics.swift` | `hrvDeloadAdvice`→`readinessAdvice`、`autoregulationAdvice` 追加、`prPredictions` 改修（停滞/CI/RIR系列） |
| 改修 | `Coaching/OneRepMax.swift` | `estimate(weight:reps:rpe:)`（式選択 + RIR 補正）追加、`best` を経由に |
| 改修 | `Models/HealthSnapshot.swift` | `readinessScore: Int?` 追加（Optional, CloudKit 互換） |
| 新規/改修 | スキーマ移行（`VersionedSchema` + `SchemaMigrationPlan`） | 新スキーマ版で `readinessScore` 追加。**`swift-data-modeler` サブエージェント使用** |
| 改修 | `Health/HealthStore.swift` | `baselineStats(for:window:) -> (mean, sd, n)?` ヘルパー（HRV/RHR） |
| 改修 | `App/iOS/.../TodayConditionCard.swift` | 総合スコア + データソース注記の表示 |
| 改修 | `App/iOS/Views/HomeView.swift` | 新アドバイス生成の呼び出し追加（既存集約に統合） |
| 文書 | `docs/SPEC.md` §4.2.2 | 先行更新（後述） |

**規律**: ビジネスロジックは `OikomiKit` に置く（UI に書かない）。UI は Repository / Analytics 経由。CloudKit 互換ルール（全プロパティ Optional/デフォルト値、enum は rawValue 保存、`@Attribute(.unique)` 不使用、`@Relationship` に `inverse:`、スキーマ変更は VersionedSchema 経由）を厳守。

---

## 6. データモデル & マイグレーション

- `HealthSnapshot` に `readinessScore: Int?`（Optional なので CloudKit 互換、既存レコードは nil）。
- `VersionedSchema` を1版上げ、`SchemaMigrationPlan` に軽量移行（フィールド追加のみ）を追加。
- `swift-data-modeler` サブエージェントで設計・実装（CLAUDE.md 規律）。
- 移行テスト: 旧スキーマ → 新スキーマで `readinessScore` 既定 nil を確認。

---

## 7. データフロー

1. **セッション開始** → `HealthStore` が HRV/睡眠/RHR を取得（既存）→ `ReadinessScore` 算出 → `HealthSnapshot.readinessScore` に保存。
2. **Home 表示** →
   - `deloadAdvice`（`readinessAdvice` + 連続日数 + ボリューム比）→ `[CoachingAdvice]`
   - `autoregulationAdvice(sets, routines)` → `[CoachingAdvice]`
   - `prPredictions(sets, records)`（RIR系列・停滞・CI）→ `[CoachingAdvice]`
   - すべて既存の `CoachingChip` リストへ（impact 降順、上位3など既存ロジック踏襲）。
3. **TodayConditionCard** → 当日の `ReadinessScore`（live 算出 or snapshot）を表示＋ソース注記。
4. **通知**（既存 `CoachingNotificationScheduler`）→ HRV ディロード通知は readiness の `.low` 由来に、PR 予測通知は新 CI を反映。

---

## 8. テスト計画（TDD・OikomiKit）

実装前にテストを書く（OikomiKit の規律）。`swift test --package-path Packages/OikomiKit`。

- **ReadinessScore**: z計算、重み付き合成、部分入力の重み再配分、`confidence` 判定、`band` 閾値、ベースライン<14日でのフォールバック、`sd==0` 保護。
- **OneRepMax.estimate**: 式選択境界（5/6、12/13）、RIR補正（rpe=8 で +2 レップ相当）、`rpe==nil` の現状互換。
- **autoregulationAdvice**: 高RPE→減・低RPE→増・適正→無・`rpe==nil`→skip・データ不足→skip。
- **prPredictions**: RIR系列回帰、停滞検出（傾き≈0）、CI マージン、既存ゲート（minSamples/minR2/slope>0/予測>現PR）維持、現PR の同方式再算出。
- **readinessAdvice 統合**: `deloadAdvice` に正しく合算され impact 降順。
- **マイグレーション**: `readinessScore` 既定 nil。
- 既存 99 テストの非回帰。

---

## 9. SPEC.md 先行更新（§4.2.2）

CLAUDE.md 規律「仕様変更が必要なら SPEC.md を先に更新」に従い、実装前に §4.2.2 を更新:

- 「3つに絞る」枠を見直し、**ディロードを readiness（HRV+睡眠+RHR 統合, z-score）ベース**に改訂。
- **RPE オートレギュレーション（セッション間負荷提案）** を新コーチングタイプとして追記。
- **PR 予測に RIR 補正・停滞検出・信頼レンジ** を追記。
- これは v1.0 コーチング柱の**意図的なスコープ拡張**である旨を明記（Pro 収益の核を強化する判断）。
- **Pro 訴求は「Apple Intelligence」ではなく「HealthKit 連動コーチング」**であることを明確化。自然言語サマリ(v1.2)は「対応機種で点灯するボーナス」と位置づけ、非AI機種でも Pro はフル価値、と整理。

---

## 10. エッジケース / リスク

- **HRV は SDNN（RMSSD ではない）**: 相対比較（z-score）には十分。ベースラインは最低14日必要。不足時はフォールバック。
- **Free ユーザー**: HealthKit 読取なし → readiness=nil → ディロードは日数/ボリューム信号のみ（現状維持）。新コーチングは全て `canUseAICoaching` ゲート内で SPEC と一致。
- **Watch 無し Pro ユーザー**: HRV/RHR 欠損 → readiness は睡眠中心の `confidence:.medium/.low`。RPE自動調整・PR予測はフル。ソース注記で理由提示。
- **PR 予測の方式変更**: 保存済み `estimated1RM`（Epley）と新 `estimate` の不整合に注意 → 比較は両側同方式。
- **睡眠代理指標の妥当性**: 4.1.4 の TODO。Watch 無しで睡眠が支配的になる前提で要検証。
- **非回帰**: `prPredictions` の入力ソース変更（保存値→生セット）で既存テスト/挙動が変わりうる → テストで担保。

---

## 11. 後続スペックへの申し送り

- **Spec 2（ボリューム＆リカバリー知能）**: 部位別リカバリー（最終トレ日/蓄積疲労）、MEV/MAV 個人化＋漸進性過負荷、体組成連動（相対筋力・増量/減量フェーズ）。`HealthSnapshot.readinessScore` の蓄積を相関分析に活用。
- **Spec 3 / D（自然言語コーチング）**: Foundation Models で週次/月次の自然な日本語サマリ。**必須ガードレール**: `SystemLanguageModel.availability` を唯一のエントリ判定にし、`.available` 以外（`.deviceNotEligible` 等）は**決定論的テンプレ文へフォールバック**。Apple Intelligence を前提にしない（HealthKit コードが権限後に可用性を仮定するのとは異なる扱い）。`OikomiKit/Coaching/NaturalLanguageSummary` 等に閉じ込め、UI からモデルロジックを排除。`confidence`/ソースフラグを渡し、HRV 欠損時に HRV 由来の発話を生成しないようにする。
- **B（その場に出す・操作化）**: Watch コーチング、PR お祝い、セッション後サマリ、チップの「適用/スヌーズ/役に立った?」。autoregulation の `plannedWeight` 自動反映はここ。

---

## 12. 完了の定義（Spec 1）

- 上記の純粋関数・モデル・最小UIが実装され、TDD テストが全て成功（既存99 + 新規）。
- `/build` iOS シミュレータビルド成功、`/format`・`/lint` 準拠。
- SPEC.md §4.2.2 更新済み。
- Free / Pro / Watch無し / 非AI機種の各シナリオで「クラッシュなし・理由が分かる劣化」を満たす。

# 設計書: Spec 2-A4 — 部位別リカバリー（Muscle Recovery）

- 日付: 2026-05-31
- 対象: `OikomiKit/Coaching`（純粋関数）＋ `MuscleGroupAnalysisSection`（分析タブ「部位別」）＋ `combinedCoachingAdvice` への差し込み
- ステータス: 設計合意済み・実装計画(writing-plans)待ち
- 位置づけ: Spec 2（ボリューム＆リカバリー知能）を独立3機能に分割した中の**第1弾 = A4**。続く C2（MEV/MAV個人化）/ A3（体組成連動）は別サブスペック。

---

## 1. 背景とゴール

### 1.1 なぜやるか
現状、リカバリー/疲労/「最終トレ日」の概念は**コードに一切ない**（`recover`/`fatigue`/`lastTrained` 等で grep 0 件）。唯一の回復シグナルは `deloadAdvice` の**全身**連続日数で、「胸は回復済みだが脚は疲労」のような部位別の状態は出せない。一方、必要な素材はすべて揃っている: `SetRecord.completedAt`（per-set タイムスタンプ）＋ `Exercise.muscleGroups`（筋群マッピング）＋ 既存の部位別集計パターン（`Analytics.setCountByMuscleGroup` の fan-out）。

### 1.2 ゴール
部位ごとの**回復状態**（回復済 / 回復中 / 疲労 / 未実施）と**回復率（0-100%）**を、`SetRecord` から純粋関数で導出し、分析タブ「部位別」に表示し、「今は○○が回復済み。次のトレ候補」というコーチング提案を出す。**新スキーマ不要・自重不要・HealthKit不要**（部位ローカルで完結）。

---

## 2. スコープ

### 2.1 含む（In Scope）
- 新規 `Coaching/MuscleRecovery.swift`（純粋関数 + 値型 + 部位別基準時間テーブル）
- `Analytics.combinedCoachingAdvice` への `recoveryAdvice` 差し込み
- `MuscleGroupAnalysisSection`（部位別タブ）に「回復状態」サブセクション追加
- ユニットテスト（`MuscleRecoveryTests` + `combinedCoachingAdvice` 統合テスト）

### 2.2 含まない（Out of Scope）
- **トレ前（ルーティン開始時）のインライン提示** → B スコープ（セッション実行 UI への組み込みが必要）
- **HealthKit / `readinessScore` による全身モディファイア**（一律スケール）→ 今回は部位ローカルのみ。将来拡張余地は残す
- **部位別の目標頻度設定 UI** → C2 / 将来
- C2（MEV/MAV個人化・漸進性過負荷）・A3（体組成連動）→ 別サブスペック

---

## 3. 現状（実装の事実確認）

- リカバリー/疲労/最終トレ日の概念・モデル・関数は**存在しない**（新規追加）。
- `SetRecord.completedAt: Date`（per-set）＋ `set.exercise?.muscleGroups: [MuscleGroup]` で「部位別の最終トレ日」「部位別の直近セット」を導出可能。
- `MuscleGroup`（13ケース、`.fullBody` は untracked sentinel、`displayName` で JP ラベル）と `WeeklySetTarget`/`isTracked` は流用できるキー次元。
- 既存の部位別 fan-out（`for group in set.exercise?.muscleGroups`、warmup/incomplete/.fullBody 除外）は `setCountByMuscleGroup`/`volumeByMuscleGroup` のパターン（`Analytics.swift`）。新関数はこの near-copy で「max(completedAt)」を保持する形。
- 表示は `MuscleGroupAnalysisSection.setsCard` の「行 + バー + 状態チップ」パターンを踏襲できる。
- アドバイスは `CoachingAdvice{title,message,severity,impact}` ＋ `combinedCoachingAdvice`（warning 優先 → impact 降順 → 上位 `limit`）の確立パターンに乗せる。

---

## 4. 設計

### 4.1 回復モデル（純粋関数）

各 tracked 筋群（`MuscleGroup.allCases` から `weeklySetTarget.isTracked == true`、= fullBody 除外）について:

1. **最終トレ日**: その筋群のワーキングセット（`!isWarmup && isCompleted`）の `max(completedAt)` を `lastTrained`。該当なし → `untrained`。
2. **直近セッションの負荷**: `lastTrained` と同じ**カレンダー日**にその筋群を刺激したワーキングセット群 → `setCount` と `avgRPE`（rpe 非 nil の平均、無ければ nil）。
3. **回復ウィンドウ（時間）**:
   ```
   windowHours = baseHours
               + min(maxExtraHours, max(0, setCount − freeSets) × hoursPerExtraSet)
               + rpeAdjustHours
   windowHours = max(windowHours, baseHours × 0.5)   // 下限
   ```
   - **baseHours（部位別テーブル、定数）**:
     - 大筋群: quads / hamstrings / glutes / back → **72**
     - 中: chest / shoulders → **48**
     - 小: biceps / triceps / forearms / calves / abs / obliques → **36**
   - **負荷伸縮**: `freeSets = 6`, `hoursPerExtraSet = 3`, `maxExtraHours = 24`（6セット超は1セット+3h、最大+24h）。
   - **RPE 加味（graceful）**: `avgRPE ≥ 8.5 → +6` / `avgRPE ≤ 6 → −6` / それ以外・nil → `0`。
4. **回復率**: `fraction = clamp(elapsedHours / windowHours, 0, 1)`（`elapsedHours = (referenceDate − lastTrained) / 3600`）。
5. **経過日数**: `daysSinceLastTrained = カレンダー日差(lastTrained, referenceDate)`（Int）。`untrained` は nil。
6. **状態** `RecoveryState`:
   - `.recovered`（回復済）: `fraction ≥ 1.0`
   - `.recovering`（回復中）: `0.5 ≤ fraction < 1.0`
   - `.fatigued`（疲労）: `fraction < 0.5`
   - `.untrained`（未実施）: 記録なし（fraction = 1.0、daysSince = nil として扱う）

> 定数（baseHours・freeSets・hoursPerExtraSet・maxExtraHours・RPE閾値・状態閾値）はすべて**暫定値**。実装時にテストで検証・調整する。

### 4.2 値型・API・ファイル

| 区分 | パス | 内容 |
|---|---|---|
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleRecovery.swift` | 下記すべて |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift` | `combinedCoachingAdvice` の統合リストに `MuscleRecovery.recoveryAdvice(...)` を追加 |
| 改修 | `App/iOS/Views/Analysis/MuscleGroupAnalysisSection.swift` | 「回復状態」サブセクション追加 |

`MuscleRecovery.swift` の中身:
```
public enum RecoveryState: String, Sendable { case recovered, recovering, fatigued, untrained }

public struct MuscleRecoveryRow: Sendable, Identifiable, Hashable {
    public var id: MuscleGroup { muscle }
    public let muscle: MuscleGroup
    public let daysSinceLastTrained: Int?   // untrained は nil
    public let recoveryFraction: Double     // 0...1
    public let state: RecoveryState
}

public enum MuscleRecovery {
    // 部位別基準回復時間（時間）。fullBody は untracked のため含めない。
    static func baseHours(for muscle: MuscleGroup) -> Double { ... }   // 大72/中48/小36

    // 全 tracked 筋群の回復状態。並び: untrained を末尾に固定し、残りを recoveryFraction 降順
    // （タイブレークは muscle.rawValue 昇順）。
    public static func report(sets: [SetRecord], referenceDate: Date = Date(), calendar: Calendar = .current) -> [MuscleRecoveryRow]

    // 直近〜10日に鍛えて今 .recovered の筋群を「次のトレ候補」として最大1件にまとめる。
    public static func recoveryAdvice(sets: [SetRecord], referenceDate: Date = Date(), calendar: Calendar = .current) -> [CoachingAdvice]
}
```
> `CoachingAdvice` は `Analytics.swift` 定義（同一モジュール）。Analytics.swift が既に大きいため、リカバリーは**新ファイルに分離**する。

### 4.3 コーチング提案（`recoveryAdvice`）

- **対象**: `daysSinceLastTrained != nil && daysSinceLastTrained ≤ 10 && state == .recovered` の筋群（= 最近の疲労から回復した、回転中の部位）。
- **未実施・長期未トレは除外**（「最近の疲労からの回復」ではない。ボリューム不足は MEV/MAV 側の責務）。
- **最大1件に集約**: 例「胸・肩・背中が回復済み。次のトレ候補です。」`severity: .info`、`impact` は info 帯の中位（例 `100 + 対象数×10`。warning は `combinedCoachingAdvice` で先に並ぶので埋もれない）。対象ゼロなら空配列。
- `combinedCoachingAdvice` の統合リストに加える（`deload + autoreg + prPredictions + plateau + volume + recovery`）。既存の warning 優先→impact 降順→`prefix(limit)` にそのまま乗る。

### 4.4 露出（分析タブ「部位別」）

- `MuscleGroupAnalysisSection`（既存・`sets: allSets` を受領済み）に **「回復状態」サブセクション**を追加。`MuscleRecovery.report(sets: allSets)` を表示。
- 行: `muscle.displayName` ＋ **回復バー（fraction）** ＋ 状態チップ ＋「最終: N日前 / 未実施」。
  - 色: 回復済=`statGreen` / 回復中=`statOrange` / 疲労=`statRed` / 未実施=グレー（`.secondary`）。既存 `setsCard` のバー/チップ実装パターンを流用（新規コンポーネントは最小）。
- ソート: `untrained` を末尾に固定し、残りを `recoveryFraction` 降順（回復済が上）、タイブレーク `muscle.rawValue`（= `report` の戻り順）。
- 既存の MEV/MAV（`setsCard`）とは別概念の別カードとして並置。

---

## 5. データフロー

1. 分析タブ「部位別」表示 → `MuscleGroupAnalysisSection` が手持ちの `allSets` で `MuscleRecovery.report(sets:)` を算出 → 回復状態カード描画（HealthKit 不要・同期不要）。
2. Home / 全件コーチング → `Analytics.combinedCoachingAdvice(...)` が内部で `MuscleRecovery.recoveryAdvice(sets:)` を呼び、統合リストに合流。
3. ゲーティング: 部位別セクションは既存どおり `ProGate.canSeeAdvancedAnalytics`、コーチングは `canUseAICoaching`（純粋データなので追加ゲート不要）。

---

## 6. テスト（TDD・OikomiKit）

実装前にテストを書く。`swift test --package-path Packages/OikomiKit`。

- **`MuscleRecovery.report`**: 経過日数算出 / `fraction` の clamp / 基準時間（大72・中48・小36）/ 負荷伸縮（6超セットで延長・上限+24h）/ RPE加味（≥8.5で延長・≤6で短縮・nilで無影響）/ 状態閾値（≥1.0 recovered・0.5–1.0 recovering・<0.5 fatigued）/ 未実施 → daysSince nil・`.untrained` / fullBody 除外 / マルチ筋群の compound が各筋群に反映。
- **`MuscleRecovery.recoveryAdvice`**: 回復済の集約（複数筋群を1チップ）/ 未実施・10日超は除外 / 対象ゼロで空。
- **`combinedCoachingAdvice` 統合**: recovery が統合リストに混ざり、warning 優先→impact ソートに乗る。
- 既存テストの非回帰。

---

## 7. エッジケース / リスク

- **同日複数セッション**: 「最終トレ日」は `max(completedAt)`。負荷は同カレンダー日のその筋群ワーキングセット合算（セッション跨ぎでも同日なら合算）。
- **マルチ筋群種目（compound）**: 既存パターン同様、各筋群にフルカウント（synergist の按分はしない）。これにより compound 翌日は関与筋すべてが「疲労」寄りになる（妥当）。
- **未実施筋群**: `daysSince nil`・`.untrained`・`fraction 1.0`。コーチングの ready リストには入れない。UI は「未実施」表示。
- **RPE 欠損**: 多くのユーザーは RPE 未入力 → RPE 加味は graceful（無影響）。負荷伸縮はセット数ベースで常に効く。
- **暫定定数の妥当性**: baseHours/伸縮係数は文献ベースの初期値。`MuscleVolumeTargets` の MEV/MAV 同様、後で個人化（C2 と連携）の余地。テストは「相対挙動」（多く叩いた方が長い・大筋群が長い 等）を主に検証し、絶対値は緩めに。

---

## 8. 後続への申し送り
- 全身 `readinessScore`（Spec 1 予約フィールド）で部位回復を一律スケール（低readiness日は全部位を回復遅めに）→ 将来拡張。
- トレ前インライン提示・「回復済み部位だけでルーティン提案」→ B スコープ。
- C2（MEV/MAV個人化）と回復頻度の統合（部位別の目標頻度）。

## 9. 完了の定義
- 上記純粋関数・値型・最小UIが実装され、TDD テスト全成功（既存 + 新規）。
- `/build` iOS ビルド成功、`/format`・`/lint` 準拠。
- 部位別タブに回復状態が表示され、`combinedCoachingAdvice` に回復提案が混ざる。
- Free / Pro / RPE未入力 / 未実施筋群でクラッシュなし・妥当な表示。

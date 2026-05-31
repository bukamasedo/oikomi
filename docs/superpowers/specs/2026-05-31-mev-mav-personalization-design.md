# 設計書: Spec 2-C2 — MEV/MAV個人化 + 漸進性過負荷

- 日付: 2026-05-31
- 対象: `OikomiKit/Coaching`・`OikomiKit/Models`（純粋関数 + UserDefaults プロファイル）＋ 設定タブ・分析タブ「部位別」・Home
- ステータス: 設計合意済み・実装計画(writing-plans)待ち
- 位置づけ: Spec 2（ボリューム＆リカバリー知能）の**第2弾 = C2**。第1弾 A4（部位別リカバリー）はマージ済み。第3弾 A3（体組成連動）は別サブスペック。

---

## 1. 背景とゴール

### 1.1 なぜやるか
部位別 MEV/MAV（週推奨セット数レンジ）は現状 `MuscleGroup.weeklySetTarget` に**固定定数**（Schoenfeld 中央値）でハードコードされ、経験・目標・個人差を一切反映しない（`MuscleVolumeTargets.swift:9` のコメント自身が「v1.1 でユーザーカスタマイズを追加する想定」と予告）。また「来週 +N セットで MAV に向けて漸進」のような**目標連動の漸進性過負荷ガイドが存在しない**（`volumeAdvice` は前週比のみで目標非連動）。

### 1.2 ゴール
ユーザーの **経験レベル × トレ目標** を UserDefaults に保存し、それで MEV/MAV を個人化（分析タブ「部位別」のバー/チップが個人化目標を反映）。さらに今週の部位別セット数と個人化目標から **漸進性過負荷アドバイス**（不足→増やす / 適正→来週+1〜2 / 過多→維持orディロード）を `combinedCoachingAdvice` に流す。**オンデバイス・Pro 連動・新スキーマ不要**（プロファイルは UserDefaults）。

---

## 2. スコープ

### 2.1 含む（In Scope）
- 新 enum `ExperienceLevel` / `TrainingGoal`（`Models/Enums.swift`）
- 新 `Coaching/TrainingProfile.swift`（`TrainingProfile` 値型 + `TrainingProfilePreference` UserDefaults アクセサ）
- `MuscleVolumeTargets.swift` に `MuscleGroup.weeklySetTarget(for:)`（個人化スケーリング）
- `Analytics.weeklySetCountReport` に `profile` 引数
- 新 `Coaching/ProgressiveOverload.swift`（`progressiveOverloadAdvice`）
- `Analytics.combinedCoachingAdvice` に `profile` 引数 + 漸進性過負荷統合
- 設定タブ「環境」に経験・目標 Picker、分析タブ「部位別」と Home でプロファイルを読み渡す配線
- ユニットテスト

### 2.2 含まない（Out of Scope）
- オンボーディングでのプロファイル取得（任意・後回し。設定で取得できれば足りる）
- 端末間同期（UserDefaults のため無し。既存設定＝重量単位・週目標も同様）
- A3 体組成連動 → 別サブスペック

---

## 3. 現状（実装の事実確認）

- 設定はすべて **UserDefaults**（`WeeklyTrainingTarget` = `.standard`、`UnitPreference` = App Group）。**@Model 設定は存在しない**。iCloud KVS も無し。→ プロファイルも UserDefaults が自然（コーチングの純粋関数入力にしやすい）。
- `WeightUnit`（String rawValue / Codable / CaseIterable / Sendable + displayName）が enum-as-setting の雛形。`ExperienceLevel`/`TrainingGoal` も同形。
- 目標値の**単一生成点**は `MuscleGroup.weeklySetTarget`（`MuscleVolumeTargets.swift:25-42`、固定 switch）。`WeeklySetTarget{mev,mav,isTracked}` が producer→`MuscleSetCountRow.target`→View と流れる**唯一の注入シーム**。
- `Analytics.weeklySetCountReport` が `muscle.weeklySetTarget` を読んで行に詰める（`Analytics.swift:128,131`）。`MuscleSetCountRow.status`（`:732-736`）は `count` vs `target.mev/.mav` の**純粋関数**。
- `MuscleGroupAnalysisSection` は `row.target.mev/.mav`/`row.status` のみ消費（`weeklySetTarget` を直接呼ばない）→ **report に profile を足せば View 変更ほぼ不要で個人化**。
- `MuscleRecovery.report` は `.weeklySetTarget.isTracked` の**トラッキングゲートだけ**使用 → no-arg 版を温存すれば無影響。
- 漸進性過負荷の素材: `setCountByMuscleGroup(sets:in:)` × `lastWeekRange`/`currentWeekRange` で部位別週セット数が計算可能。「来週+N」処方ロジックのみ新規。
- 設定 UI: `SettingsTabView` の `preferenceSection`（"環境"）に既に Location/WeightUnit/WeeklyTarget の Picker が並ぶ → ここに経験・目標を追加。

---

## 4. 設計

### 4.1 プロファイル（UserDefaults・端末ローカル）

`Models/Enums.swift` に追加（`WeightUnit`/`Location` と同形）:
```
public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced     // displayName: 初心者/中級者/上級者
}
public enum TrainingGoal: String, Codable, CaseIterable, Sendable {
    case hypertrophy, strength, maintenance   // displayName: 筋肥大/筋力/維持
}
```

新 `Coaching/TrainingProfile.swift`:
```
public struct TrainingProfile: Sendable, Hashable {
    public let experience: ExperienceLevel
    public let goal: TrainingGoal
    public static let `default` = TrainingProfile(experience: .intermediate, goal: .hypertrophy)
}

/// WeeklyTrainingTarget と同パターンの UserDefaults アクセサ。
public enum TrainingProfilePreference {
    public static let experienceKey = "OikomiExperienceLevel"
    public static let goalKey = "OikomiTrainingGoal"
    public static func current(defaults: UserDefaults = .standard) -> TrainingProfile {
        let exp = defaults.string(forKey: experienceKey).flatMap(ExperienceLevel.init(rawValue:))
            ?? TrainingProfile.default.experience
        let goal = defaults.string(forKey: goalKey).flatMap(TrainingGoal.init(rawValue:))
            ?? TrainingProfile.default.goal
        return TrainingProfile(experience: exp, goal: goal)
    }
}
```
保存先は `UserDefaults.standard`（iPhone のコーチングを駆動するだけなので per-device で十分。Watch/Widget 不要）。

### 4.2 個人化 MEV/MAV（注入点1か所）

`MuscleVolumeTargets.swift` に追加（既存 no-arg `weeklySetTarget` は**ベースライン=中級者+筋肥大として温存**）:
```
extension MuscleGroup {
    public func weeklySetTarget(for profile: TrainingProfile) -> WeeklySetTarget {
        let base = weeklySetTarget  // 既存固定値（中級+筋肥大相当）
        let (eMev, eMav) = profile.experience.volumeFactors
        let (gMev, gMav) = profile.goal.volumeFactors
        let mev = Int((Double(base.mev) * eMev * gMev).rounded())
        var mav = Int((Double(base.mav) * eMav * gMav).rounded())
        mav = max(mev, mav)  // mev<=mav 不変条件を保証
        return WeeklySetTarget(mev: mev, mav: mav)
    }
}
```
スケーリング係数（暫定・テストで調整）:
| 経験 | (mev係数, mav係数) | 目標 | (mev係数, mav係数) |
|---|---|---|---|
| beginner | (0.85, 0.70) | hypertrophy | (1.0, 1.0) |
| intermediate | (1.0, 1.0) | strength | (0.85, 0.80) |
| advanced | (1.0, 1.20) | maintenance | (0.85, 0.70) |

- **既定(中級+筋肥大) = 係数すべて 1.0 → ベースライン完全一致**（既存挙動・テスト不変）。
- 初心者<中級<上級でMAV上昇、筋力<筋肥大、維持はMEV寄り。`fullBody`(0,0) は係数を掛けても (0,0)。`abs`(mev0) は mev'0。
- 係数は `ExperienceLevel.volumeFactors` / `TrainingGoal.volumeFactors`（`(Double, Double)` を返す）として enum 拡張に定義。

### 4.3 weeklySetCountReport を個人化

`Analytics.weeklySetCountReport` に `profile: TrainingProfile = .default` を追加し、内部の `muscle.weeklySetTarget` を `muscle.weeklySetTarget(for: profile)` に変更。`guard target.isTracked` の判定も個人化目標で行う（係数 ≤ 1.2 なので tracked 状態は変わらない＝fullBody 以外は tracked 維持）。
- 既存呼び出し（profile 省略）は `.default` → ベースライン → **既存テスト無変更**。
- `MuscleSetCountRow.status` は行の target を読むため、個人化目標で自動的に 不足/適正/過多 が変わる。

### 4.4 漸進性過負荷アドバイス（標準・最大2件）

新 `Coaching/ProgressiveOverload.swift`:
```
public enum ProgressiveOverload {
    public static func progressiveOverloadAdvice(
        sets: [SetRecord], profile: TrainingProfile = .default,
        referenceDate: Date = Date(), calendar: Calendar = .current
    ) -> [CoachingAdvice]
}
```
- 今週の部位別セット数 = `Analytics.setCountByMuscleGroup(sets:, in: Analytics.currentWeekRange(...))`。各 tracked 筋群で個人化目標 `muscle.weeklySetTarget(for: profile)` と比較。
- **集約して最大2件**:
  1. **MEV未満**の筋群（不足）が1つ以上 → `severity .warning` 1件。例「胸・肩 が今週 MEV 未満です。来週は各 +1〜2 セット増やしましょう。」（最大4部位 + "など"）。`impact` は warning 帯（例 `1000 + 不足部位数×100`）。
  2. **MEV〜MAV で MAV に未到達**の筋群（漸進候補）が1つ以上 → `severity .info` 1件。例「背中・脚 は来週 +1〜2 セットで MAV に向けて漸進できます。」（最大4部位 + "など"）。`impact` info 帯（例 `120 + 候補数×10`）。
- **MAV以上は新アドバイスを出さない**（部位別チップの「過多」＋ `deloadAdvice`/`volumeAdvice` が担当）。対象ゼロの状態は該当アドバイスを省略（両方ゼロなら空配列）。
- **列挙順（決定的）**: 不足は「不足幅 `mev-count` の大きい順」、漸進候補は「MAV までの余地 `mav-count` の大きい順」。いずれもタイブレークは `muscle.rawValue` 昇順。

`Analytics.combinedCoachingAdvice` に `profile: TrainingProfile = .default` を追加し、統合リストに `ProgressiveOverload.progressiveOverloadAdvice(sets:profile:referenceDate:calendar:)` を足す（warning優先→impact 降順→`prefix(limit)` にそのまま乗る）。既存呼び出し（profile 省略）は default。

### 4.5 露出

- **設定タブ「環境」**（`SettingsTabView.preferenceSection`）: `@AppStorage(TrainingProfilePreference.experienceKey)` / `goalKey` を追加し、WeeklyTarget Picker の後に経験・目標 Picker を2つ（`ForEach(Enum.allCases, id: \.rawValue)` + `Label(systemImage:)`）。`.standard` ストア（store 指定なし）。
- **分析タブ「部位別」**（`MuscleGroupAnalysisSection`）: `@AppStorage` で経験/目標を読み `TrainingProfile` を組み、`Analytics.weeklySetCountReport(sets: sets, profile: profile)` に渡す。バー/チップは自動個人化（View構造不変）。
- **Home/全件コーチング**（`HomeView`）: 同様にプロファイルを読み、`Analytics.combinedCoachingAdvice(... profile: profile)` に渡す。漸進性過負荷提案が既存パイプラインに流れる。

---

## 5. データフロー

1. ユーザーが設定で経験・目標を選択 → UserDefaults に保存。
2. 分析タブ「部位別」表示 → プロファイルを読み `weeklySetCountReport(sets:profile:)` → 個人化 MEV/MAV バー・過不足チップ。
3. Home 表示 → プロファイルを読み `combinedCoachingAdvice(... profile:)` → `progressiveOverloadAdvice` が統合リストに合流 → コーチングチップ/全件画面。
4. ゲーティング: 部位別は既存 `ProGate.canSeeAdvancedAnalytics`、コーチングは `canUseAICoaching`（純粋データなので追加ゲート不要）。プロファイル設定 UI 自体はゲートしない（Free でも選べる。効果は Pro 機能に出る）。

---

## 6. テスト（TDD・OikomiKit）

- **TrainingProfile / Preference**: `.default`、UserDefaults 往復（書く→`current` で読む）、未設定キーで default フォールバック。
- **`weeklySetTarget(for:)`**: 既定(中級+筋肥大)==ベースライン（全筋群）、初心者MAV<中級MAV<上級MAV（同筋群）、筋力MAV<筋肥大MAV、`mev<=mav` 不変、`fullBody`==(0,0)、`abs` mev 0 維持。
- **`weeklySetCountReport(profile:)`**: 上級で同じ count が 過多→適正 になる等、個人化が status に反映。profile 省略でベースライン。
- **`progressiveOverloadAdvice`**: MEV未満→warning（部位列挙）、MEV〜MAV→info（漸進）、MAV以上のみ→空、両ゼロ→空、最大4列挙+など。
- **`combinedCoachingAdvice(profile:)`**: 漸進性過負荷が統合される。既存 combined テストは profile 省略で不変。

---

## 7. エッジケース / リスク

- **既定の後方互換**: 既定プロファイルがベースラインに一致するよう係数を 1.0 に設計 → 既存テスト・既存挙動（profile 未指定の呼び出し）が壊れない。これが最重要不変条件。
- **丸めと不変条件**: 係数適用後に `mav = max(mev, mav)` で `mev<=mav` を必ず保証。`fullBody`/`abs` の 0 起点は 0 維持。
- **isTracked の安定**: 係数 ≥ 0.7 なので tracked 筋群（mav>0）が untracked 化することはない（fullBody のみ untracked のまま）。
- **アドバイスのスパム**: 13筋群×3状態を出すと氾濫するため、不足/漸進の2カテゴリに集約し各最大4部位列挙。`combinedCoachingAdvice` の `prefix(limit)` でさらに制限。
- **`volumeAdvice` との重複感**: 前週比 vs 目標連動で観点が異なるが、両方出ると冗長に見える可能性。warning 優先ソート＋prefix(3) で実害は限定的。将来 volumeAdvice と統合検討（今回は別出し）。
- **スケーリング係数の妥当性**: 文献ベースの初期値。テストは「相対挙動（上級>中級>初心者、既定==ベースライン）」を主に検証し絶対値は緩く。

---

## 8. 後続への申し送り
- オンボーディングでのプロファイル取得（既存 `OnboardingView` に1ステップ追加）。
- A4 リカバリー × C2 目標頻度の統合（部位別の目標トレ頻度）。
- `volumeAdvice` と `progressiveOverloadAdvice` の将来統合（前週比＋目標連動を1本化）。
- A3 体組成連動（増量/減量フェーズで目標を自動シフト）。

## 9. 完了の定義
- 上記 enum・プロファイル・個人化関数・漸進アドバイス・設定UI・配線が実装され、TDD テスト全成功（既存 + 新規）。
- `/build` iOS ビルド成功、`/format`・`/lint` 準拠。
- 設定で経験/目標を変えると部位別 MEV/MAV バーと過不足チップが変化し、`combinedCoachingAdvice` に漸進性過負荷提案が混ざる。
- 既定プロファイルで既存挙動が完全維持される。

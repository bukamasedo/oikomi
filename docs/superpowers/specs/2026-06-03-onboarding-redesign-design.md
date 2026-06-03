# オンボーディング再設計 — 設計ドキュメント

- 日付: 2026-06-03
- 対象: `App/iOS/Views/OnboardingView.swift`
- 関連: `SettingsTabView`（環境セクション）、`OikomiKit` Preferences/Coaching アクセサ

## 背景と課題

現在のオンボーディングは **6 ステップ**（ようこそ → ヘルスケア → 通知 → ルーティン説明 → 重量単位 → Pro）。
2 つの問題がある:

1. **環境設定を初日から拾えていない** — コーチング（MEV/MAV 個人化・ボリューム警告・週次リング）の入力となる
   経験レベル・トレーニング目標・週次トレ目標・場所を、オンボーディングで一切聞いていない。
   設定タブには存在するが、ユーザーが能動的に開かない限りデフォルトのまま。
2. **長すぎてストレス** — 6 画面のうち「ルーティン説明」は入力のない説明だけ、ヘルスケアと通知は別々の
   権限画面で 2 タップ分のステップを消費している。

## ゴール

- オンボーディング中に **経験レベル / トレーニング目標 / 週次トレ目標 / トレーニング場所 / 重量単位** を設定できる。
- それでいて **画面数を 6 → 4 に減らす**。設定項目は増えるのに体感は短くする。
- すべて既存の設定キーに保存し、**設定タブと完全に一致**させる（二重管理しない）。

## 新フロー（6 → 4 ステップ）

| # | ステップ | 内容 | 旧との対応 |
|---|---------|------|-----------|
| 0 | **ようこそ** | 価値訴求（既存のまま） | 維持 |
| 1 | **あなたについて**（新規・統合） | 経験レベル / 目標 / 週目標 / 場所 / 重量単位 を 1 画面で | 設定 4 項目を新規追加 ＋ 旧「重量単位」単独ステップを吸収 |
| 2 | **連携**（統合） | HealthKit と 通知 の許可を 1 画面に集約 | 旧「ヘルスケア連携」＋「通知でサポート」を統合 |
| 3 | **Pro** | サブスク案内（既存のまま） | 維持 |

**削除**: 「ルーティン説明」ステップ（入力なし。ホーム/トレーニングタブで自然に発見できる）、
「重量単位」単独ステップ（あなたについて画面へ吸収）。

`Step` enum を更新:

```swift
enum Step: Int, CaseIterable {
    case welcome      // 0
    case profile      // 1  (新規)
    case integrations // 2  (旧 healthKit + notifications 統合)
    case pro          // 3
}
```

`OnboardingStepIndicator` は `Step.allCases.count` を参照しているため、ドット数は自動で 4 に追従する。
各ステップの `OnboardingStepIndicator(current:)` の引数を 0/1/2/3 に振り直す。

## ステップ 1: 「あなたについて」（ProfileStep）

### 目的とストレス低減の鍵

5 項目を **すべてデフォルト選択済み** で表示し、こだわらないユーザーは何も触らず「次へ」で通過できる。
密度は上がるが、各項目は単純なセグメント選択で、1 スワイプ分に収まる。

### 入力項目と保存先（既存キーを再利用）

| 表示ラベル | 型 | 保存キー | デフォルト | UI |
|-----------|-----|---------|----------|-----|
| 経験レベル | `ExperienceLevel` | `TrainingProfilePreference.experienceKey` (`OikomiExperienceLevel`) | `.intermediate`（中級者） | セグメント 3 |
| 目標 | `TrainingGoal` | `TrainingProfilePreference.goalKey` (`OikomiTrainingGoal`) | `.hypertrophy`（筋肥大） | セグメント 3 |
| 週のトレーニング日数 | `Int` | `WeeklyTrainingTarget.storageKey` (`OikomiWeeklyTargetDays`) | `4` | セグメント 1〜7 |
| 場所 | `Location` | `OikomiPreferredLocation` | `.gym`（ジム） | セグメント 2（ジム/自宅） |
| 重量の単位 | `WeightUnit` | `UnitPreference`（App Group suite） | `.kg` | セグメント 2（kg/lb） |

### 永続化方針

- **経験 / 目標 / 週目標 / 場所** は `@AppStorage`（`.standard`）でセグメントに直接バインドし、変更を即時保存する。
  SettingsTabView の環境セクションと**同一のキー・同一の `@AppStorage` パターン**を使う（実装の一貫性）。
  ユーザーが触らなければキーは未書き込みのまま → 読み手は同じデフォルトにフォールバックするので挙動は不変。
- **重量単位** だけは App Group suite に保存する必要があるため `@AppStorage` の `.standard` ではなく、
  `@State selected: WeightUnit = UnitPreference.current()` を保持し、「次へ」押下時に `UnitPreference.set(selected)` で書き込む。
  あわせて、設定タブと同じく `WCSyncBridge.shared.sendUnitPreferenceUpdate(selected)` で Watch に同期する
  （旧 `WeightUnitStep` は同期していなかったが、設定タブとの整合のためここで揃える）。

### レイアウト

- 縦に長くなりすぎないよう、ヒーローアイコンは小さめ（または省略）にし、見出し「あなたについて」＋
  サブテキスト「あとで設定でいつでも変更できます」を上部に置く。
- 5 つのセグメント行を縦に並べる。小型デバイス（iPhone SE 等）で全項目＋ボタンが収まらない可能性に備え、
  コンテンツを `ScrollView` に入れ、最下部の「次へ」は固定表示にする。
- 既存の `OikomiSpacing` / `OikomiColor` / カードスタイルに準拠する。

### 画面イメージ

```
┌──────────────────────────────┐
│           ・―・ ・            │  ← StepIndicator (current: 1)
│        あなたについて          │
│  あとで設定でいつでも変更できます    │
│                              │
│  経験レベル                    │
│  [ 初心者 ][●中級者●][ 上級者 ]  │
│  目標                         │
│  [●筋肥大●][ 筋力 ][ 維持 ]     │
│  週のトレーニング日数            │
│  [1][2][3][●4●][5][6][7]      │
│  場所         重量の単位        │
│  [●ジム●][自宅] [●kg●][lb]    │
│                              │
│            [ 次へ ]            │
└──────────────────────────────┘
```

## ステップ 2: 「連携」（IntegrationsStep）

### 目的

HealthKit と 通知 の 2 つの権限リクエストを 1 画面に統合し、ステップを 1 つ削減する。
どちらも任意（スキップ可能）で、「次へ」を押せば許可状況に関わらず先へ進める。

### 構成

- 見出し「連携」＋ サブテキスト（ヘルスケア・通知の役割を 1〜2 文で）。
- **HealthKit 行**: 説明（ワークアウト保存＋HRV/睡眠でコーチング、計算はオンデバイス完結）と
  インライン「許可」ボタン。許可後は「許可済み ✓」表示に変わる（`healthAuthorizationDone` を流用）。
  アクションは既存 `HealthStore.shared.requestWorkoutWriteAuthorization()`（拒否されても続行）。
- **通知 行**: 説明（レスト終了・PR 予測・終了し忘れリマインド）とインライン「許可」ボタン。
  許可後は「許可済み ✓」表示。アクションは既存 `RestTimerNotifier.requestAuthorization()`。
- 最下部に主ボタン「次へ」。許可の有無に関わらず `step = .pro` へ進む。
- キャプション「許可は後から『設定 → 連携・同期 / 通知』で変更できます」。

### 注記

- 2 つの権限を 1 画面に出すが、**システムダイアログは各ボタン押下時に個別に表示**する
  （1 ボタンで 2 ダイアログ連発はしない。ユーザーが各々の判断で許可できる）。
- 旧 `HealthKitStep` / `NotificationsStep` のコピー・ブレットは流用しつつ、1 画面に再構成する。

## ステップ 0「ようこそ」/ ステップ 3「Pro」

機能・コピーともに現状維持。`OnboardingStepIndicator(current:)` の引数のみ新インデックス（0 / 3）へ更新。
Pro ステップの `finish()`（完了フラグ書き込み・`NotificationCoordinator.bootstrap()`）はそのまま。

## 永続化・互換性

- 完了フラグ `OnboardingState.completedKey`（`OikomiOnboardingCompleted_v1`）は**変更しない**。
  既存ユーザーは再表示されない（意図通り）。設定タブの「オンボーディングを再表示」から手動で新フローを確認できる。
- 環境設定はいずれも既存キーに保存するため、設定タブと双方向に一致する（オンボーディングで選んだ値が
  設定タブにそのまま反映され、その逆も成立）。

## 削除・変更するコード（OnboardingView.swift）

- `Step` enum: `healthKit` / `notifications` / `routinePrompt` / `weightUnit` を削除し、
  `profile` / `integrations` を追加。
- `body` の `switch`: 4 ケースに再構成。
- `RoutinePromptStep`、`WeightUnitStep`、`WeightUnitChoiceCard` を削除。
- `HealthKitStep` / `NotificationsStep` を `IntegrationsStep` に統合（既存コピーを移植）。
- `ProfileStep` を新規追加。
- 共有コンポーネント（`OnboardingStepIndicator` / `OnboardingHeroIcon` / `OnboardingPrimaryButton` /
  `ValueRow` / `BulletPoint`）は再利用。

## テスト・検証

- ビジネスロジックの新規追加はなく、保存先はすべて既存のテスト済みアクセサ（`TrainingProfilePreference` /
  `WeeklyTrainingTarget` / `UnitPreference`）なので、OikomiKit のユニットテストは現状維持で通る想定。
- 手動確認（`OikomiOnboardingCompleted_v1` を未設定にした状態 or 設定の「再表示」）:
  1. 4 ステップで進行し、StepIndicator が 4 ドットになる。
  2. あなたについて画面で各項目を変更 → 設定タブの環境セクションに反映される。
  3. 何も触らず通過 → デフォルト（中級者 / 筋肥大 / 週4 / ジム / kg）が維持される。
  4. 連携画面で HealthKit・通知それぞれを許可/スキップでき、いずれでも Pro へ進める。
  5. Pro をスキップ/購入で完了し、再起動で再表示されない。

## 非ゴール（やらないこと）

- ルーティンの作成フローをオンボーディングに組み込むことはしない（説明ステップは削除のみ）。
- アプリアイコン選択・通知個別トグル・通知時刻などの細かい設定はオンボーディングに含めない
  （設定タブに残す。初日に必要な最小限のみ聞く）。
- 完了フラグのバージョンを上げて既存ユーザーへ再表示することはしない。

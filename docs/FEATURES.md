# Oikomi 機能一覧（実装ベース）

このドキュメントは、現在の実装に基づく **ユーザー向け機能カタログ** です。仕様の詳細・哲学は [`SPEC.md`](./SPEC.md) を参照してください。

- 対象 OS: iOS 26+ / watchOS 26+ / iPadOS 26+ / macOS 26+
- 課金: Pro 月額 ¥780 / 年額 ¥5,800（14 日トライアル）
- 一次デバイス: **Apple Watch**（記録・実行）／ iPhone は計画・分析

---

## 1. iPhone / iPad

5 タブ構成（`App/iOS/ContentView.swift`）。

### 1.1 ホーム（`HomeView.swift`）

- **進行中ワークアウトカード** — 開いていればタップでトレーニングタブへ
- **週次目標リング** — 今週の達成日数 / 目標日数（1–7 日設定可）と連続活動週数
- **今週のセッション数・総ボリューム** — 大型タイル表示
- **今日のコンディションカード** — HRV / 体重 / 睡眠（Pro + HealthKit）
- **AI コーチングチップ**（横スクロール、Pro 限定）
  - ボリューム超過 / 不足の警告
  - HRV 低下時のディロード推奨
  - PR 予測（「あと N kg で PR」）
- **直近 PR ハイライト** — トロフィー + 推定 1RM
- **今週のボリューム部位別チャート** — 上位 6 部位の横棒グラフ

### 1.2 トレーニング（`WorkoutTabView.swift`）

**開始前**
- **クイック開始** — ルーティンなしで即セッション
- **ルーティングリッド** — 保存済みルーティンを 2 カラム表示、タップで開始
- **新規ルーティン作成**（右上 ＋）

**進行中**
- Hero ヘッダー：経過時間タイマー + 完了 / 計画セット数
- 種目ごとのカード（重量 / レップ / チェックボックス、追加・削除・編集）
- セット完了で自動レストタイマー起動
- 種目追加カード（点線ボーダー）
- 終了ボタン（確認ダイアログ、Watch にも反映）

**セット入力 UX**（`AddSetSheet.swift`）
- 種目ピッカー（検索 + 部位フィルタ）
- 重量 / レップの ± ステッパー（長押し連続増減、前回比バッジ）
- レスト秒数の per-set カスタマイズ

### 1.3 履歴（`HistoryView.swift`）

- 期間セグメント — 日 / 週 / 月 / 年 / 全期間
- サマリーカード — セッション数 / セット数 / 総ボリューム
- **カレンダー UI** — 実績日ハイライト + 日付絞り込み
- セッション一覧（時刻 + ルーティン名 + セット数 + 実行時間）
- **セッション詳細 + 複製コピー** — 過去セッションをそのまま今日のメニューに

### 1.4 分析（`AnalysisTabView.swift`）

4 カテゴリの Segmented Picker。

- **推移** — 週次総ボリュームバー / 種目別最大重量ライン / PR 一覧（Pro でグラフ開放）
- **コンディション** — HRV / 安静時心拍 / 睡眠時間（Pro + HealthKit）
- **ボディ** — 体重 / 体脂肪率 / 除脂肪体重（Pro + HealthKit）
- **部位別** — 週セット数・ボリューム横棒。MEV / MAV ターゲットに対する「不足 / 最適 / 過剰」判定（Pro）

### 1.5 設定（`SettingsTabView.swift`）

- **Pro Hero Row** — タップで Pro Upgrade Sheet
- **環境設定** — トレーニング場所（ジム / 自宅）／ 重量単位（kg / lb、Watch 即時同期）／ 週次目標日数（1–7）／ アプリアイコン切替（Barbell / Protein / Dumbbell）
- **通知設定** — 各種トグル + 時刻プリセット（朝 7:00 / 12:00 / 19:00）
- **iCloud 同期トグル**（Pro）
- **HealthKit 詳細画面** — 状態確認 + 権限再要求
- **データ** — オンボーディング再表示 / CSV エクスポート（Pro、ShareLink）/ 全データ削除
- **情報** — 用語解説 / バージョン

**Pro Upgrade Sheet** — 14 日無料トライアル誘導、月 / 年プラン選択、復元、規約 / プライバシーリンク。

### 1.6 オンボーディング（`OnboardingView.swift`）

6 ステップ：Welcome → HealthKit → 通知 → ルーティン作成促し → 重量単位 → Pro 紹介。

### 1.7 ルーティン管理（`RoutineEditorView.swift`）

- 名前 / 予定曜日（複数選択）
- 種目追加（ピッカー）→ 重量・レップ・セット数入力
- ドラッグ並べ替え

### 1.8 種目ライブラリ（`ExercisePickerSheet.swift`）

- 873 種シード（日本語 + 英語名検索）
- 部位フィルタ / お気に入り上部固定
- **種目詳細** — 推定 1RM・総セッション数・最大重量推移グラフ（Pro）・直近セット履歴 / デフォルトレスト秒数カスタマイズ
- **カスタム種目追加**（Free: 5 個 / Pro: 無制限）

### 1.9 macOS（Catalyst, `App/Mac/`）

NavigationSplitView のプレースホルダ実装。本格対応は v2.0 以降。

---

## 2. Apple Watch（`App/Watch/`）

**実行専用デバイス**。iPhone で作成済みのルーティンを Apple Watch スタンドアロンで実行・記録する設計（watchOS standalone app）。計画系操作（ルーティン作成・種目追加）は iPhone 専任。

### 2.1 ホーム（`WatchHomeView.swift`）

- ルーティン一覧（最終使用日順）
- 各ルーティンの種目数表示
- タップで即セッション開始
- 計画 / 編集は iPhone 専任、Watch は **実行専念**

### 2.2 セッション実行（`WatchActiveSessionView.swift`）

- セッション経過時間（タイマー）
- 完了 / 総セット数の進捗
- 種目セクション化されたセット行
- セット行タップで完了 ⇄ 未完了切替
- 終了ボタン（確認ダイアログ）

### 2.3 レストタイマー（`WatchRestTimerView.swift`）

- 進捗リング（TimelineView でなめらか更新）
- カウントダウン（OS 秒同期）
- スキップ → 「閉じる」へ確定的に切替
- 0 到達時にハプティクス通知

### 2.4 HKWorkoutSession 統合（`WatchHealthSession.swift`）

- セッション開始で `HKWorkoutSession(.traditionalStrengthTraining, .indoor)` 起動
- 活動リング貢献 + Workout Buddy と共存
- 終了順序を厳密化（ローカル保存 → WC 送信 → Live Activity 終了 → HK セッション終了）

### 2.5 同期

- 起動時に iPhone へ `requestFullSync()` でルーティン + 進行中セッション一括取得
- レストタイマー状態、単位設定（kg/lb）、ルーティン追加・削除、アイコン変更を双方向リアルタイム同期
- リーチャビリティ復旧時に自動フル同期

---

## 3. ウィジェット

### 3.1 iOS（`OikomiWidgets`）

`StatsWidget`：

| ファミリー | 内容 |
|---|---|
| systemSmall | 今週達成日数（リング）+ 連続週数 |
| systemMedium | セッション数 + ボリューム + 直近 PR + HRV |
| accessoryCircular（Lock Screen） | リング + 日数 / 目標 |
| accessoryRectangular | 「今週 X/Y 日」+ 連続週数 / セッション数 / PR |
| accessoryInline | 1 行テキスト |

HRV は Pro でのみ表示、Free は "HRV Pro" プレースホルダ。

### 3.2 watchOS（`OikomiWatchWidgets`）

文字盤・Smart Stack の `accessoryCircular / Rectangular / Inline / Corner` 4 ファミリー対応。

---

## 4. Live Activity / Dynamic Island

`WorkoutLiveActivityWidget.swift`：

- **Lock Screen** — ルーティン名 + 経過時間 + セット数
- **Dynamic Island**
  - 展開：種目名 / タイマー / セット数 / レスト残時間
  - コンパクト：セット数 or レスト残秒
  - ミニマル：アイコン
- **Apple Watch Smart Stack** — `@Environment(\.activityFamily)` で Watch 用にも適応
- iOS / Watch のレスト状態を `WorkoutActivityController` 経由で同期更新
- 現状 **Free 開放**（v0.x 戦略：差別化は HRV × AI コーチングへ）

---

## 5. Siri / Shortcuts / App Intents

`LogSetIntent.swift`：

- **「セットを記録」** インテント — 種目名 / 重量 / レップ数を音声で
- Siri / Shortcuts / Spotlight から呼び出し可
- 種目検索：完全一致 → 前方一致 → 部分一致（日英両対応）
- 進行中セッションなければ自動開始、`openAppWhenRun = false` でバックグラウンド記録
- 例：「Oikomi に記録、ベンチプレス 80 kg 8 レップ」

---

## 6. 通知

`NotificationCoordinator` 統括：

| 通知 | 内容 | ゲート |
|---|---|---|
| レストタイマー終了 | セット完了後のレスト終了通知 + ハプティクス | Free |
| 週次サマリ | 日曜のプリセット時刻にセッション数・ボリューム等 | Free |
| 忘却セッション | 進行中セッション放置のリマインド | Free |
| トライアル残日数 | 期限切れ前の通知 | – |
| PR 予測 | 翌日のルーティン × PR 圏内種目を朝に通知 | **Pro** |
| HRV 連動ディロード | HRV 低下検知で強度緩和を提案 | **Pro** |

iOS 側で BGTaskScheduler (`com.shuhirouchi.oikomi.coaching.refresh`) によりバックグラウンド再スケジュール。

---

## 7. HealthKit 連携（`HealthStore.swift`）

- **書き込み**（Free）: 完了セッションを `HKWorkout`（traditionalStrengthTraining）として保存。活動リングに反映
- **読み取り**（**Pro**）: HRV (SDNN) / 安静時心拍数 / 睡眠 / 体重 / 体脂肪率 / 除脂肪体重
- セッション開始時に `HealthSnapshot` をキャッシュし、AI コーチングへ供給

---

## 8. iCloud / CloudKit 同期

- コンテナ：`iCloud.com.shuhirouchi.oikomi`
- SwiftData の CloudKit-compatible スキーマで多デバイス同期
- **Pro 限定**（`ProGate.canUseICloudSync`）
- watchOS は CloudKit を直接使わず、WatchConnectivity 経由で iPhone と同期

---

## 9. データ・記録モデル（コアロジック層）

`Packages/OikomiKit/Sources/OikomiKit/` に集約。UI からは Repository 経由。

- **Exercise** — 種目（部位 / 装具 / 測定タイプ / デフォルトレスト / お気に入り）
- **WorkoutSession** — セッション（開始 / 終了時刻 / メモ / HKWorkout UUID）
- **SetRecord** — セット（重量 / レップ / RPE / ウォームアップ / 推定 1RM / レスト秒数 / 完了フラグ）
- **Routine + RoutineExercise** — メニュー（曜日スケジュール / 種目順 / 想定セット）
- **PersonalRecord** — 種目別 PR（重量 / レップ / 推定 1RM / 達成日）
- **HealthSnapshot** — セッション開始時の HRV / 睡眠 / 安静時心拍

### コーチングエンジン（`Coaching/`）

- **1RM 推定** — Epley / Brzycki 式、`relativeIntensity()` で %1RM
- **MuscleVolumeTargets** — 部位別 MEV / MAV テーブル
- **WeeklyTrainingTarget** — 目標トレーニング日数（1–7）
- **Analytics** — 週セット数 / ボリューム集計、連続週数、線形回帰による PR 予測、ディロード判定、HRV ベース緩和提案

### 種目ライブラリ（`SeedData.swift`）

- 873 種（free-exercise-db ベース、日本語 + 英語名）
- 旧 120 種からの自動マイグレーション、新種目追加時はユーザーに自動反映（カスタム種目は温存）

---

## 10. Free / Pro 機能境界

| カテゴリ | Free | Pro |
|---|---|---|
| 基本記録 | ✅ | ✅ |
| 履歴・カレンダー | ✅ 無制限 | ✅ |
| Apple Watch でのセッション実行・記録 | ✅ | ✅ |
| HealthKit 書き込み（HKWorkout） | ✅ | ✅ |
| Live Activity / Dynamic Island | ✅ | ✅ |
| ウィジェット / Smart Stack | ✅ | ✅ |
| Siri / Shortcuts | ✅ | ✅ |
| ルーティン | 5 個 | 無制限 |
| カスタム種目 | 5 個 | 無制限 |
| HealthKit 読み取り（HRV / 睡眠 / 体組成） | – | ✅ |
| AI コーチング（ディロード / PR 予測 / ボリューム警告） | – | ✅ |
| 高度な分析グラフ（推移 / 部位別 / 体組成） | – | ✅ |
| iCloud / CloudKit 同期 | – | ✅ |
| CSV データエクスポート | – | ✅ |

価格：月額 ¥780 / 年額 ¥5,800（14 日トライアル）／ Subscription Group: `Oikomi Pro`（プラン間アップグレード可）

---

## 11. 意図的に **作っていない** 機能

戒めとして（仕様書 §5.4 / Tier 5）：

- ソーシャル / フィード / コミュニティ機能
- フォーム動画指導
- パーソナルコーチとのチャット
- 完全初心者向けチュートリアル動画
- 食事手入力 UI（HealthKit 経由のみ）
- Android 版
- Firebase / RevenueCat / Supabase 等の外部 SaaS 依存
- 外部 LLM API（オンデバイス Foundation Models のみ）

---

## 参考

- 仕様書：[`docs/SPEC.md`](./SPEC.md)
- 公開ページ：[`docs/index.md`](./index.md)
- マーケティング素材：[`docs/marketing/`](./marketing/)
- 法務（プライバシー等）：[`docs/legal/`](./legal/)

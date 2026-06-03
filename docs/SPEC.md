# 筋トレメモアプリ「Oikomi」仕様書

> 本ドキュメントはアプリの公式仕様書です。実装中に方針が揺らいだ際の判断基準として、また AI コーディングハーネスのコンテキストとして利用します。
> 仕様の変更が必要になった場合は、コード変更より先にこのファイルを更新してください。

## 目次

1. [概要](#1-概要)
2. [ターゲット](#2-ターゲット)
3. [差別化ポイント](#3-差別化ポイント)
4. [主要機能](#4-主要機能)
5. [技術スタック](#5-技術スタック)
6. [データモデル](#6-データモデル)
7. [画面構成](#7-画面構成)
8. [MVP 範囲（v1.0）](#8-mvp-範囲v10)
9. [リリース後ロードマップ](#9-リリース後ロードマップ)
10. [収益モデル](#10-収益モデル)
11. [想定リスク](#11-想定リスク)

---

## 1. 概要

Apple エコシステムにフル特化した筋トレ記録アプリ。HealthKit / Live Activity / Apple Intelligence を統合し、**「iPhone で組み立て、Apple Watch で追い込む、ヘルスデータと連動した筋トレ記録」** を提供する。役割分担: iPhone でルーティンと種目を計画し、ジムでは Apple Watch をスタンドアロン記録デバイスとして使う。

- プロダクト名: **Oikomi**（追い込み）
  - App Store 表記: **Oikomi - 筋トレ記録 & Apple Watch**
- 対応 OS: iOS 26+ / watchOS 26+（iPhone 専用）
- 提供形態: Freemium（広告なし）+ サブスクリプション
  - Pro 月額: ¥780
  - Pro 年額: ¥5,800（実質 ¥483/月）
  - 14日間無料トライアル
  - 買い切りプランなし

---

## 2. ターゲット

### 地域戦略
日本市場特化でローンチ。v2.0 以降に英語 UI を整備しグローバル展開を検討。

### メインペルソナ：「Apple 信者のシリアストレーニー」

- 25〜40代、男性 60% / 女性 40%
- 会社員・自営業（IT・専門職多め）、年収 500〜1,000万円
- 週3〜5回トレーニング（ジム中心、自宅トレも併用）
- トレーニング歴 1年以上、目的はボディメイク・PR 更新
- iPhone + Apple Watch Series 9 以上を所有
- 既存アプリ（Hevy / Strong / 筋トレ Memo）に不満を持つ層
- 月額許容: ¥500〜¥1,500

### セカンダリペルソナ：「ヘルスデータ集約志向ユーザー」

- 30〜50代、男女問わず
- Apple 信者、Whoop / Oura 等も併用
- HealthKit へのデータ集約自体に価値を感じる

### トレーニング対象範囲

- **主軸**: ジムでのウェイト・マシントレーニング
- **サブ**: 自宅自重・ダンベル・チューブトレーニング
- 種目ライブラリ: v1.0 で 100種（ジム中心）→ v1.2 で 200種（自宅トレ追加）

### 除外ユーザー

- 完全初心者（フォーム動画指導が必要 → Nike Training Club 等）
- Android ユーザー
- 価格感度が極めて高い層

### 市場規模（概算）

- **SOM**: 約 50万人（日本の Apple Watch 筋トレ層、自宅トレ含む）
- **3年後目標**: 18,000 有料ユーザー / 年商 8,100万円（独立可能ライン）

---

## 3. 差別化ポイント

### コア訴求

> **「iPhone で組み立て、Apple Watch で追い込む、ヘルスデータ駆動の筋トレ記録」**

3つの体験価値：

1. **手首だけで実行** — iPhone で作成したルーティンを Apple Watch スタンドアロンで実行・記録（ジムで iPhone を取り出さない）。Live Activity / Dynamic Island で進行中表示
2. **賢い** — HRV・睡眠・生理周期と連動した負荷自動調整
3. **日本語ネイティブ** — UI・種目名・コーチング文言すべて自然な日本語

### 競合比較

| 観点 | Oikomi | Hevy | Strong | バーンフィット | 筋トレMemo |
|---|---|---|---|---|---|
| Apple Watch スタンドアロン | ◎ | ○ | ○ | △ | × |
| Live Activity / Dynamic Island | ◎ | × | × | × | × |
| HealthKit 双方向連携 | ◎ | △ | △ | △ | × |
| HRV/睡眠連動 AI コーチング | ◎ | × | × | × | × |
| 生理周期連携 | ○（v1.1） | × | × | × | × |
| 日本語 UI 品質 | ◎ | △（機械翻訳） | △ | ◎ | ◎ |
| 種目ライブラリ数 | ○ 200種 | ◎ 400種 | ◎ | ○ | ○ |
| ソーシャル機能 | × | ◎ | △ | △ | △ |
| 価格（年額） | ¥5,800 | ¥3,600 | ¥4,500 | ¥5,790 | 課金あり |

### 意図的に勝たない領域（戒め）

機能の選択と集中のため、以下は意図的に競合に勝たない設計とする。実装中に方針が揺らがないよう、仕様書に明記して戒めとする。

- **種目ライブラリの網羅性** — Hevy の 400種には追いつかなくて良い。上位 200種で十分。
- **ソーシャル機能** — Hevy のコミュニティとは戦わない。「孤独な追い込み」層を取る。
- **動画によるフォーム指導** — Apple Fitness+ / Nike Training Club の領域は侵さない。

### Apple 純正 Workout Buddy との関係

watchOS 26 で導入された Workout Buddy（Apple Intelligence による音声モチベーション）とは**共存関係**を取る。

| 役割 | Workout Buddy | Oikomi |
|---|---|---|
| ポジション | 励まし役 | コーチ役 |
| 対象運動 | カーディオ中心・一般ワークアウト | ウェイトトレーニング特化 |
| 主データ | 心拍・距離・リング | 重量・レップ・ボリューム・1RM |
| 課金 | 無料（watchOS 26 標準） | サブスク |

Workout Buddy 起動中も Oikomi の記録は並行動作する設計とする。ユーザーは Apple 純正の音声モチベーションを受けながら、Oikomi で詳細記録・長期分析を行える。

---

## 4. 主要機能

機能は重要度に応じた 5階層で整理する。Tier 5 は意図的に作らない機能を戒めとして明記する。

### Tier 1: コア体験（これがないと存在意義なし）

#### 4.1.1 高速入力 UX

1セットあたり **1〜3タップ**で完結する設計。Hevy（5〜8タップ）の倍速を実現する。

```
ステップ1: ルーティン開始
  → 前回履歴から「ベンチプレス 80kg 8レップ × 3セット」を自動表示

ステップ2: 1セット完了
  → Apple Watch で Double Tap or 画面タップ
  → そのままレストタイマー自動起動

ステップ3: 値が違う時だけ修正
  → Digital Crown で重量 ±2.5kg / レップを物理ダイヤル感覚で調整
```

実装ポイント：
- `WKInterfaceCrownSequencer` で Digital Crown 入力
- watchOS 26 の Double Tap ジェスチャでセット完了確定
- 前回履歴は CloudKit / SwiftData から即座にプリフィル

#### 4.1.2 履歴閲覧（無制限）

- カレンダー UI で過去全セッション閲覧可能
- 種目別履歴(重量・レップ推移)
- 前回セッションのコピー機能

#### 4.1.3 Apple Watch スタンドアロン記録

iPhone が手元になくても Watch 単体で全記録機能が動作。`HKWorkoutSession` でアクティビティリングに自動貢献。

#### 4.1.4 Live Activity / Dynamic Island

- ロック画面・Dynamic Island に現セット情報・レスト残り秒を常時表示
- StandBy モード対応（横置きでジム据え置きディスプレイ化）

---

### Tier 2: Apple 特化の差別化（Pro 主力）

#### 4.2.1 HealthKit 双方向連携

- 書き込み: `HKWorkout`, `bodyMass`, `bodyFatPercentage`, `leanBodyMass`
- 読み取り（Pro）: 心拍ゾーン、HRV、安静時心拍数、睡眠スコア、生理周期（v1.1）

#### 4.2.2 AI コーチング（オンデバイス数式・Pro 限定）

すべて `OikomiKit/Coaching` のオンデバイス純粋関数で算出する（外部 LLM 不使用）。v1.0 当初の3種（ディロード／PR予測／ボリューム警告）を、Pro 収益の核を強化するため**意図的に拡張**した。設計の一次ソースは [`docs/superpowers/specs/2026-05-30-coaching-readiness-autoregulation-design.md`](superpowers/specs/2026-05-30-coaching-readiness-autoregulation-design.md)。

| 提案タイプ | トリガー | 例 |
|---|---|---|
| ディロード／回復優先 | **コンディション総合スコア**（HRV を主軸に睡眠・安静時心拍を統合した 0-100 スコア。HRV は単純平均でなく**ローリングベースライン＋z-score**で判定）が低い、または連続トレ日数・週ボリューム比が過大 | "今日は回復優先。前回比80%程度で軽めに組みましょう" |
| RPE オートレギュレーション | 直近2セッションの平均 RPE が目標域から外れている（重すぎ／軽すぎ） | "ベンチは直近2回とも高強度でした。次回は 100→95kg を目安に" |
| PR 予測 | 直近セッションの最高推定1RM（**RIR補正**つき）の上昇トレンドを線形回帰 | "次回ベンチで PR 更新の可能性（推定 87.5kg ±2kg）" |
| 停滞検出 | 同種目の推定1RMがほぼ横ばい（傾き ≈ 0） | "ベンチが停滞ぎみ。レップ域・頻度・種目の変更を検討" |
| ボリューム警告 | 部位別の週間ボリュームが過剰/不足 | "今週の胸トレが先週比150%です。オーバーワーク注意" |

**PR 予測のセッション内導線（Pro）**: ルーティンで開始したセッション実行中、PR 予測が立っている種目には「セットを追加」ボタンの下に「重さを更新 → NNkg」ボタンを表示する。NN は予測推定 1RM を今回の予定レップ数へ逆算（`OneRepMax.workingWeight`）し単位刻みに丸めたワーキング重量。タップで当セッションの未完了（計画）セットの重量を一括更新する（ルーティン定義の `plannedWeight` は変更しない）。推奨値が現在の予定重量を上回る場合のみ表示。

**コンディション総合スコア**は信号が欠けても利用可能な信号だけで重みを再配分して算出し（`confidence` とデータソース注記を保持）、UI の「今日のコンディション」カードに 0-100 で表示する。

**動作機種・前提（重要）**: 上記コーチングは**すべてオンデバイス数式**であり、**Apple Intelligence 非対応機種でもフル機能で動作**する。Apple Intelligence（Foundation Models）が必要なのは v1.2 の自然言語サマリのみで、それは「対応機種で点灯するボーナス」。Pro の訴求は「Apple Intelligence」ではなく「**HealthKit 連動コーチング**」。**Apple Watch を使わない iPhone 単体ユーザー**でも RPE オートレギュレーション・PR予測・停滞検出・ボリューム警告はフル動作し、HRV/安静時心拍が取れない分はコンディションスコアが睡眠中心に graceful に縮退する（理由をカードに明示）。

#### 4.2.3 1RM 自動計算・推定強度（%1RM）表示

セット履歴から推定 1RM を自動算出し、各セットの相対強度を可視化。

#### 4.2.4 Workout Buddy 並行動作

watchOS 26 純正の Workout Buddy 起動中も Oikomi の記録セッションが並行動作。`HKWorkoutSession` を別途持つことで両立。

---

### Tier 3: 継続率を上げる機能

- **ルーティン管理**: 種目リスト・想定セット数を保存、ワンタップで開始
- **種目ライブラリ**: v1.0 で 100種（ジム中心）、部位・器具・場所タグで検索
- **インターバルタイマー**: レスト自動起動、種目ごとにデフォルト秒数設定
- **履歴コピー**: 前回セッションを丸ごとコピーして開始
- **App Intents / Siri**: 「ベンチプレス 80kg 8レップ記録」を音声入力
- **ウィジェット**: 小・中・大・ロック画面・StandBy 対応

---

### Tier 4: 拡張機能（v1.1 以降）

- **生理周期連携**（v1.1）: HealthKit の `menstrualFlow` を読んで負荷自動調整
- **自宅トレ種目追加**（v1.2）: 種目ライブラリを 200種に拡張、自重・チューブ・ダンベル対応
  - 種目データに `locations: [.gym, .home]` タグを持たせ、モード切替で表示制御
  - 自重種目は重量ではなく秒数/回数で記録
- **Apple Intelligence サマリ**（v1.2）: 月次振り返りを自然言語で自動生成
- **Core ML レップ自動カウント**（v1.3）: 手首 IMU からレップ数推定
- **Family Sharing**（v1.1）: 最大 6名でサブスク共有

---

### Tier 5: 意図的に作らない機能（戒め）

ブレないために仕様書に明記する。「機能要望が来ても作らない」リスト。

- **ソーシャル / フィード / コミュニティ機能** — Hevy の領域。「孤独な追い込み」層を取る
- **フォーム動画指導** — Apple Fitness+ / Nike Training Club の領域
- **パーソナルコーチとのチャット** — Hevy Coach の領域、B2B 拡張は v2.0 以降に検討
- **完全初心者向けのチュートリアル動画** — 中〜上級者向けに集中
- **食事の手入力管理** — HealthKit 経由のみ（独自の食事入力 UI は作らない）
- **Android 版** — Apple 特化が崩れるため対応しない

---

## 5. 技術スタック

Apple 純正で完結させる方針。サードパーティ依存を最小化し、月額固定費とプライバシーリスクを抑える。

### 5.1 採用技術

| レイヤー | 技術 | 採用理由 |
|---|---|---|
| UI | **SwiftUI** | 宣言的、watchOS / iOS で共通化 |
| ローカル DB | **SwiftData** | CloudKit と自動同期、Core Data 後継 |
| 同期 | **CloudKit** | 無料・iCloud アカウントのみで OK、サーバー運用不要 |
| ヘルスデータ | **HealthKit / WorkoutKit** | 双方向連携の標準 |
| ライブ表示 | **ActivityKit** | Live Activity / Dynamic Island |
| 音声・自動化 | **App Intents** | Siri / ショートカット / Spotlight 統合 |
| AI コーチング | **オンデバイス計算 + Foundation Models** | HRV / ボリュームは数式、自然言語は Apple Intelligence |
| ML（v1.3） | **Core ML + Create ML** | IMU レップ自動カウント |
| 課金 | **StoreKit 2** | Apple 標準、月額固定費を避ける |

### 5.2 開発・運用ツール

| 用途 | 技術 |
|---|---|
| バージョン管理 | Git + GitHub |
| CI/CD | Xcode Cloud（月25時間まで無料） |
| ベータ配信 | TestFlight |
| 分析 | App Store Connect Analytics + TelemetryDeck（プライバシー重視） |
| クラッシュレポート | Xcode Organizer（無料、Apple 純正） |
| カスタマーサポート | TestFlight Feedback + メール |

### 5.3 AI コーチングの実装方針

- **計算は全てオンデバイス**で完結。プライバシーを最大訴求ポイントとする
- HRV / ボリューム警告 / PR 予測は数式ベース（軽量、即応）
- v1.2 以降の自然言語サマリは **Foundation Models framework** を使用
- ユーザーデータを外部送信しない・モデル学習に使わない

### 5.4 意図的に採用しない技術（戒め）

サードパーティ依存と運用負荷を避けるため、以下は採用しない。

| 技術 | 不採用の理由 |
|---|---|
| Firebase | CloudKit で十分、Google エコシステム依存を避ける |
| RevenueCat | StoreKit 2 で十分、月額固定費を避ける |
| Supabase / Fly.io | サーバーレス（CloudKit のみ）で運用負荷ゼロを維持 |
| React Native / Flutter | Apple 特化が崩れる、ネイティブ性能を優先 |
| Sentry / Bugsnag | Xcode Organizer で十分 |
| サードパーティ広告 SDK | 広告なしの方針 |
| 外部 LLM API（OpenAI / Anthropic） | オンデバイス Apple Intelligence のみ使用 |

---

## 6. データモデル

### 6.1 概念モデル

```
User ───< WorkoutSession ───< SetRecord >─── Exercise
                  │                              │
                  │                      (locations, muscleGroups)
                  └─── HealthSnapshot

User ───< Routine ───< RoutineExercise >─── Exercise

User ───< PersonalRecord >─── Exercise
User ───< BodyMetric （HealthKit ミラー）
```

### 6.2 SwiftData 雛形

```swift
@Model
final class Exercise {
    var id: UUID
    var name: String                       // "ベンチプレス"
    var nameEn: String                     // "Bench Press"
    var muscleGroups: [MuscleGroup]        // [.chest, .triceps]
    var equipment: Equipment               // .barbell, .dumbbell, .bodyweight
    var locations: [Location]              // [.gym, .home]
    var measurementType: MeasurementType   // .weightReps, .bodyweightReps, .time
    var defaultRestSeconds: Int
    var isCustom: Bool
}

@Model
final class WorkoutSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var healthKitWorkoutUUID: UUID?        // HKWorkout との紐付け
    @Relationship(deleteRule: .cascade) var sets: [SetRecord]
    var notes: String?
    var healthSnapshot: HealthSnapshot?    // セッション開始時の状態
}

@Model
final class SetRecord {
    var id: UUID
    var exercise: Exercise
    var session: WorkoutSession
    var order: Int                         // セッション内の順序
    var weight: Double?                    // 自重種目は nil
    var reps: Int?                         // 時間計測種目は nil
    var durationSeconds: Int?              // プランク等
    var rpe: Double?                       // 主観的運動強度（1〜10）
    var isWarmup: Bool
    var estimated1RM: Double?              // 記録時点のスナップショット
    var restSeconds: Int?
    var completedAt: Date
}

@Model
final class Routine {
    var id: UUID
    var name: String
    var exercises: [RoutineExercise]       // 順序付き種目リスト
    var createdAt: Date
    var lastUsedAt: Date?
}

@Model
final class HealthSnapshot {
    var date: Date
    var hrvSDNN: Double?                   // ms
    var sleepScore: Int?                   // 0〜100
    var restingHeartRate: Int?
    var menstrualPhase: MenstrualPhase?    // v1.1
}

@Model
final class PersonalRecord {
    var id: UUID
    var exercise: Exercise
    var weight: Double
    var reps: Int
    var estimated1RM: Double
    var achievedAt: Date
}
```

### 6.3 CloudKit 互換の注意点

- すべてのプロパティをデフォルト値持ち or Optional にする（CloudKit 必須要件）
- enum は String / Int の `rawValue` で保存
- `@Attribute(.unique)` は CloudKit 同期と相性が悪いため使わない
- リレーションは `@Relationship` の `inverse` を明示する
- 画像・大容量データは CKAsset としてフィールド分離（v1.0 では未使用）

### 6.4 マイグレーション方針

- SwiftData の `VersionedSchema` を v1.0 から導入
- メジャーバージョン毎にスキーマを切り、`SchemaMigrationPlan` で段階移行
- 破壊的変更は v2.0 のような節目に限定
- マイグレーション失敗時は iCloud 上のスナップショットから復元する設計

### 6.5 HealthSnapshot の運用

- セッション開始時に HealthKit から HRV / 睡眠スコア / 安静時心拍数を取得しキャッシュ
- AI コーチングはこのスナップショットを参照（毎回 HealthKit を叩かない）
- 過去のスナップショットを蓄積することで、長期トレンド分析が可能

---

## 7. 画面構成

### 7.1 iPhone（5タブ構成）

| タブ | 画面 | 主な要素 |
|---|---|---|
| 🏠 ホーム | 今日の概要 | 今日のルーティン / 直近 PR / アクティビティリング / AI コーチング提案 |
| 💪 トレーニング | ワークアウト実行 | 種目リスト / セット記録 / Live Activity 連動 |
| 📅 履歴 | 過去セッション | カレンダー / セッション詳細 / 履歴コピー |
| 📊 分析 | グラフ・統計 | 種目別推移 / 部位別ボリューム / PR一覧 / 推定 1RM |
| ⚙️ 設定 | 各種設定 | HealthKit / 通知 / 課金 / ジム自宅モード切替 / アカウント |

### 7.2 Apple Watch

| 階層 | 画面 | 主な要素 |
|---|---|---|
| ルート | ホーム | 今日のルーティン開始 / 直近セッション |
| → | ワークアウト中 | 現セット / 次セット / レストタイマー / 心拍 |
| → | 種目選択 | クイック選択（履歴ベース） |
| → | セット入力 | Digital Crown で重量・レップ調整、Double Tap で確定 |
| Complication | 各種ウォッチフェイス | 次セット / レスト残り / 今日の進捗 |
| Smart Stack | 自動表示ウィジェット | トレーニング時間が近いと自動浮上 |

### 7.3 オンボーディング（4ステップ・各スキップ可）

ローカル利用前提でアカウント作成は不要（端末の Apple ID と iCloud を CloudKit が自動的に利用）。

1. **ウェルカム** — 3つの体験価値（手首完結 / 賢い / 日本語ネイティブ）を簡潔に紹介
2. **HealthKit 権限** — 読み書き範囲を説明して許可リクエスト
3. **Apple Watch ペアリング確認** — 未所持の場合はスキップ
4. **ルーティン作成** — プリセットから選ぶ or 後で

### 7.4 AI コーチング提案の表示場所

| 場所 | タイミング | 内容 |
|---|---|---|
| ホーム画面トップ | アプリ起動時 | 今日の推奨ボリューム / ディロード推奨 |
| ワークアウト開始前 | ルーティン開始タップ時 | 「今日は HRV が低いので軽めに」 |
| プッシュ通知 | PR 予測時・休息推奨時 | 「明日のベンチで PR 予測！」 |
| 月次サマリ画面 | 月初 | Apple Intelligence による振り返り（v1.2） |

### 7.5 課金導線（控えめ・体験ベース）

アグレッシブな全画面ポップアップは作らない。ソフトウォール中心で離脱を防ぐ。

- 設定タブ内に「Pro にアップグレード」セクション
- AI コーチング機能タップ時のソフトウォール（「Pro 機能です」表示）
- 分析画面で Pro 限定グラフをぼかし表示（プレビュー風）
- 月1回、控えめなホーム画面バナー（dismiss 可能）
- 14日間トライアル中は「残り◯日」を控えめにヘッダー表示

### 7.6 ナビゲーション構造

- **iPhone**: タブバー（5タブ）
- **Apple Watch**: フラットなナビゲーションスタック

> iPad / Mac 対応は v1.0 では行わない。将来検討する場合も別プロダクトとして再設計する想定。

---

## 8. MVP 範囲（v1.0）

### 8.1 v1.0 で含む機能

**Tier 1: コア体験（全て Free）**

- 高速入力 UX（B+C ハイブリッド、1〜3タップ）
- 履歴閲覧（無制限）
- Apple Watch スタンドアロン記録
- Live Activity / Dynamic Island
- 種目ライブラリ 100種（ジム中心）
- ルーティン管理（Free は 5つまで、Pro は無制限）
- インターバルタイマー

**Tier 2: Apple 特化（Pro 限定）**

- HealthKit 双方向連携（HRV / 睡眠の読み込みは Pro）
- AI コーチング 3種（ディロード / PR予測 / ボリューム警告）
- 1RM 自動計算・推定強度（%1RM）
- 高度な分析グラフ

**Tier 3: 継続率（Free / Pro 共通）**

- App Intents / Siri 入力
- ウィジェット（小・中・大・ロック画面・StandBy）
- Workout Buddy 並行動作

### 8.2 v1.0 で除外する機能

| 機能 | リリース予定 |
|---|---|
| 生理周期連携 | v1.1 |
| Family Sharing | v1.1 |
| 自宅トレ種目（計200種に拡張） | v1.2 |
| Apple Intelligence 自然言語サマリ | v1.2 |
| Core ML レップ自動カウント | v1.3 |
| SharePlay 共同セッション | v2.0 以降 |
| App Clips（ジム提携用） | v2.0 以降 |

### 8.3 Apple Watch MVP 範囲の定義

**Watch 単体でできること**

- ルーティン開始
- セット記録（重量・レップ・タイマー）
- 履歴閲覧（直近 5セッション）
- Complication / Smart Stack 表示

**Watch ではできないこと（iPhone 必須）**

- 種目ライブラリの追加・編集
- 詳細な分析グラフ閲覧
- 課金管理
- 設定変更

### 8.4 開発スケジュール（個人開発・1人想定、計 8ヶ月）

| フェーズ | 期間 | 内容 |
|---|---|---|
| 設計・準備 | 1ヶ月 | Swift 学習・データモデル設計・UI モック |
| iPhone 実装 | 2ヶ月 | 記録機能・履歴・分析・設定 |
| Watch 実装 | 1.5ヶ月 | スタンドアロン記録・Live Activity |
| HealthKit / AI | 1.5ヶ月 | 双方向連携・AI コーチング 3種 |
| 課金・QA | 1ヶ月 | StoreKit 2 統合・TestFlight |
| ローンチ準備 | 1ヶ月 | App Store 申請・LP・マーケ素材 |

リリース目標: **2026年末〜2027年初**

### 8.5 ローンチ後 3ヶ月の成功 KPI

| 指標 | 目標値 | 失敗ライン |
|---|---|---|
| 累計ダウンロード | 5,000 | 1,000 未満 |
| 月間アクティブユーザー（MAU） | 1,500 | 300 未満 |
| Pro トライアル開始率（DL比） | 15% | 5% 未満 |
| トライアル → 課金転換率 | 30% | 10% 未満 |
| 累計有料ユーザー | 200 | 50 未満 |
| App Store 評価 | ★4.5 以上 | ★3.5 未満 |

失敗ラインに当たった場合は、ユーザーヒアリング実施 → 機能調整 or ピボット検討。

---

## 9. リリース後ロードマップ

| Ver | テーマ | 主要追加 |
|---|---|---|
| v1.0 | MVP リリース | 記録 + Watch + Live Activity |
| v1.1 | 女性対応・コーチング | 生理周期連携 / HRV・睡眠連動の負荷提案 |
| v1.2 | AI・種目拡張 | Apple Intelligence サマリ / 自宅トレ種目追加（計200種） |
| v1.3 | センサー | Core ML レップ自動カウント |
| v2.0 | 拡張 | Vision Pro フォーム確認 / 英語UI |

---

## 10. 収益モデル

### プラン構成

| プラン | 価格 | 内容 |
|---|---|---|
| **Free** | 無料・広告なし | 基本記録機能、履歴閲覧無制限、Apple Watch記録、HealthKit書き込み、ルーティン5つまで、カスタム種目5つまで、Live Activity / Dynamic Island |
| **Pro 月額** | ¥780/月 | 全機能アンロック |
| **Pro 年額** | ¥5,800/年 | 全機能アンロック（実質 ¥483/月、月額比 38%オフ） |

### Pro 限定機能

- HealthKit 双方向連携（HRV・睡眠・安静時心拍数の読み込み）
- AIコーチング 3種（HRV 連動ディロード提案・線形回帰 PR 予測・部位別ボリューム警告）
- 高度な分析グラフ（ボリューム推移・部位別・推定1RM・PR履歴）
- ルーティン・カスタム種目 無制限
- iCloud 同期（マルチデバイス）
- Family Sharing（最大6名）
- データエクスポート（CSV / JSON）

> Live Activity / Dynamic Island は v0.x で Free 開放に方針変更。一番尖った差別化を全ユーザーに体験させ、Pro 訴求は HRV × AI コーチングへ集約する。

### トライアル・割引戦略

- 全プランで **14日間無料トライアル**（クレジットカード登録必須）
- ローンチキャンペーン：先着1,000名 or 30日間 年額50%オフ（¥2,900）
- 年に2回程度、新規ユーザー向け年額50%オフキャンペーン

### 想定 ARPU

- ¥4,000〜5,000/ユーザー/年（年額・月額・無料の比率を加味）

---

## 11. 想定リスク

### 11.1 致命的リスク（事業継続を脅かす）

| リスク | 確率 | 影響 | 対策 |
|---|---|---|---|
| 開発スケジュールの大幅遅延 | 高 | 高 | 月次マイルストーン管理、3ヶ月遅延で機能スコープ縮小判断 |
| Apple 純正が筋トレ特化機能をリリース | 中 | 高 | watchOS 各 WWDC を要観察、共存戦略の柔軟性を保つ |
| ローンチ後 6ヶ月で KPI 未達 | 中 | 高 | 撤退・ピボット判断ライン（後述）に従う |
| 個人開発のバーンアウト | 中 | 高 | 開発期間中の休息週を意図的に確保、月次セルフレビューで負荷可視化 |

### 11.2 重要リスク（事業成長を阻害）

| リスク | 確率 | 影響 | 対策 |
|---|---|---|---|
| 競合（Hevy）の日本語化対応 | 中 | 中 | 「Apple 特化＋AI コーチング」で差別化を維持 |
| 開発中の OS メジャーバージョン更新（iOS 27） | 高 | 中 | β版を継続的に追従、API 変更点を早期キャッチアップ |
| 商標トラブル（OIKOMI 既存アプリ） | 低 | 中 | リリース前に J-PlatPat で出願状況確認、サブタイトル付き登録 |
| HealthKit 権限拒否ユーザー | 中 | 低 | 拒否時も基本記録機能は動作する設計 |

### 11.3 注意リスク（影響軽微）

| リスク | 確率 | 影響 | 対策 |
|---|---|---|---|
| iOS 26 → 27 の API 変更 | 高 | 低 | Apple 純正 API のみ採用で影響最小化 |
| CloudKit のレート制限 | 低 | 低 | 同期頻度を最適化、エラーハンドリング徹底 |
| App Store 審査リジェクト | 中 | 低 | ガイドライン遵守、HealthKit 利用目的を明示 |

### 11.4 撤退・ピボット基準

リリース後 **6ヶ月時点**で以下のいずれかに該当した場合、判断を行う。意思決定の節目を固定することで、迷いと先送りを防ぐ。

| 状況 | 判断 |
|---|---|
| MAU < 500 / 累計有料 < 50 | **撤退検討** — ユーザーヒアリング後に終息か継続を判断 |
| MAU 500〜1,500 / 有料 50〜150 | **ピボット検討** — 機能・価格・ターゲットの再設計 |
| MAU > 1,500 / 有料 > 150 | **継続・拡張** — v1.1 以降のロードマップ実行 |

### 11.5 リスク管理の運用

- 月次でリスク状況をセルフレビュー（GitHub Issues にトラッキング）
- 各リスクの「発火条件」を明記し、検知次第アクション
- 6ヶ月の撤退判断ラインを意思決定の節目として固定
- 仕様書も生きたドキュメントとして、状況変化に応じて更新

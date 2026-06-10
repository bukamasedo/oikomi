# CLAUDE.md — Oikomi 開発ガイド

このファイルは Claude Code が常に参照するプロジェクトコンテキストです。
**仕様の詳細は必ず [`docs/SPEC.md`](docs/SPEC.md) を参照してください。** 本ファイルは要約と開発規律のみ。

---

## プロダクト概要

**Oikomi（追い込み）** — Apple Watch を主役とした筋トレ記録アプリ。
HealthKit / Live Activity / Apple Intelligence と統合し「iPhone で組み立て、Apple Watch で追い込む、ヘルスデータ駆動の筋トレ記録」を提供する Freemium サブスクアプリ。役割分担: iPhone = 計画・分析・管理、Apple Watch = ジムでのセッション実行・記録。

- 対応 OS: iOS 26+ / watchOS 26+（iPhone 専用）
- 開発期間目安: 8ヶ月（個人開発、リリース目標 2026年末〜2027年初）
- 課金: Pro 月額 ¥780 / 年額 ¥5,800（14日トライアル）

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| UI | SwiftUI |
| ローカルDB | SwiftData |
| 同期 | CloudKit |
| ヘルスデータ | HealthKit / WorkoutKit |
| ライブ表示 | ActivityKit (Live Activity / Dynamic Island) |
| 音声・自動化 | App Intents |
| AI | Foundation Models（オンデバイス） + 数式ベースのコーチング |
| 課金 | StoreKit 2 |

**外部依存を入れない**（仕様書 §5.4）: Firebase / RevenueCat / Supabase / RN・Flutter / Sentry / 外部 LLM API は採用しない。

---

## ディレクトリ構成

```
oikomi/
├── CLAUDE.md                  ← このファイル
├── docs/SPEC.md               ← 仕様書（一次ソース）
├── project.yml                ← XcodeGen 設定（iOS / watchOS）
├── Oikomi.xcodeproj/          ← 自動生成・gitignore 対象
├── App/
│   ├── iOS/                   ← iOS ターゲット（iPhone 専用）
│   └── Watch/                 ← watchOS ターゲット
├── Packages/OikomiKit/        ← 共有ビジネスロジック（SPM）
│   └── Sources/OikomiKit/
│       ├── Models/            ← SwiftData モデル
│       ├── Health/            ← HealthKit ラッパー
│       ├── Coaching/          ← 1RM 計算・HRV 判定など
│       └── Repositories/      ← SwiftData CRUD
├── .claude/                   ← Claude Code ハーネス
└── .swift-format              ← Apple 純正フォーマッタ設定
```

**ビジネスロジックは必ず `Packages/OikomiKit` に置く**。UI ターゲット側に書かない。
UI から SwiftData を直接クエリするのも避け、Repository 経由にする。

---

## 開発コマンド（スラッシュコマンドあり）

| コマンド | 内容 |
|---|---|
| `/build` | iOS シミュレータ向けビルド |
| `/test` | OikomiKit のユニットテスト |
| `/format` | swift-format で一括整形 |
| `/lint` | swift-format lint で違反検出 |
| `/regen` | `xcodegen generate` で `.xcodeproj` 再生成 |
| `/sim-run` | iPhone シミュレータで起動 |
| `/spec [section]` | `docs/SPEC.md` の特定セクションを抜粋表示 |
| `/release [version]` | 版上げ → commit → タグ → push（リリース手順を自動実行） |

新規セットアップ時: `brew install xcodegen` → `xcodegen generate` → Xcode で `Oikomi.xcodeproj` を開く。

`.swift` ファイル保存時に PostToolUse hook が自動で `swift-format` を実行する。

---

## Git / ブランチ運用（指示がなくても自動で守る）

個人開発向けの **trunk-based + タグ** 運用。GitFlow（develop / release 常設）は採用しない。
バージョンは**ブランチではなくタグで表す**。これを毎回守ること。

### ブランチ

- `main` = 常にビルド可能な唯一の幹。リリースはここから出す
- 作業は必ず `feature/xxx` / `fix/xxx` を `main` から切る（直接 main に大きな変更を積まない）
- **マージ済みブランチは即削除**（ローカル・リモート両方）。残骸を残さない
- `develop` / `release/*` を常設しない

### バージョン（迷子防止の肝）

- **真実の源は `project.yml`**（`CFBundleShortVersionString` = マーケ版 / `CFBundleVersion` = ビルド番号、4 ターゲット分すべて同値）
- **マーケ版** = ユーザー向け semver `MAJOR.MINOR.PATCH`
- **ビルド番号** = 単調増加の整数。版を上げても **リセットしない**（App Store が一意を要求）
- **App Store 提出のたびに対象コミットへタグを打つ**：`vMAJOR.MINOR.PATCH+BUILD`（例 `v0.1.1+13`）
- タグを打ったら GitHub Release 化して変更点を残す → 「どれが何版か」が一覧で分かる

### コミット規約

- Conventional Commits（`feat:` / `fix:` / `chore(release):` など）。本文・件名は日本語で可
- リリースコミットは `chore(release): vX.Y.Z (build N)` の形に揃える

### 守るべき判断

- 「バージョンを上げて」「リリースして」と言われたら **`/release` の手順**に従う（手作業でバラバラにやらない）
- 残骸ブランチを見つけたら掃除を提案する
- **リモートブランチ削除・タグの付け替え・force push は破壊的**なので、実行前に必ず確認を取る

---

## コーディング規約

### SwiftData / CloudKit 互換ルール（仕様書 §6.3、絶対厳守）

- すべての `@Model` プロパティは **Optional または デフォルト値** を持つ
- enum は `String` / `Int` の `rawValue` で保存（直接 enum 型を使わない）
- `@Attribute(.unique)` は **使わない**（CloudKit 同期と非互換）
- `@Relationship` には必ず `inverse:` を明示
- 画像など大容量は `CKAsset` フィールドで分離（v1.0 では不要）
- スキーマ変更は `VersionedSchema` + `SchemaMigrationPlan` を経由

### アーキテクチャ

- UI ターゲット → `OikomiKit.Repository` → SwiftData の順で隔離
- HealthKit アクセスは `OikomiKit.Health` の薄いラッパー経由
- AI コーチング判定（HRV / ボリューム / PR 予測）は純粋関数として `OikomiKit.Coaching` に集約 → テスト容易
- Apple Watch はセッション実行に特化（事前に iPhone で作成したルーティンを Watch スタンドアロンで実行・記録）。ルーティン作成・分析・設定は iPhone 専任

### ローカライズ

- UI 文字列は `Localizable.xcstrings`（String Catalog）に集約。`Text("日本語")` 等のリテラルは `LocalizedStringKey` として自動ローカライズされるため許容するが、`String` 型コンテキストの直書きは避ける
- 対応言語は **日本語（開発言語）+ 英語** の2言語（v0.x で前倒し実装）。`developmentLanguage: ja` / 各ターゲット `CFBundleLocalizations: [ja, en]` / `SWIFT_EMIT_LOC_STRINGS: YES`
- 種目名（873種）はデータ側に `Exercise.name`(日) / `nameEn`(英) を持ち、表示は `Exercise.localizedName` で言語切替。ソート・検索は `name` のまま
- OikomiKit はビジネスロジック層なので `LocalizedStringKey` 自動解決が効かない。コーチング文言・enum 表示名は `Localization/L10n.swift` の `L(_:)`（= `String(localized:bundle:.module)`）で SPM リソースの String Catalog を参照する
- キー抽出はビルド時（`swiftc` → `.stringsdata` → `xcstringstool sync`）。新規 UI 文字列を追加したら `/build` 後に各 `Localizable.xcstrings` を sync して英訳を埋める
- 種目名・コーチング文言の日本語/英語は機械翻訳ではなく自然な表現

### Swift スタイル

- swift-format に従う（`.swift-format` 設定参照）
- 関数コメントは「なぜ」のみ。「何を」はコードと型で表現する
- `// TODO` には Issue 番号か理由を併記

---

## 意図的に作らない機能（戒め）

機能要望が来ても **作らない** リスト（仕様書 Tier 5 / §5.4）:

- ソーシャル / フィード / コミュニティ機能 — Hevy の領域、「孤独な追い込み」層を取る
- フォーム動画指導 — Apple Fitness+ / Nike Training Club の領域
- パーソナルコーチとのチャット — v2.0 以降に検討
- 完全初心者向けチュートリアル動画 — 中〜上級者に集中
- 食事手入力 UI — HealthKit 経由のみ
- Android 版 — Apple 特化が崩れる
- Firebase / RevenueCat / Supabase など外部 SaaS 依存
- 外部 LLM API（OpenAI / Anthropic 等）— オンデバイス Foundation Models のみ

「これを足すと便利では？」と思った時は、まず Tier 5 と §5.4 を読み返すこと。

---

## AI コーディング規律

新機能・大きな変更に着手する前に、以下を意識する：

1. **仕様変更が必要なら `docs/SPEC.md` を先に更新する**。コードは仕様のあとを追う
2. **新しいビジネスロジックは `OikomiKit` 内 + テスト先行**で実装
3. **ブレインストーミングが必要なら `superpowers:brainstorming` スキル**を起動する
4. **SwiftData / @Model を追加・変更**するときは `swift-data-modeler` サブエージェントを使う
5. **大きなビルドエラーは推測で潰さず**、最小再現 → 仮説 → 検証の順
6. **MVP 範囲外（仕様書 §8.2）の機能は v1.0 では実装しない**。後回しでよい

### 既存パターンを優先する

新しいコードを書く前に、必ず以下を確認：

- 同じ目的のヘルパーが `OikomiKit` 内に既にないか
- SwiftData 操作なら既存 Repository が使えないか
- HealthKit アクセスなら既存 `HealthStore` ラッパーが使えないか

---

## MVP（v1.0）スコープの要点

仕様書 §8 で確定済み。Pro 限定機能の境界線：

**Free**: 基本記録・履歴無制限・Watch 記録・HealthKit 書き込み・ルーティン 5つ・カスタム種目 5つ・Live Activity / Dynamic Island
**Pro**: HealthKit 読み取り（HRV/睡眠）・AI コーチング 3種（HRV 連動ディロード含む）・高度な分析・ルーティン無制限・iCloud 同期・Family Sharing・データエクスポート

v1.0 で **作らないもの**: 生理周期連携(v1.1) / 自宅トレ種目拡張(v1.2) / 自然言語サマリ(v1.2) / レップ自動カウント(v1.3) / SharePlay(v2.0+) / App Clips(v2.0+)

---

## トラブルシュート

- `.xcodeproj` がおかしくなったら → `/regen` で再生成
- swift-format が見つからない → `xcrun --find swift-format` で確認、Xcode 同梱版を使う
- iOS 26 シミュレータが無い → Xcode → Settings → Platforms から追加
- CloudKit エラー → iCloud にサインインしているか、開発用 iCloud コンテナが作成済みか確認

---

## 実装状況（v0.1 開発中）

仕様書 §8.1 の MVP 範囲に対する達成状況。詳細は `docs/SPEC.md` を参照。

### 実装済み

**Tier 1 コア体験**
- ✅ 4.1.1 高速入力 UX（ルーティン / クイック追加 / プリフィル / レストタイマー / 進捗表示）
- ✅ 4.1.2 履歴閲覧（カレンダー UI / 日付フィルタ / 詳細 / コピー）
- ✅ 4.1.3 Apple Watch スタンドアロン記録（Digital Crown 入力）
- ✅ 4.1.4 Live Activity / Dynamic Island

**Tier 2 Apple 特化**
- ✅ 4.2.1 HealthKit 双方向（HKWorkout 書き込み + HRV / 睡眠 / 安静時心拍数読み取り）
- ✅ 4.2.2 AI コーチング 3種（ディロード / PR 予測 / ボリューム警告）
- ✅ 4.2.3 1RM 自動計算（Epley / Brzycki）

**Tier 3 継続率**
- ✅ ルーティン管理（CRUD + 並べ替え + 進行中表示）
- ✅ 種目ライブラリ 100 種（仕様書 §4.1.4 の v1.0 目標達成）
- ✅ インターバルタイマー（種目別 defaultRestSeconds）
- ✅ 履歴コピー（startSessionByCopying）
- ✅ App Intents / Siri 入力
- ✅ ウィジェット（small / medium / accessory 3 種）
- ✅ オンボーディング（3 ステップ）

### 実装済み (v0.x 拡充)

- ✅ StoreKit 2 統合（SubscriptionManager + ProGate + 実購入 UI）
- ✅ Pro 機能ゲート（ルーティン 5 / カスタム種目 5 / HealthKit 読 / AI コーチング / iCloud 同期）— Live Activity は v0.x で Free 開放
- ✅ HKWorkoutSession + Workout Buddy 共存（`WatchHealthSession` で strength training セッション起動済み。Workout Buddy が同セッションを読む設計）
- ✅ iCloud 同期 (Pro 連動)（`SubscriptionManager.lastKnownProActiveKey` を `SharedContainer.bootstrap` が参照）

### 未実装（v1.0 ローンチ前 or v1.1 以降）

- ✅ Watch Complication / Smart Stack（`OikomiWatchWidgets` 拡張で `StatsWidget` が `.accessoryCircular / .accessoryRectangular / .accessoryInline / .accessoryCorner` の 4 ファミリーをサポート。手動 Smart Stack 追加で動作確認可）
- ❌ App Store Connect 商品登録（手動別作業）
- ❌ 生理周期連携（v1.1）
- ❌ Family Sharing（v1.1）
- ❌ 自宅トレ種目 100 → 200 拡張（v1.2、現状は location タグ準備済み）
- ❌ Apple Intelligence 自然言語サマリ（v1.2、Foundation Models）
- ❌ Core ML レップ自動カウント（v1.3）

### テスト

- 99 ユニットテスト全成功（OneRepMax / Repositories / Routine / Analytics / PersonalRecord ほか）
- 実行: `swift test --package-path Packages/OikomiKit`

### ビルド対応プラットフォーム

- ✅ iOS 26+ シミュレータ
- ✅ watchOS 26 シミュレータ（Apple Watch Series 11 46mm で確認済）
- ✅ OikomiWidgets 拡張（Live Activity + Stats）
- ✅ OikomiWatchWidgets 拡張（Smart Stack / Complication 4 ファミリー）

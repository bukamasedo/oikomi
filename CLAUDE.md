# CLAUDE.md — Oikomi 開発ガイド

このファイルは Claude Code が常に参照するプロジェクトコンテキストです。
**仕様の詳細は必ず [`docs/SPEC.md`](docs/SPEC.md) を参照してください。** 本ファイルは要約と開発規律のみ。

---

## プロダクト概要

**Oikomi（追い込み）** — Apple Watch を主役とした筋トレ記録アプリ。
HealthKit / Live Activity / Apple Intelligence と統合し「Apple Watch だけで完結する、ヘルスデータ駆動の筋トレ記録」を提供する Freemium サブスクアプリ。

- 対応 OS: iOS 26+ / watchOS 26+ / iPadOS 26+ / macOS 26+
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
| 認証 | Sign in with Apple |
| 課金 | StoreKit 2 |

**外部依存を入れない**（仕様書 §5.4）: Firebase / RevenueCat / Supabase / RN・Flutter / Sentry / 外部 LLM API は採用しない。

---

## ディレクトリ構成

```
oikomi/
├── CLAUDE.md                  ← このファイル
├── docs/SPEC.md               ← 仕様書（一次ソース）
├── project.yml                ← XcodeGen 設定（マルチプラットフォーム）
├── Oikomi.xcodeproj/          ← 自動生成・gitignore 対象
├── App/
│   ├── iOS/                   ← iOS / iPadOS / Mac Catalyst ターゲット
│   ├── Watch/                 ← watchOS ターゲット
│   └── Mac/                   ← macOS ネイティブターゲット
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

新規セットアップ時: `brew install xcodegen` → `xcodegen generate` → Xcode で `Oikomi.xcodeproj` を開く。

`.swift` ファイル保存時に PostToolUse hook が自動で `swift-format` を実行する。

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
- Apple Watch スタンドアロン動作前提（iPhone が無くても全機能可）

### ローカライズ

- UI 文字列は `Localizable.xcstrings` に集約（直書き禁止）
- デフォルト言語は **日本語**。英語は v2.0 以降
- 種目名・コーチング文言の日本語は機械翻訳ではなく自然な表現

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

**Free**: 基本記録・履歴無制限・Watch 記録・HealthKit 書き込み・ルーティン 3つ・カスタム種目 5つ
**Pro**: HealthKit 読み取り（HRV/睡眠）・AI コーチング 3種・Live Activity・高度な分析・ルーティン無制限・iCloud 同期・Family Sharing・データエクスポート

v1.0 で **作らないもの**: 生理周期連携(v1.1) / 自宅トレ種目拡張(v1.2) / 自然言語サマリ(v1.2) / レップ自動カウント(v1.3) / SharePlay(v2.0+) / App Clips(v2.0+)

---

## トラブルシュート

- `.xcodeproj` がおかしくなったら → `/regen` で再生成
- swift-format が見つからない → `xcrun --find swift-format` で確認、Xcode 同梱版を使う
- iOS 26 シミュレータが無い → Xcode → Settings → Platforms から追加
- CloudKit エラー → iCloud にサインインしているか、開発用 iCloud コンテナが作成済みか確認

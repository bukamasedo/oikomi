# Oikomi（追い込み）

Apple エコシステム特化の筋トレ記録アプリ。HealthKit / Live Activity / Apple Intelligence を統合し、**「iPhone で組み立て、Apple Watch で追い込む、ヘルスデータ駆動の筋トレ記録」** を目指す。役割分担: iPhone でルーティンと種目を計画し、ジムでは Apple Watch スタンドアロンでセッションを実行・記録する。

詳しい仕様は [`docs/SPEC.md`](docs/SPEC.md) を参照。

## 必要環境

- macOS Tahoe（macOS 26+）
- Xcode 26.2 以上
- iOS 26 / watchOS 26 / macOS 26 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## セットアップ

```bash
# 1. XcodeGen をインストール（未導入の場合）
brew install xcodegen

# 2. Xcode プロジェクトを生成
xcodegen generate

# 3. Xcode で開く
open Oikomi.xcodeproj
```

`.xcodeproj` は gitignore 済みで、`project.yml` から再生成されます。プロジェクト構造を変えたいときは `project.yml` を編集して `xcodegen generate` を再実行してください。

## プロジェクト構造

| パス | 役割 |
|---|---|
| `docs/SPEC.md` | 仕様書（一次ソース） |
| `CLAUDE.md` | AI コーディングハーネス向け開発ガイド |
| `project.yml` | XcodeGen 設定 |
| `App/iOS` | iOS / iPadOS / Mac Catalyst アプリ |
| `App/Watch` | watchOS アプリ |
| `App/Mac` | macOS ネイティブアプリ |
| `Packages/OikomiKit` | 共有ビジネスロジック（Swift Package） |
| `.claude/` | Claude Code 用設定・スラッシュコマンド |

## 開発フロー

ビジネスロジックは `Packages/OikomiKit` に集約し、各 UI ターゲットからリンクして使います。UI ターゲットには SwiftData クエリを直接書かず、`OikomiKit` の Repository 経由でアクセスします。

スタンドアロンのテスト：

```bash
swift test --package-path Packages/OikomiKit
```

ビルド：

```bash
xcodebuild build -scheme Oikomi -destination 'generic/platform=iOS Simulator'
```

整形：

```bash
xcrun swift-format -i -r App Packages/OikomiKit/Sources
```

## Claude Code で開発

Claude Code を使うと、リポジトリ内の `.claude/commands/` に定義されたスラッシュコマンド（`/build`, `/test`, `/format`, `/regen` 等）と、保存時の自動フォーマットフックが利用できます。詳細は [`CLAUDE.md`](CLAUDE.md) を参照。

## 現在の実装状況（v0.1 開発中）

- **iOS アプリ（5タブ）**: ホーム / トレーニング / 履歴 / 分析 / 設定
- **Apple Watch アプリ**: ルーティン実行・記録（スタンドアロン動作）、Digital Crown 入力
- **macOS アプリ**: プレースホルダ（本格 UI は v2.0）
- **ウィジェット拡張**: Live Activity（Dynamic Island 対応）+ 統計ウィジェット
- **OikomiKit**: 7 つの SwiftData モデル + 4 つの Repository + Analytics + Coaching + HealthKit ラッパー
- **テスト**: 39 ユニットテスト全成功

### 達成済み主要機能

- ルーティン管理（並べ替え可・進行中の進捗表示）
- 100 種目のシードライブラリ（検索・部位フィルタ）
- 自動レストタイマー（種目別 defaultRestSeconds）
- HealthKit セッション書き込み + HRV / 睡眠 / 安静時心拍数読み取り
- AI コーチング 3 種（ディロード / PR 予測 / ボリューム警告）
- 履歴カレンダー UI + コピー機能
- 種目別最大重量推移チャート（Swift Charts）
- Live Activity / Dynamic Island
- Siri / ショートカット記録（App Intents）

詳細な機能リストと実装スコープは [`CLAUDE.md`](CLAUDE.md) の「実装状況」セクションを参照。

## ライセンス

未定（リリースまでに決定）。

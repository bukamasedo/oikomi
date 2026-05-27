---
layout: default
title: スクリーンショット撮影台本
permalink: /release/screenshots/
---

# App Store Connect — スクリーンショット撮影台本 (v1.0)

最終更新: 2026-05-27
対象: iPhone 6.9" / iPad 13" / Apple Watch 49mm 用スクリーンショット
配信地域: 日本（v1.0）

---

## 必要解像度（2026 年時点の Apple 要件）

| デバイス | 解像度 (Portrait) | ASC 必須？ | 最大枚数 |
|---|---|---|---|
| iPhone 6.9" (17 Pro Max / 16 Pro Max) | **1320 × 2868** | ✅ 必須 | 10 |
| iPad 13" (iPad Pro M4 / M5) | **2064 × 2752** | ✅ 必須 | 10 |
| Apple Watch 49mm (Series 10 / 11) | **410 × 502** | 任意（watchOS バイナリ申請時推奨） | 10 |

> iPhone 6.9" を提出すれば 6.7" / 6.5" / 5.5" は自動的に同じスクショが流用される。
> iPad 13" を提出すれば iPad Pro 12.9" / 11" / mini 等にも流用される。
> 別解像度の提出は不要（ASC が自動スケール）。

---

## 撮影前のシミュレータ準備

### A. 使うシミュレータ

```
iPhone 17 Pro Max  (iOS 26.x)         — メイン
iPad Pro 13"       (iPadOS 26.x)      — タブレット
Apple Watch 49mm   (watchOS 26.x)     — Watch 用
```

Xcode → Settings → Platforms で iOS 26 / watchOS 26 シミュレータを取得済み
（CLAUDE.md「ビルド対応プラットフォーム」参照）。

### B. ステータスバーの整形

撮影前に必ず実行（時刻 9:41 / バッテリー満タン / 電波最大は Apple 推奨）:

```bash
# 起動中の全シミュレータに適用
xcrun simctl status_bar booted override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --operatorName "" \
    --batteryState charged \
    --batteryLevel 100
```

watchOS シミュレータも同様。

### C. デモデータ投入

リアルなスクショには 4〜12 週分の履歴が必要。実機開発ビルドではなく
**シミュレータでサインインなし**を前提に、以下のいずれか:

1. **手動投入** — 種目ライブラリ 873 種からベンチ・スクワット・デッド・懸垂
   ベンチローを選び、過去 8 週分のセッションを Quick Add で投入（30 分作業）
2. **専用 DemoSeed 機能の追加（推奨）** — `OikomiKit` に
   `DemoSeed.populateForScreenshots(modelContext:)` を生やし、Settings に
   "Debug → Populate demo data" メニューを Release ビルドでは隠す形で追加

> 提案: D-1 着手時に DemoSeed を実装すると、将来の Marketing 更新時も再現性が
> 出るので投資効果が高い。30 行程度のヘルパー関数で済む想定。

HealthKit データ（HRV / 睡眠 / 心拍）はシミュレータでは Health アプリが
スタブのみ。スクショ用には:

- iPhone Simulator: **Health → Browse → "Add Data"** で 7 日分の HRV (50-80ms)、
  睡眠（7-8h）、安静時心拍（55-65bpm）を手入力
- これは撮影セッションの最初に 1 回やればよい

### D. アプリ状態

- オンボーディング完了済み
- Pro 状態 ON（Sandbox サブスク or 開発フラグ `lastKnownProActiveKey = true`）
- 言語: 日本語
- アクセントカラー: AppIcon 系（既存設定）

---

## iPhone 6.9" 撮影リスト（10 枚）

各スクショは **アプリ内 UI のみ**（端末フレームやテキストオーバーレイは ASC
アップロード後に同梱の "Screenshot Tools" でも追加可。今回は **生のスクショで提出**
を推奨。Apple のレビュー通過率も高い）。

| # | 画面 | 投入する状態 | キャッチコピー候補（任意） |
|---|---|---|---|
| 1 | **ホーム** | 週次目標リング 4/5、今日のコンディション (HRV 72ms / 睡眠 7h12m)、直近 PR ハイライト | "Apple Watch だけで完結する筋トレ" |
| 2 | **トレーニング進行中** | プッシュ・デイ、ベンチ 80kg × 8 を 3 セット中 2 セット完了、レストタイマー 60s | "1〜3 タップで 1 セット記録" |
| 3 | **AI コーチング** | ホーム下部の Coaching Chip 3 枚（HRV ディロード / PR 予測 / ボリューム警告） | "HRV と睡眠を読むスマート提案" |
| 4 | **分析・推移** | 週次総ボリュームバーチャート + ベンチ最大重量ライン | "過去のすべてを 1 タップで可視化" |
| 5 | **履歴カレンダー** | カレンダー UI で当月の活動日ハイライト + 直近セッション一覧 | "履歴は永久保存。期間制限なし" |
| 6 | **ルーティン一覧** | Push / Pull / Legs / Full Body の 4 ルーティングリッド | "ワンタップで開始、前回値を自動プリフィル" |
| 7 | **Live Activity (ロック画面合成)** | ロック画面に Live Activity（Dynamic Island 用画像を別途）| "進行中を常時表示" |
| 8 | **Pro アップグレード** | プラン選択シート、年額タブ選択中、14日トライアル表示 | "14 日間無料でフル機能を試す" |
| 9 | **設定・データ管理** | HealthKit 連携 ON、iCloud 同期 ON、CSV エクスポート | "外部送信ゼロ。すべて端末内＋ iCloud" |
| 10 | **Tip Jar (任意)** | TipJarSheet を開いた状態 | "気に入ったら開発を応援できる" |

### 順序の意図

1-3 が **コア体験**（毎日見るホーム → 記録 → コーチング）
4-6 が **継続率**（履歴・分析・ルーティン）
7-8 が **差別化と課金**（Live Activity → Pro）
9-10 が **信頼**（プライバシー → 任意支援）

### 撮影手順

各画面で:

```
Cmd+S        # シミュレータ → File → Save Screen
# または
xcrun simctl io booted screenshot --type=png ~/Desktop/oikomi-iphone-01.png
```

出力ファイル名は `oikomi-iphone-{番号}-{画面名}.png` で命名。

---

## iPad 13" 撮影リスト（5 枚で十分）

iPad は閲覧用途に強み。ハイライトを絞る。

| # | 画面 | 備考 |
|---|---|---|
| 1 | ホーム（横画面 Master-Detail 想定、現状 v1.0 は iPhone 流用なら Portrait） | iPad で UI が破綻していないことを示す |
| 2 | 分析・推移（大画面でグラフが映える） | 部位別ボリュームと推移ラインを一画面に |
| 3 | 履歴カレンダー（カレンダーがフル幅で広い） | iPad の画面の広さを活かす |
| 4 | Pro アップグレード | 課金 UI が iPad でも崩れない確認 |
| 5 | ルーティン管理 | 大画面で複数ルーティンを並べる |

> v1.0 では iPad は iPhone レイアウトの流用が中心。撮影時に大きな破綻が
> なければそのまま提出。破綻があれば D-1 終了時に Issue 化して v1.0.1 で対応。

---

## Apple Watch 49mm 撮影リスト（任意・3〜5 枚）

| # | 画面 | 備考 |
|---|---|---|
| 1 | 種目選択（Digital Crown 入力中） | スタンドアロン動作の象徴 |
| 2 | レストタイマー進行中 | カウントダウン視覚化 |
| 3 | セット完了直後（チェックマーク） | 入力 UX の軽快さ |
| 4 | Smart Stack（Stats Widget） | 4 ファミリーのうち rectangular |
| 5 | ルーティン選択 | （撮影時間に余裕あれば） |

撮影:

```bash
xcrun simctl io booted screenshot --type=png \
    ~/Desktop/oikomi-watch-01-exercise.png
# Watch サイズは自動で 410 x 502
```

> Apple Watch のスクショは Watch アプリの ASC で別途提出。
> Watch 用 ASC エントリは iOS アプリと統合管理（companion watchOS bundle）。

---

## アップロードフロー

1. **ASC → My Apps → Oikomi → iOS App → Version 1.0**
2. **App Previews and Screenshots** セクション
3. デバイス選択タブで **6.9" Display** → 10 枚をドラッグ＆ドロップ
4. 同じく **iPad Pro 13"** → 5 枚をドラッグ＆ドロップ
5. （任意）**Apple Watch Ultra (49mm)** → 3〜5 枚
6. 順序は ASC 上でドラッグ並べ替え可。1 枚目が "Hero" として検索結果に出る

---

## チェックリスト

- [ ] iPhone 17 Pro Max シミュレータでステータスバー化粧
- [ ] iPad Pro 13" シミュレータでステータスバー化粧
- [ ] Apple Watch 49mm シミュレータでステータスバー化粧（時計のみ）
- [ ] デモデータ投入（8 週分のセッション履歴）
- [ ] HealthKit に HRV / 睡眠 / 心拍を手入力
- [ ] Pro 状態を ON にする
- [ ] iPhone 6.9" 10 枚撮影
- [ ] iPad 13" 5 枚撮影
- [ ] Watch 49mm 3〜5 枚撮影
- [ ] **IAP Review Screenshot 撮影**（→ [iap-products.md](./iap-products.md) 参照、Pro 課金画面 + Tip Jar）
- [ ] ファイル命名規則に従ってリネーム
- [ ] ASC へアップロード
- [ ] 1 枚目が "Hero" として狙いの画面になっているか確認

---

## App Preview 動画（任意・v1.0 では見送り推奨）

Apple は 15-30 秒の動画もサポート（iPhone 縦長 1080×1920 等）。
v1.0 では **撮影工数 vs CVR 改善幅** の trade-off で見送り、
v1.1 のリリースに合わせて作成を検討。

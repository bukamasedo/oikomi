---
layout: default
title: スクリーンショット撮影台本
permalink: /release/screenshots/
---

# App Store Connect — スクリーンショット撮影台本 (v1.0)

最終更新: 2026-05-27
対象: iPhone 6.9" / Apple Watch 49mm 用スクリーンショット（iPhone 専用アプリ）
配信地域: 日本（v1.0）

---

## 必要解像度（2026 年時点の Apple 要件）

| デバイス | 解像度 (Portrait) | ASC 必須？ | 最大枚数 |
|---|---|---|---|
| iPhone 6.9" (17 Pro Max / 16 Pro Max) | **1320 × 2868** | ✅ 必須 | 10 |
| Apple Watch 49mm (Series 10 / 11) | **410 × 502** | 任意（watchOS バイナリ申請時推奨） | 10 |

> iPhone 6.9" を提出すれば 6.7" / 6.5" / 5.5" は自動的に同じスクショが流用される。
> 別解像度の提出は不要（ASC が自動スケール）。
> iPad スクショは不要（`TARGETED_DEVICE_FAMILY: "1"` で iPhone 専用配信）。

---

## 撮影前のシミュレータ準備

### A. 使うシミュレータ

```
iPhone 17 Pro Max  (iOS 26.x)         — メイン
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

**ナラティブの軸**: 最初の 2 枚で「**iPhone で計画、Apple Watch で実行**」の役割分担を打ち込む。Watch は実行特化（ルーティン作成は iPhone）が実装の現実なので、Watch を単独で前面に出して "Watch だけで完結" と謳うのは事実と乖離する。

| # | 画面 | 投入する状態 | キャッチコピー候補（任意） |
|---|---|---|---|
| 1 | **iPhone ホーム** | 週次目標リング 4/5、今日のコンディション (HRV 72ms / 睡眠 7h12m)、直近 PR ハイライト | "iPhoneで組み立て、Apple Watchで追い込む" |
| 2 | **iPhone ルーティン編集** | "Push - Heavy Day" を編集中、種目 5 種、計画レップ / 重量を入力 | "ジムに行く前に、家でじっくり計画" |
| 3 | **Apple Watch セット記録（Watch 単独スクショ）** | ベンチプレス 80kg × 8、Digital Crown で重量変更中 | "ジムでは、Apple Watchだけで記録" |
| 4 | **AI コーチング** | ホーム下部の Coaching Chip 3 枚（HRV ディロード / PR 予測 / ボリューム警告） | "HRV と睡眠が、今日の負荷を決める" |
| 5 | **Live Activity (ロック画面)** | レストタイマー残り 00:42、Dynamic Island compact 別添 | "進行中は、常に手元に" |
| 6 | **ルーティン一覧** | Push / Pull / Legs / Full Body の 4 ルーティングリッド | "一度組めば、何度でも使い回せる" |
| 7 | **推移グラフ（分析）** | ベンチプレス推定 1RM の 12 週ライン + PR バッジ "95.4kg ↑" | "重ねた一本は、必ず数字で残る" |
| 8 | **履歴カレンダー** | 当月の活動日 16/30 ハイライト + サマリー "16セッション / 142セット / 28,400kg" | "歴史は消えない、無料で永久保存" |
| 9 | **Pro アップグレード** | 年額タブ選択中、"14日間無料トライアル" バッジ表示 | "14 日間、無料でフル機能" |
| 10 | **プライバシー設定** | "外部送信: なし" "分析SDK: 不使用" "iCloud同期: 任意" を明示 | "外部送信ゼロ、あなたの端末で完結" |

### 順序の意図

- **#1–#2 計画フェーズ**: iPhone でルーティンを組み立てる体験 → 役割分担の前半を伝える
- **#3 実行フェーズ**: Apple Watch 単独スクショで「ジムでは手首だけ」を象徴的に伝える
- **#4–#5 差別化**: AI コーチング × Live Activity（Oikomi の核）
- **#6–#8 継続率**: 再利用性 × 数値化 × 永久保存
- **#9–#10 意思決定**: 課金 × 信頼

### 撮影手順

各画面で:

```
Cmd+S        # シミュレータ → File → Save Screen
# または
xcrun simctl io booted screenshot --type=png ~/Desktop/oikomi-iphone-01.png
```

出力ファイル名は `oikomi-iphone-{番号}-{画面名}.png` で命名。

---

## Apple Watch 49mm 撮影リスト（任意・3〜5 枚）

| # | 画面 | 備考 |
|---|---|---|
| 1 | 種目選択（Digital Crown 入力中） | ジムで手首だけで実行する象徴 |
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
4. （任意）**Apple Watch Ultra (49mm)** → 3〜5 枚
5. 順序は ASC 上でドラッグ並べ替え可。1 枚目が "Hero" として検索結果に出る

---

## チェックリスト

- [ ] iPhone 17 Pro Max シミュレータでステータスバー化粧
- [ ] Apple Watch 49mm シミュレータでステータスバー化粧（時計のみ）
- [ ] デモデータ投入（8 週分のセッション履歴）
- [ ] HealthKit に HRV / 睡眠 / 心拍を手入力
- [ ] Pro 状態を ON にする
- [ ] iPhone 6.9" 10 枚撮影
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

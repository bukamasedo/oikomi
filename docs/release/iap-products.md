---
layout: default
title: IAP 商品登録テンプレ
permalink: /release/iap-products/
---

# App Store Connect — In-App Purchase 登録テンプレ (v1.0)

最終更新: 2026-05-27
対象: App Store Connect → My Apps → Oikomi → Monetization
ソースオブトゥルース: [`Oikomi.storekit`](../../Oikomi.storekit) / [`ProductIDs.swift`](../../Packages/OikomiKit/Sources/OikomiKit/Subscription/ProductIDs.swift) / [`TipProductIDs.swift`](../../Packages/OikomiKit/Sources/OikomiKit/Subscription/TipProductIDs.swift)

---

## 全体像

合計 6 商品。

| Product ID | 種別 | 価格 (JPY) | 用途 |
|---|---|---|---|
| `com.shuhirouchi.oikomi.pro.monthly` | Auto-Renewable Subscription | 780 | Pro 機能解放（月額） |
| `com.shuhirouchi.oikomi.pro.yearly` | Auto-Renewable Subscription | 5,800 | Pro 機能解放（年額・実質 ¥483/月） |
| `com.shuhirouchi.oikomi.tip.sportsdrink` | Consumable | 120 | 開発支援チップ（最小） |
| `com.shuhirouchi.oikomi.tip.protein` | Consumable | 250 | 開発支援チップ（小） |
| `com.shuhirouchi.oikomi.tip.chicken` | Consumable | 500 | 開発支援チップ（中） |
| `com.shuhirouchi.oikomi.tip.cheatday` | Consumable | 1,000 | 開発支援チップ（大） |

すべて **Family Sharing: Off** で登録（CLAUDE.md 実装状況の §「Family Sharing」は
v1.1 で対応予定 / `familyShareable: false` 統一）。

---

## サブスクリプショングループ

ASC → Monetization → **Subscriptions → Subscription Groups** → 新規作成。

| 項目 | 入力値 |
|---|---|
| Reference Name | `Oikomi Pro` |
| App Store Localized Display Name (ja_JP) | `Oikomi Pro` |
| App Store Localized Display Name (en_US) | `Oikomi Pro` |

> 月額と年額を同一グループに入れることで、ユーザーは自動的にアップグレード /
> ダウングレード可能（Apple 側でプロレーション処理）。

---

## サブスクリプション 1: Oikomi Pro 月額

ASC → Monetization → Subscriptions → グループ "Oikomi Pro" → "+" → Auto-Renewable

### 基本情報

| 項目 | 入力値 |
|---|---|
| Reference Name (ASC 内部用) | `Oikomi Pro Monthly` |
| Product ID | `com.shuhirouchi.oikomi.pro.monthly` |
| Subscription Duration | 1 Month |
| Family Sharing | Off |
| Cleared for Sale | Yes |

### 価格

| Storefront | 価格 |
|---|---|
| Japan (JPY) | ¥780 |

> 他地域配信は v2.0 以降。JPY 単独で登録。

### Subscription Localization (ja-JP)

| 項目 | 入力値 |
|---|---|
| Subscription Display Name | `Oikomi Pro 月額` |
| Description | `Pro 機能をすべて使えます（月額）` |

### Subscription Localization (en-US, 将来用)

| 項目 | 入力値 |
|---|---|
| Subscription Display Name | `Oikomi Pro Monthly` |
| Description | `Unlock all Oikomi Pro features (monthly)` |

### Introductory Offer (14日トライアル)

| 項目 | 入力値 |
|---|---|
| Offer Type | Free |
| Duration | 2 Weeks |
| Eligibility | New Subscribers |
| Countries | Japan |

### Review Information

- **Screenshot for Review**: Pro アップグレード画面（`SubscriptionUpgradeView` 系）の
  iPhone 6.9" スクリーンショット（後述の D-1 で撮影）
- **Review Notes** (英文推奨):

```
Auto-renewable monthly subscription. Unlocks HealthKit read access,
AI coaching (HRV-based deload, PR prediction, volume warning),
advanced analytics, unlimited routines and custom exercises, iCloud
sync, and CSV data export. 14-day free trial for new subscribers.
Manage in iOS Settings → [Name] → Subscriptions.
```

---

## サブスクリプション 2: Oikomi Pro 年額

### 基本情報

| 項目 | 入力値 |
|---|---|
| Reference Name | `Oikomi Pro Yearly` |
| Product ID | `com.shuhirouchi.oikomi.pro.yearly` |
| Subscription Duration | 1 Year |
| Family Sharing | Off |
| Cleared for Sale | Yes |
| Subscription Group | `Oikomi Pro`（月額と同一）|

### 価格

| Storefront | 価格 |
|---|---|
| Japan (JPY) | ¥5,800 |

### Subscription Localization (ja-JP)

| 項目 | 入力値 |
|---|---|
| Subscription Display Name | `Oikomi Pro 年額` |
| Description | `Pro 機能をすべて使えます（年額・実質 ¥483/月）` |

### Subscription Localization (en-US, 将来用)

| 項目 | 入力値 |
|---|---|
| Subscription Display Name | `Oikomi Pro Yearly` |
| Description | `Unlock all Oikomi Pro features (yearly)` |

### Introductory Offer (14日トライアル)

月額と同じ Free / 2 Weeks / New Subscribers / Japan。

### Review Information

- **Screenshot for Review**: Pro アップグレード画面（年額タブを選択した状態）
- **Review Notes**: 月額の英文に "yearly" 差し替え

---

## Consumable 1〜4: Tip Jar

ASC → Monetization → In-App Purchases → "+" → **Consumable** で 4 商品作成。
サブスクリプショングループには属さない。

### 共通入力フォーマット

各 Tip 商品で以下を埋める:

```
Reference Name (内部用):       {下表の値}
Product ID:                    {下表の値}
Type:                          Consumable
Family Sharing:                Off
Cleared for Sale:              Yes
Price (Japan):                 {下表の値}

Localization (ja-JP):
  Display Name:                {下表の値}
  Description:                 {下表の値}

Localization (en-US):
  Display Name:                {下表の値}
  Description:                 {下表の値}

Review Screenshot:             TipJarSheet を開いた状態の iPhone 6.9"
Review Notes:                  下記共通テンプレ
```

### 商品マトリクス

| Reference Name | Product ID | 価格 | Display Name (ja) | Description (ja) | Display Name (en) | Description (en) |
|---|---|---|---|---|---|---|
| `Tip - Sports Drink` | `com.shuhirouchi.oikomi.tip.sportsdrink` | ¥120 | `🥤 スポーツドリンク 1 本` | `スポーツドリンク 1 本分の応援。ありがとうございます！` | `🥤 Sports Drink` | `Buy the developer a sports drink.` |
| `Tip - Protein` | `com.shuhirouchi.oikomi.tip.protein` | ¥250 | `🥛 プロテイン 1 杯` | `プロテイン 1 杯分の応援。励みになります。` | `🥛 Protein Shake` | `Buy the developer a protein shake.` |
| `Tip - Chicken` | `com.shuhirouchi.oikomi.tip.chicken` | ¥500 | `🍗 鶏胸肉 200g` | `鶏胸肉 200g 分の応援。本当にありがとう！` | `🍗 Chicken Breast 200g` | `Buy the developer 200g of chicken breast.` |
| `Tip - Cheat Day` | `com.shuhirouchi.oikomi.tip.cheatday` | ¥1,000 | `🥩 焼肉チートデイ` | `焼肉チートデイ級の大応援。最高です！` | `🥩 BBQ Cheat Day` | `Treat the developer to a cheat day BBQ.` |

### Tip Jar 共通 Review Notes (英文)

```
Non-consumable tip / appreciation IAP. Provides no in-app entitlement
or feature unlock — purely a way for satisfied users to support the
developer. Accessible from Settings → "Tip Jar" or "Buy Me A Protein
Shake". After purchase, the app shows a thank-you toast and increments
a lifetime tip total displayed in the same sheet.

Per App Store Review Guideline 3.1.1: this is supplementary support
for an otherwise free/freemium app, not required to unlock any
functionality. Receipt validation uses StoreKit 2 Transaction.currentEntitlements.
```

> Note: ASC 上は **Consumable** 区分。日本の確定申告上は売上計上。

---

## Review Screenshot 撮影プラン

Apple は各 IAP に **Screenshot for Review (1024×1024 推奨)** を要求する。
最低限の合格条件は「商品が App 内 UI に表示されている画像」。

### 撮影セット

| 商品群 | 撮影画面 | 元 View | 備考 |
|---|---|---|---|
| Pro 月額 / 年額 | Pro アップグレードシート（プラン選択 UI） | `App/iOS/Views/Subscription/*` | 月額タブ・年額タブで 2 枚 |
| Tip Jar 4 種 | `TipJarSheet`（全 4 ボタンが見える） | `App/iOS/Views/TipJar/TipJarSheet.swift` | 1 枚を 4 商品で使い回し可 |

### 撮影手順（D-1 で実施）

1. iPhone 17 Pro Max シミュレータで Release ビルドを起動
2. Pro アップグレード画面 → Cmd+S で 1290×2796 スクショ
3. 同じく年額タブを選択 → Cmd+S
4. 設定タブ → Tip Jar → Cmd+S
5. ASC アップロード時に 1024×1024 にクロップ（プレビュー領域を中心に切り出し）

> Apple は 1024×1024 を推奨しているが、実際は **iPhone 6.9" のフルスクショ (1290×2796)** をそのままアップしても通る (2024 年以降の運用)。

---

## 提出フロー

1. **Subscription Group** 作成 → "Oikomi Pro"
2. **月額** 商品作成 → 上記値で入力 → Save
3. **年額** 商品作成 → 上記値で入力 → Save
4. **Tip 4 商品** を順次作成（Consumable として）
5. すべての商品の **Review Screenshot** をアップロード（D-1 後）
6. 各商品を **"Ready to Submit"** ステータスに遷移
7. アプリ本体の v1.0 申請に **6 商品すべてを Bundled** で添付して提出
   （ASC の App Submission ページで IAP を選択する）

---

## チェックリスト

- [ ] Subscription Group "Oikomi Pro" 作成
- [ ] `pro.monthly` 商品作成（価格 ¥780 / 14日トライアル）
- [ ] `pro.yearly` 商品作成（価格 ¥5,800 / 14日トライアル）
- [ ] `tip.sportsdrink` 商品作成（¥120）
- [ ] `tip.protein` 商品作成（¥250）
- [ ] `tip.chicken` 商品作成（¥500）
- [ ] `tip.cheatday` 商品作成（¥1,000）
- [ ] 6 商品分の Review Screenshot をアップロード
- [ ] 6 商品とも "Ready to Submit" ステータス
- [ ] v1.0 申請時にバンドルして提出

---

## 提出後のメンテナンス

- 価格変更: ASC で直接変更可（次回更新サイクルから適用）
- ローカライズ追加: 新規 storefront を opt-in にする際に追加
- 新規 Tip 額の追加: コード側 (`TipProductIDs.swift` + `Oikomi.storekit`) と
  ASC の両方を同期更新。本ドキュメントも改訂

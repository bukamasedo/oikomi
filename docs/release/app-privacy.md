---
layout: default
title: App Privacy 入力テンプレ
permalink: /release/app-privacy/
---

# App Store Connect — App Privacy 入力テンプレ (v1.0)

最終更新: 2026-05-27
対象: App Store Connect → My Apps → Oikomi → App Privacy

このドキュメントは App Store Connect の "App Privacy" 質問票に答える際の
入力テンプレ。**[`docs/legal/privacy-policy.md`](../legal/privacy-policy.md)**
と整合している。

---

## 結論

> **Data Not Collected** を選択する。

Apple の定義 (Developer → App Privacy Details) では、以下のいずれかに該当する
データは "collection" とみなされない:

1. 端末内のみで処理され、開発者のサーバーに送信されない
2. CloudKit Private Database に保存される（ユーザーの Apple ID で隔離、
   開発者は内容にアクセス不可）
3. HealthKit 内のデータ（Apple が管理、開発者の独自保存・送信なし）
4. StoreKit/IAP の購入情報（Apple が処理、開発者の独自保存・送信なし）

Oikomi の取り扱うデータはすべて上記いずれかに該当するため、Data Not Collected
で申告できる。

---

## ASC 入力フロー

App Store Connect → 対象アプリ → "App Privacy" タブ:

### Step 1. Privacy Policy URL

```
https://bukamasedo.github.io/oikomi/legal/privacy/
```

### Step 2. Data Types

質問: **"Do you or your third-party partners collect data from this app?"**

**回答: No, we do not collect data from this app.**

→ そのまま "Publish" で確定。それ以降の詳細セクション（Data Linked to You /
Tracking 等）は表示されない。

---

## 裏付けエビデンス（レビュアー質問対応用）

App Privacy のレビューでクレームが入った場合、以下を引用して回答できる。

### 1. 外部送信ゼロ

| カテゴリ | 通信先 | 性質 |
|---|---|---|
| トレーニング記録 | SwiftData (端末内) + CloudKit Private DB (任意/Pro) | Apple 管理、Developer アクセス不可 |
| HRV / 睡眠 / 心拍 / 体重等 | HealthKit (端末内) | Apple 管理、Developer 保存なし |
| ワークアウト書き込み | HealthKit (端末内) → アクティビティリング反映 | 同上 |
| Pro サブスクリプション | StoreKit 2 (App Store) | Apple 管理、Developer は権利フラグのみキャッシュ |
| Watch ↔ iPhone | WatchConnectivity (WCSession) | Apple 管理、外部サーバ経由なし |
| アプリアイコン選択 | 端末内 UserDefaults + App Group | 端末内のみ |

### 2. 第三者 SDK 不使用

- 依存パッケージ: `Packages/OikomiKit/Package.swift` — Pure Swift、外部依存ゼロ
- Firebase / Sentry / Mixpanel / Amplitude / Google Analytics 等は不採用
  （CLAUDE.md §5.4「外部依存を入れない」方針）

### 3. トラッキングなし

- `NSUserTrackingUsageDescription` を Info.plist に含めていない
- `AppTrackingTransparency` / `ATTrackingManager` を一切インポートしていない
- IDFA を取得しない

### 4. アカウント情報を扱わない

- Sign in with Apple は v0.x で削除済み（コミット履歴参照）
- メール / 電話番号 / 氏名 / 位置情報 / 写真 / 連絡先のいずれも要求しない
- レビュー用デモアカウントも不要（オンボーディングで「後で設定」を選べる）

---

## レビュー質問が入った場合の返信テンプレ

```
Thank you for the review.

Oikomi does not collect any user data per Apple's App Privacy Details
definition. All workout records, settings, and health metrics are processed
entirely on-device using SwiftData and HealthKit. Optional iCloud sync
(Pro plan) stores data exclusively in the user's private CloudKit
container, which the developer cannot access.

We use no third-party SDKs, analytics, advertising, or tracking
frameworks. Subscription purchases are handled entirely by Apple's
StoreKit 2; we cache only a boolean entitlement flag locally.

Privacy policy: https://bukamasedo.github.io/oikomi/legal/privacy/
```

---

## 将来データ収集を追加する場合の更新フロー

新機能で開発者サーバーへの送信が発生した場合（例: クラッシュレポート SaaS、
プッシュ通知サーバー、E メール登録）、以下を順に更新:

1. `docs/legal/privacy-policy.md` を改訂（収集データ・用途・第三者を明記）
2. 本ファイルを改訂（"Data Not Collected" → 該当データタイプを列挙）
3. ASC App Privacy 質問票で該当データタイプにチェック
4. 同バージョン提出時に Privacy Policy の最終更新日も更新

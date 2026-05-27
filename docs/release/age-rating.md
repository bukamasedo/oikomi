---
layout: default
title: Age Rating 質問票テンプレ
permalink: /release/age-rating/
---

# App Store Connect — Age Rating 質問票テンプレ (v1.0)

最終更新: 2026-05-27
対象: App Store Connect → My Apps → Oikomi → App Information → Age Rating

---

## 結論

> 目標レーティング: **4+**

Oikomi は中〜上級トレーニーをターゲットとした筋トレ記録アプリで、暴力 /
性的 / 賭博 / 薬物等の要素は一切含まない。フィットネスデータ（HRV / 睡眠 /
心拍）の表示と AI コーチングは医療助言には該当しない（ストア説明文の
"医療上の免責" 参照）ため、Medical/Treatment Information も **None** で
申告できる。

実装上は **13 歳以上を推奨**（プライバシーポリシー §6）だが、これはストアの
Age Rating とは別軸であり、4+ で問題ない。

---

## 各質問への回答

App Store Connect の Age Rating 質問票（2024 年改訂版）。

| # | カテゴリ | 回答 | 備考 |
|---|---|---|---|
| 1 | Cartoon or Fantasy Violence | **None** | ゲーム要素なし |
| 2 | Realistic Violence | **None** | — |
| 3 | Prolonged Graphic or Sadistic Realistic Violence | **None** | — |
| 4 | Profanity or Crude Humor | **None** | 罵倒語・卑語なし |
| 5 | Mature/Suggestive Themes | **None** | — |
| 6 | Horror/Fear Themes | **None** | — |
| 7 | Medical/Treatment Information | **None** | フィットネス情報のみで医療助言・症状診断・治療法は提供しない |
| 8 | Alcohol, Tobacco, or Drug Use or References | **None** | — |
| 9 | Simulated Gambling | **None** | — |
| 10 | Sexual Content and Nudity | **None** | — |
| 11 | Graphic Sexual Content and Nudity | **None** | — |
| 12 | Contests | **None** | リーダーボードなし |
| 13 | Unrestricted Web Access | **No** | アプリ内ブラウザなし（外部 URL は Safari で開く） |
| 14 | Gambling | **No** | — |

その他のフラグ:

| 項目 | 回答 | 備考 |
|---|---|---|
| Made for Kids (Kids Category 申請) | **No** | Tier 5 で「初心者向けチュートリアル不要」と確定済み |
| Age Restriction Limits Eligibility for Apple Programs | (該当なし) | — |

→ 質問票確定後、App Store 表示は **4+** になる想定。

---

## Q7 (Medical/Treatment Information) を None にする根拠

Apple のガイドラインでは「医療助言、症状診断、治療法、医療従事者による
指示の提供」が該当する。Oikomi が提供するのは:

- HealthKit から取得した HRV / 安静時心拍 / 睡眠データの **表示**
  → ユーザーが自分のデータを参照する、Apple Watch / ヘルスケアアプリと
    同等のフィットネス文脈
- AI コーチング（ディロード提案 / ボリューム警告 / PR 予測）
  → トレーニング負荷の調整提案、医学的診断ではない

これらは Apple Watch 本体・Apple Fitness+ と同じ「フィットネス情報」の
カテゴリで、いずれも 4+ レーティング。

加えてストア説明文・利用規約に **医療上の免責** を明記:

> 本アプリは健康・フィットネス情報を提供するもので、医療助言ではありません。
> 体調に不安がある場合は医師にご相談ください。

レビューで医療助言とみなされる懸念は低い。

---

## なぜ Kids Category を申請しないか

- ターゲットは中〜上級者（仕様書 §2.2）
- Pro サブスクリプション課金が中心 → Kids Category の制約（広告・課金規制）と
  相容れない
- App Tracking Transparency 等の Kids 専用要件が増えるが Oikomi には不要
- プライバシーポリシー §6 で 13 歳以上推奨

通常レーティング 4+ で公開し、Kids Category 申請は行わない。

---

## ASC 操作手順

1. App Store Connect → My Apps → Oikomi
2. 左サイドバー "App Information"
3. "Age Rating" の "Edit" ボタン
4. 上記表に従って 14 項目を None / No で回答
5. "Done" → 自動で **4+** が表示される

---

## 提出後の更新タイミング

Age Rating 質問票は **アプリの実装内容が変わるたびに見直す**:

- v1.1 で生理周期連携を追加 → 同じく 4+ で問題なし（フィットネス文脈）
- v1.2 で自然言語サマリを追加 → 出力内容が医療助言に踏み込まないことを確認
- v2.0 で SharePlay 等を追加 → "Unrestricted Web Access" 等を再評価

新バージョン申請時に ASC が再確認を求めない限り、変更不要。

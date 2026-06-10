# App Store Connect 入力テキスト (v1.0)

最終更新: 2026-05-27
配信地域: 日本 (v1.0 ローンチ時点)

各セクションを App Store Connect の対応フィールドにコピペ。
文字数は ASC のカウント (見える文字数) に準拠。

---

## App Name (30 字)

```
Oikomi - 追い込み筋トレ記録
```

(15 字 / 商標衝突回避のため記号付き)

別案:

```
Oikomi（追い込み）筋トレ記録
```

(15 字 / ブランド第一案)

---

## Subtitle (30 字)

```
体調に合わせて追い込む筋トレ記録
```

(15 字 / 採用案)

> ⚠️ 5.2.5 (知的財産) 対応: サブタイトル・キーワードに Apple 製品名
> (iPhone / Apple Watch / Watch) を入れないこと。2026-06-03 のリジェクトは
> 旧サブタイトル「iPhoneで計画、Watchで追い込む」が原因。Description 本文や
> 対応デバイス欄での製品名言及 (機能説明) は許容される。

別案:

```
HRVと睡眠で読む筋トレ習慣
```

(13 字 / 専門用語あり)

```
孤独な追い込みのための筋トレ
```

(13 字 / ブランド哲学)

---

## Promotional Text (170 字 / 動的更新可)

```
スマホでルーティンを組み立て、ジムでは腕元のデバイスだけで追い込む筋トレ記録。HRV・睡眠・安静時心拍からオンデバイスAIが今日の負荷を提案。進行中はロック画面に常時表示。1RM自動計算、873種の種目ライブラリ。外部分析・広告・トラッキングは一切なし。処理は端末内で完結し、iCloud同期は任意（自分のiCloudのみ）。
```

(約 150 字)

> ⚠️ 2.3 (正確なメタデータ) / 5.1 (プライバシー) 対応: 旧文の「外部送信ゼロ」は
> Pro のオプトイン iCloud 同期と矛盾し、絶対的プライバシー主張として誤解を招く。
> 「外部分析・広告・トラッキングなし」「端末内で完結」「iCloud 同期は任意・自分の
> iCloud のみ」と Description 本文 (§プライバシー) と整合する正確な表現に修正。
>
> ⚠️ 5.2.5 (知的財産) 対応 (保守判断): Promotional Text は Description 系フィールドのため
> 製品名の機能説明使用は本来許容されるが、2026-06-03 のリジェクト経緯を踏まえ保守的に対応。
> ハードウェア製品名 (iPhone → スマホ / Apple Watch → 腕元のデバイス)、商標機能名
> (Live Activity → ロック画面に常時表示) を一般表現へ置換。「iCloud」は同期先を正確に
> 示す事実記載のため残置 (自社サービス名の事実言及は許容)。
> ※ 製品名を戻したい場合: Promotional Text 単体ではガイドライン上 iPhone / Apple Watch 表記も可。

---

## Description (4000 字)

```
■ iPhone で組み立て、Apple Watch で追い込む。本気のトレーニーのための記録アプリ

Oikomi は「追い込み」という名のとおり、中〜上級トレーニーが
セッションの質に集中できるよう設計された筋トレ記録アプリです。
家では iPhone でルーティンを組み立てて履歴を分析、ジムでは
Apple Watch だけでセットを記録。HRV と睡眠スコアを読み解く
コーチング、Apple 純正フレームワークだけで作られたプライバシー設計。
孤独に重ねた一本を、確実に積み上げます。


■ 主な特徴

◇ Apple Watch でジム記録、iPhone は持ち込まない
iPhone であらかじめルーティンを作成しておけば、ジムでは
Apple Watch だけでセッションを実行・記録できます。
Digital Crown でレップ・重量を素早く入力。1〜3 タップで 1 セット保存。
Live Activity / Dynamic Island で進行中のセット数・経過時間・
レストタイマーを常時表示。

◇ HRV と睡眠を読むスマートコーチング (Pro)
HealthKit から HRV / 安静時心拍数 / 睡眠スコアを読み取り、
回復状況に応じてディロード提案、過剰ボリュームの警告、
自己ベスト到達予測の 3 種のアドバイスをオンデバイスで生成します。
外部 LLM API は使用せず、すべて端末内で完結します。

◇ 873 種の種目ライブラリ
ジム種目を中心に、自重・ダンベル・バーベル・ケーブル・マシンの
全カテゴリを網羅。部位・器具・場所タグで検索でき、自作種目も追加可能。

◇ 1RM 自動計算と推定強度
Epley / Brzycki 式で重量×レップから 1RM を自動推定し、
種目別の自己ベスト履歴とトレンドを可視化します。

◇ ルーティン管理
プッシュ・プル・レッグなど、よく使うメニューをルーティンとして
保存。ワンタップでセッション開始、前回値を自動プリフィル。

◇ HealthKit 双方向連携
完了したワークアウトは HKWorkout として「ヘルスケア」に保存し、
Apple Watch のアクティビティリングに反映されます。
HRV・睡眠・体重・体脂肪率の読み取りは Pro プランで有効化。

◇ ウィジェット / Smart Stack
ロック画面・ホーム画面・Apple Watch の Smart Stack に
今週の達成日数・連続活動週数・直近 PR を表示。

◇ App Intents / Siri 入力
「Hey Siri、Oikomi にベンチプレス 80kg を 10 レップ記録」で
セッション開始から記録まで音声完結。


■ プライバシーへの本気

外部分析 SDK・広告ライブラリ・トラッキングは一切使用していません。
すべての処理は端末内で完結し、利用者の同意なしには
1 バイトも外部に送信されません。
iCloud 同期は Pro プラン限定のオプトイン機能で、Apple ID で
自動隔離されます。詳細はプライバシーポリシーをご覧ください。


■ Pro プランで使える機能

・HealthKit 読み取り (HRV / 安静時心拍 / 睡眠 / 体組成)
・AI コーチング 3 種 (ディロード / PR 予測 / ボリューム警告)
・高度な分析グラフ (部位別ボリューム / トレンド)
・ルーティン無制限 (無料は 5 つまで)
・カスタム種目無制限 (無料は 5 つまで)
・iCloud 同期 (複数デバイス間で同期)
・CSV データエクスポート
・初回 14 日間無料トライアル

・月額 ¥780 / 年額 ¥5,800 (実質 ¥483/月)
・サブスクリプションは購入確認時に Apple ID に課金されます
・期間終了 24 時間前までに自動更新をオフにしない限り更新されます
・解約は iOS「設定」→「自分の名前」→「サブスクリプション」から
・利用規約: https://bukamasedo.github.io/oikomi/legal/terms/
・プライバシーポリシー: https://bukamasedo.github.io/oikomi/legal/privacy/


■ 対応デバイス

iPhone (iOS 26 以降) / Apple Watch (watchOS 26 以降)


■ 医療上の免責

本アプリは健康・フィットネス情報を提供するもので、医療助言ではありません。
体調に不安がある場合は医師にご相談ください。
```

(約 1,520 字 / 上限 4,000 字)

---

## Keywords (100 字 / ASCII カンマ区切り or 日本語混在)

```
筋トレ,ワークアウト,記録,回復,HRV,睡眠,コーチング,ジム,フィットネス,1RM,ルーティン,ベンチプレス
```

(73 字)

> ⚠️ 5.2.5 (知的財産) 対応: キーワード欄に Apple 製品名・商標
> (Apple / Apple Watch / Watch / iPhone / Siri / HealthKit 等) を入れないこと。
> 旧キーワードの `AppleWatch` を削除し `回復` に差し替え。製品名は Description
> 本文・対応デバイス欄での機能説明のみ許容。

別案 (英語 ASO 用、英語ロケール追加時):

```
workout,gym,strength,training,log,tracker,HRV,sleep,recovery,1RM,fitness,powerlifting
```

(83 字)

---

## What's New (4000 字 / バージョンごと)

App Store Connect の「このバージョンの最新情報 / What's New in This Version」に貼る本文。
**ロケールごとに別フィールド**なので、日本語ロケールには日本語、英語ロケールには英語を貼る。

### フォーマット規約（毎回この型に揃える）

1. **冒頭1行**: そのバージョンの目玉を一文で（見出し的に）
2. **セクション順**: `▼ 新機能` → `▼ 改善` → `▼ 不具合修正`（該当なしのセクションは丸ごと省略）
3. 各項目は `・`（日本語）/ `•`（英語）始まりの箇条書き。ユーザー視点の効能で書く（内部用語・コミット名・リファクタは載せない）
4. **末尾1行**: 感謝＋フィードバック誘導
5. ja と en は**同じ構成・同じ項目数**で対応させる（機械翻訳でなく自然な表現に）
6. 内部向け変更（レビュー依頼ゲート、リリース運用、docs/SPEC 更新、テスト等）は**載せない**
7. 出典は「前回リリースタグ `vX.Y.Z+N` 以降のコミット」。`feat:` = 新機能/改善、`fix:` = 不具合修正に振り分ける

新バージョンを出すたびに、この規約に沿った ja/en 対の `### vX.Y.Z` ブロックを下に追記する。

### v0.2.0

日本語ロケール:

```
英語に対応しました。設定からいつでも日本語／英語を切り替えられます。

▼ 新機能
・英語ローカライズに対応（日本語・英語の2言語）。種目名・コーチング文言・ウィジェット・Apple Watch まで全画面を翻訳
・設定画面に言語切り替えを追加

▼ 改善
・iPhone と Apple Watch を横断して表示文言を統一・最適化

▼ 不具合修正
・Apple Watch へルーティンを同期した際、受信側に未登録の種目が脱落することがある問題を修正

いつもオイコミをご利用いただきありがとうございます。ご意見・ご要望はぜひお寄せください。
```

英語ロケール:

```
Oikomi now speaks English. Switch between English and Japanese anytime from Settings.

New
• Full English localization — exercise names, coaching messages, widgets, and Apple Watch are all translated (Japanese & English)
• Language switcher added to Settings

Improvements
• Unified and refined wording across iPhone and Apple Watch

Bug Fixes
• Fixed an issue where exercises missing on the receiving device could be dropped when syncing a routine to Apple Watch

Thank you for using Oikomi. We'd love to hear your feedback!
```

### v1.0 初回リリース用

```
Oikomi 初回リリース

・Apple Watch でのセッション実行（iPhone でルーティン作成）
・Live Activity / Dynamic Island で進行中表示
・HealthKit 双方向連携 (HRV / 睡眠 / 体組成)
・AI コーチング 3 種 (ディロード / PR 予測 / ボリューム警告)
・873 種の種目ライブラリ
・ルーティン管理
・App Intents / Siri 入力
・iCloud 同期 (Pro)
・CSV データエクスポート (Pro)

フィードバックお待ちしています:
shu.hirouchi@gmail.com
```

(約 270 字)

---

## URLs

| 項目 | URL |
|---|---|
| Marketing URL (任意) | (空欄でも可。後日マーケサイト作成時に追加) |
| Support URL (必須) | `https://bukamasedo.github.io/oikomi/` |
| Privacy Policy URL | `https://bukamasedo.github.io/oikomi/legal/privacy/` |
| EULA (任意) | `https://bukamasedo.github.io/oikomi/legal/terms/` |

---

## App Review Information

### Sign-in 情報

```
本アプリはアカウント登録不要 (ローカル + CloudKit のみ)。レビュー用デモアカウントは不要。
HealthKit 権限はオンボーディングで「後で設定」を選んでもテスト可能。
```

### Contact Information

| 項目 | 入力 |
|---|---|
| First name | Shu |
| Last name | Hirouchi |
| Phone | (デベロッパープログラム登録時の電話番号) |
| Email | shu.hirouchi@gmail.com |

### Notes for the reviewer

```
ご審査ありがとうございます。

Oikomi は Apple Watch を主役とした筋トレ記録アプリです。
v1.0 では日本市場向けにリリースし、Pro サブスクリプションを
StoreKit 2 で提供します。

【主要機能の動作確認方法】

1. 基本記録 (Free)
   - 「トレーニング」タブ → クイック開始 → 種目選択
   - セット記録 (重量・レップ・完了)
   - 「終了」で HKWorkout として「ヘルスケア」に保存

2. ルーティン (Free 5 つまで / Pro 無制限)
   - 「トレーニング」タブ → 「+」ボタン → ルーティン名・種目・計画値を入力
   - ルーティンタップで前回値プリフィル付き開始

3. HealthKit 読み取り (Pro)
   - 設定 → HealthKit → 読み取り権限を許可
   - 「分析」タブ → コンディションで HRV / 睡眠 / 心拍を確認

4. AI コーチング (Pro)
   - 5 セッション以上のデータが蓄積されると「ホーム」タブにコーチング表示
   - HRV 低下・ボリューム急増・PR 到達予測の 3 種

5. iCloud 同期 (Pro)
   - 設定 → iCloud 同期トグル → 別デバイスでサインインで同期確認

【Pro 課金テスト】

Sandbox アカウントで以下フローを確認いただけます:
- 設定タブ「Pro にアップグレード」→ プラン選択 → 購入
- 14 日間無料トライアル付き
- 月額 / 年額アップグレード・ダウングレード対応 (同一 group)
- 「購入を復元」リンクで権利再取得確認可能

【プライバシー設計】

- 外部分析 SDK・トラッキングなし (Firebase / Sentry 等不採用)
- 全データは端末内 + Apple サービス (HealthKit / CloudKit) のみで処理
- 詳細: https://bukamasedo.github.io/oikomi/legal/privacy/

ご質問があれば shu.hirouchi@gmail.com までお問い合わせください。
```

---

## メモ・運用ルール

- **Promotional Text** はバージョン提出を伴わずに変更可能。月次でキャンペーン文言更新を想定
- **Description / Keywords** は新バージョン申請時に変更可能
- **App Name / Subtitle / Bundle ID** は変更時に Apple Review 経由が必要
- 英語ロケールは v2.0 で追加予定 (SPEC §8.2)
- スクリーンショットは別途撮影 (iPhone 17 Pro Max 6.9" / Apple Watch 49mm) — iPhone 専用なので iPad スクショは不要

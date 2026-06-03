# ホーム コーチングカード UI リファイン 設計

- 日付: 2026-06-03
- 対象: ホーム画面のコーチングカード（`CoachingGroupedView` 中心）
- 種別: UI リファイン（既存構造を維持したまま視覚品質を上げる）

## 背景・課題

ホームの「コーチング」カードは `CoachingGroupedView` でカテゴリ見出し＋「対象 … 指標」の小さな文字行を並べている。ユーザーフィードバックで挙がった課題は次の 3 点:

1. **重要度が伝わりにくい** — warning / info / success が caption サイズの小アイコンの違いだけ。一番大事な助言がパッと分からない。
2. **文字主体で地味** — 小さな文字行が並ぶだけで、色・余白・タイポの強弱が弱い。
3. **数値の変化が掴めない** — 「先週比 38%」「85kg 狙い」などの数値はあるが、推移グラフが無く傾向が見えない。

方向性（ユーザー確定）: **今のカテゴリ・グルーピング構造は維持**し、色・余白・タイポ・要所のグラフで質を上げる。影響範囲は小さく安全に。グラフは要所だけ控えめに。

## 全体方針

- カード内グルーピング構造（カテゴリ見出し＋対象行）は維持する。
- OikomiKit への変更は **後方互換の追加のみ**（既存呼び出し・テストを壊さない）。
- グラフは **PR予測・停滞の推定1RMスパークラインのみ**。ボリューム推移の週次スパークラインは今回のスコープに含めない（控えめ優先）。

## 設計

### A. 重要度を効かせる（severity hierarchy）

- 各グループ先頭に **severity バッジタイル** を置く。
  - 仕様: ≈30pt の角丸正方形（`OikomiRadius.tile`）、`severity.coachingTint` を 0.16 程度で塗り、塗りつぶしアイコン（`severity.coachingIconName`）を全 tint で中央配置。
  - 既存のルーティン行 / 再開カードのアイコンタイルと同じイディオム（`RoundedRectangle.fill(tint.opacity(...))` + `Image`）。
  - 現在の caption サイズのインライン小アイコンを置き換える。
- 複数対象を持つグループには **件数チップ**（小さな tinted カプセル、例 "3"）をタイトル右に表示する。1 件のみのグループには出さない。

### B. 文字主体からの脱却（polish）

- 対象行（`subject` あり）:
  - `subject` は `.subheadline` primary（現状維持）。
  - `detail`（"先週比 38%" / "85kg 狙い"）を **tinted カプセル pill ＋ `.monospacedDigit()`** にして数値を立たせる。pill の色は severity tint の淡色。
- グループ間の区切り: 素の全幅 `Divider()` をやめ、**余白＋インセットの細いヘアライン**（左端をバッジ幅ぶんインセット）にして「1 枚のカード内の独立ブロック」感を出す。
- 対象なしの助言（回復・体組成フェーズなど `subject == nil`）: バッジが視覚アンカーになる。`message` 文はそのまま表示（現状維持）。

### C. 要所だけのグラフ（控えめ）

- `CoachingAdvice` に **optional `trend: [Double]?`** を追加（デフォルト `nil` ＝ 完全後方互換。既存の全 `init` 呼び出しは引数省略で従来どおり）。
  - 意味: 表示用の時系列（古い順）。2 点未満ならグラフ非表示。
  - 値の単位は「推定1RM（kg）」とする。UI 側で表示単位へ変換する（PR ハイライトと同じ方針）。
- 系列を埋めるのは **PR予測（`prPredictions`）・停滞（`plateauAdvice`）** の助言のみ。
  - 既存の `Analytics.estimatedOneRMSeries(sets:forExerciseId:)` で対象種目の推定1RM系列を計算して `trend` に格納（kg のまま。UI で変換）。
  - これ以外のジェネレータ（ディロード・ボリューム・回復・漸進・体組成・RPE）は `trend = nil` のまま。
- 表示は `PRHighlightRow` のスパークライン描画を **`MiniSparkline` 共有コンポーネントに抽出** して再利用する。
  - `MiniSparkline`: `series: [Double]`、`tint: Color`、描画は AreaMark + LineMark(catmullRom) + 末尾 PointMark、軸非表示（現 `PRHighlightRow.sparkline` と同等）。
  - `PRHighlightRow` は自前スパークラインを `MiniSparkline` 利用に置き換える（重複排除・見た目は不変）。
  - `CoachingGroupedView` の対象行で `trend` があるとき、行末に小さめの `MiniSparkline`（幅 ≈56–72pt、高さ ≈28–34pt）を表示する。`trend` が無い行には何も出さない（PR カードのような固定幅列揃えは不要）。

### D. セクションヘッダ

- "コーチング" + `sparkles` + "すべて見る" の構造は維持（変更なし）。

## 影響ファイル

- `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`
  - `CoachingAdvice` に `trend: [Double]?`（デフォルト nil）を追加。
  - `prPredictions` / `plateauAdvice` が対象種目の推定1RM系列を `trend` に付与。
- `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`（または該当テスト）
  - PR予測・停滞の助言に `trend` が付与されること、他ジェネレータは nil のままであることのテストを追加。
- `App/iOS/DesignSystem/Components/MiniSparkline.swift`（新規）
  - `PRHighlightRow` から抽出した共有スパークライン。
- `App/iOS/DesignSystem/Components/CoachingGroupedView.swift`
  - severity バッジタイル / 件数チップ / detail pill / インセットヘアライン / 行末スパークラインを実装。
- `App/iOS/DesignSystem/Components/PRHighlightCard.swift`
  - 自前スパークラインを `MiniSparkline` 利用に置換（見た目不変）。

## 後方互換・リスク

- `CoachingAdvice.trend` はデフォルト nil の追加プロパティ。既存の生成・テスト・`CoachingChip` / `CoachingListView` 表示は影響を受けない。
- `MiniSparkline` 抽出は `PRHighlightRow` の見た目を変えないリファクタ。抽出後にホームの PR ハイライトが従来どおり描画されることを確認する。
- ローカライズ: 件数チップなど新規文字列が出る場合は `Localizable.xcstrings` に集約（直書き禁止）。数値のみのチップは文字列リソース不要。

## テスト / 検証

- OikomiKit ユニットテスト（PR予測・停滞に `trend` 付与 / 他は nil / 系列が古い順）。
- ビルド（iOS シミュレータ）通過。
- ホーム画面で warning/info/success が色面で識別でき、PR予測行に 1RM スパークラインが出ること、detail が pill で数値が立つことを目視確認。

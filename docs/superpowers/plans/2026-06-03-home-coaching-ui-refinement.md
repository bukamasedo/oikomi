# ホーム コーチングカード UI リファイン Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ホームの「コーチング」カードを、構造を維持したまま severity の色面・余白・タイポと要所の推定1RMスパークラインで視覚的に分かりやすくする。

**Architecture:** OikomiKit の `CoachingAdvice` に後方互換の optional `trend: [Double]?` を追加し、PR予測・停滞ジェネレータだけが推定1RM系列（kg）を付与する。UI 側は `PRHighlightRow` のスパークラインを `MiniSparkline` 共有コンポーネントに抽出し、`CoachingGroupedView` で severity バッジタイル・件数チップ・detail pill・インセットヘアライン・行末スパークラインとして使う。

**Tech Stack:** Swift / SwiftUI / Swift Charts / Swift Testing (`import Testing`) / SwiftData。

設計の一次ソース: `docs/superpowers/specs/2026-06-03-home-coaching-ui-refinement-design.md`

---

## File Structure

- `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`
  - `CoachingAdvice` に `trend: [Double]?`（kg 系列・古い順、デフォルト nil）を追加。
  - `prPredictions` / `plateauAdvice` が対象種目の推定1RM系列を付与。
- `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`
  - PR予測・停滞の trend 付与テストを追加。
- `App/iOS/DesignSystem/Components/MiniSparkline.swift`（新規）
  - `PRHighlightRow` から抽出する共有スパークライン。
- `App/iOS/DesignSystem/Components/PRHighlightCard.swift`
  - 自前スパークラインを `MiniSparkline` 利用に置換（見た目不変）。
- `App/iOS/DesignSystem/Components/CoachingGroupedView.swift`
  - severity バッジタイル / 件数チップ / detail pill / インセットヘアライン / 行末スパークラインを実装。`weightUnit` を受け取る。
- `App/iOS/Views/CoachingListView.swift`
  - `weightUnit` を受け取り `CoachingGroupedView` へ渡す。
- `App/iOS/Views/HomeView.swift`
  - `CoachingGroupedView` / `CoachingListView` に `weightUnit` を渡す。

---

## Task 1: `CoachingAdvice.trend` 追加と PR予測・停滞ジェネレータの系列付与

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: 失敗するテストを追加**

`AnalyticsTests.swift` の `// MARK: - plateauAdvice` セクションの直前（`@Test("prPredictions: 予測メッセージに信頼レンジ...` テストの後ろ、`676` 行付近の `// MARK: - plateauAdvice` の手前）に次の 2 テストを追加する:

```swift
    @Test("prPredictions: 予測 advice に推定1RMトレンド系列が付与される")
    func prPredictionCarriesTrend() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        let cal = Self.calendar
        let now = Date()
        for offset in 0..<5 {
            let weight = Double(80 + offset)
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: weight, reps: 8, completedAt: date)
            session.endedAt = date
        }

        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let predictions = Analytics.prPredictions(sets: allSets, records: records)

        let trend = try #require(predictions.first?.trend)
        #expect(trend.count >= 2)
        // 古い順（昇順トレンド）で末尾が最大付近
        #expect(trend.last == trend.max())
    }

    @Test("plateauAdvice: 停滞 advice に推定1RMトレンド系列が付与される")
    func plateauCarriesTrend() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)

        // 横ばい 5 セッション → 停滞 advice 発火
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -(4 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8, completedAt: date)
            session.endedAt = date
        }

        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.plateauAdvice(sets: allSets, records: records)

        let trend = try #require(advices.first?.trend)
        #expect(trend.count >= 2)
    }
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `swift test --package-path Packages/OikomiKit --filter "prPredictionCarriesTrend|plateauCarriesTrend"`
Expected: コンパイルエラー `value of type 'CoachingAdvice' has no member 'trend'`（`trend` 未定義のため）。

- [ ] **Step 3: `CoachingAdvice` に `trend` を追加**

`Analytics.swift` の `public struct CoachingAdvice` を編集する。`detail` プロパティ宣言の直後に次を追加:

```swift
    /// 推定1RM(kg) の時系列（古い順）。PR予測・停滞など傾向を示せる助言にのみ付与し、
    /// それ以外は nil。UI 側で表示単位へ変換してスパークライン表示する。2 点未満ならグラフ非表示。
    public let trend: [Double]?
```

`public init(...)` のシグネチャに `trend` 引数を追加する。`detail: String? = nil` の後ろに:

```swift
        detail: String? = nil,
        trend: [Double]? = nil
```

`init` 本文末尾（`self.detail = detail` の後）に:

```swift
        self.trend = trend
```

- [ ] **Step 4: `prPredictions` で系列を付与**

`prPredictions` 内の `return predictions.map { p in CoachingAdvice(...) }` の `CoachingAdvice` 生成に `trend` を追加する。`detail: "\(WeightFormatter.oneRM(kilograms: p.predictedOneRM, in: weightUnit)) 狙い"` の行の後ろにカンマを付け、次を追加:

```swift
                trend: sessionMaxEstimateSeries(
                    sets: sets, forExerciseId: p.exerciseId, windowSize: windowSize)
```

- [ ] **Step 5: `plateauAdvice` で系列を付与**

`plateauAdvice` 内ではループ先頭で既に `let maxes = sessionMaxEstimateSeries(...)` を計算している。`CoachingAdvice` 生成の `detail: "横ばい \(points.count) 回"` の行の後ろにカンマを付け、次を追加:

```swift
                    trend: maxes
```

- [ ] **Step 6: テストが通ることを確認**

Run: `swift test --package-path Packages/OikomiKit --filter "prPredictionCarriesTrend|plateauCarriesTrend"`
Expected: 2 テスト PASS。

- [ ] **Step 7: 既存テストの非回帰を確認**

Run: `swift test --package-path Packages/OikomiKit`
Expected: 全テスト PASS（`trend` はデフォルト nil の追加なので既存テストに影響なし）。

- [ ] **Step 8: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): CoachingAdvice に trend を追加し PR予測・停滞へ推定1RM系列を付与

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `MiniSparkline` 共有コンポーネントの抽出

**Files:**
- Create: `App/iOS/DesignSystem/Components/MiniSparkline.swift`
- Modify: `App/iOS/DesignSystem/Components/PRHighlightCard.swift`

- [ ] **Step 1: `MiniSparkline.swift` を作成**

`App/iOS/DesignSystem/Components/MiniSparkline.swift` を新規作成し、`PRHighlightRow.sparkline` の描画ロジックをそのまま移植する:

```swift
import Charts
import OikomiKit
import SwiftUI

/// 軸を持たないミニ・スパークライン。推定1RM 推移などの短い時系列を
/// AreaMark + LineMark（catmullRom）+ 末尾 PointMark で描く。
/// ホームの自己ベストカードとコーチングカードで共有する（枠・サイズは呼び出し側が `.frame` で与える）。
struct MiniSparkline: View {

    /// 表示単位へ変換済みの時系列（古い順）。2 点未満では呼び出し側が出さない前提。
    let series: [Double]
    var tint: Color = OikomiColor.brandSecondary

    var body: some View {
        let lo = series.min() ?? 0
        let hi = series.max() ?? 1
        // 平坦な系列でも線が潰れないよう上下に余白を与える。
        let pad = max((hi - lo) * 0.18, 0.5)
        let points = Array(series.enumerated())
        Chart {
            ForEach(points, id: \.offset) { index, value in
                AreaMark(
                    x: .value("回", index),
                    yStart: .value("ベース", lo - pad),
                    yEnd: .value("推定1RM", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint.opacity(0.22), tint.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom))

                LineMark(
                    x: .value("回", index),
                    y: .value("推定1RM", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            if let lastValue = series.last {
                PointMark(
                    x: .value("回", points.count - 1),
                    y: .value("推定1RM", lastValue)
                )
                .foregroundStyle(tint)
                .symbolSize(26)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (lo - pad)...(hi + pad))
        .accessibilityLabel("推定1RM の推移グラフ")
    }
}

#Preview {
    MiniSparkline(series: [78, 80, 82, 81, 88, 90, 95])
        .frame(width: 72, height: 34)
        .padding()
        .background(OikomiColor.appBackground)
}
```

- [ ] **Step 2: `PRHighlightRow` を `MiniSparkline` 利用に置換**

`PRHighlightCard.swift` の `body` 内、スパークライン列の `if series.count >= 2 { sparkline }` を次に変更する:

```swift
            Group {
                if series.count >= 2 {
                    MiniSparkline(series: series, tint: tint)
                } else {
                    Color.clear
                }
            }
            .frame(width: PRHighlightRow.chartWidth, height: 34)
```

そして `PRHighlightCard.swift` から `private var sparkline: some View { ... }` 計算プロパティ全体を削除する（`MiniSparkline` へ移植済みのため）。`import Charts` は他で使っていなければ削除可。`PRHighlightRow.chartWidth` / `valueWidth` の `static let` は残す。

- [ ] **Step 3: ビルドして見た目不変を確認**

Run: `/build`（iOS シミュレータ向けビルド）
Expected: BUILD SUCCEEDED。エラーが出る場合は `import Charts` 削除の戻しや残存 `sparkline` 参照を確認。

- [ ] **Step 4: コミット**

```bash
git add App/iOS/DesignSystem/Components/MiniSparkline.swift App/iOS/DesignSystem/Components/PRHighlightCard.swift
git commit -m "refactor(ui): スパークラインを MiniSparkline コンポーネントへ抽出

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `CoachingGroupedView` のリファイン（バッジ・チップ・pill・ヘアライン・スパークライン）

**Files:**
- Modify: `App/iOS/DesignSystem/Components/CoachingGroupedView.swift`
- Modify: `App/iOS/Views/CoachingListView.swift`
- Modify: `App/iOS/Views/HomeView.swift`

- [ ] **Step 1: `CoachingGroupedView` に `weightUnit` を追加**

`CoachingGroupedView` の `var maxItemsPerGroup: Int? = nil` の下に追加:

```swift
    /// `trend`（kg 系列）をスパークライン表示する際の変換先単位。ホームから渡す。
    var weightUnit: WeightUnit = .kg
```

- [ ] **Step 2: グループ間の区切りをインセットヘアラインに変更**

`body` の `ForEach` 内、`if index > 0 { Divider() }` を次に置き換える:

```swift
                if index > 0 {
                    Rectangle()
                        .fill(OikomiColor.separator.opacity(0.6))
                        .frame(height: 1)
                        .padding(.leading, 42)
                        .padding(.vertical, OikomiSpacing.xs)
                }
```

- [ ] **Step 3: グループ見出しを severity バッジタイル＋件数チップに変更**

`groupView(_:)` 内の見出し HStack（`HStack(spacing: OikomiSpacing.xs) { Image(...) ; Text(group.title) ... }`）を次に置き換える:

```swift
            // カテゴリ見出し: severity 色のバッジタイル＋タイトル＋（複数なら）件数チップ。
            HStack(spacing: OikomiSpacing.s) {
                ZStack {
                    RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                        .fill(group.severity.coachingTint.opacity(0.16))
                    Image(systemName: group.severity.coachingIconName)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(group.severity.coachingTint)
                }
                .frame(width: 30, height: 30)

                Text(group.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if group.items.count > 1 {
                    Text("\(group.items.count)")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(group.severity.coachingTint)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(group.severity.coachingTint.opacity(0.14), in: Capsule())
                }

                Spacer(minLength: 0)
            }
```

また `groupView` 内 `VStack(alignment: .leading, spacing: OikomiSpacing.xs)` の spacing を `OikomiSpacing.s` に変更し、バッジと行に余白を持たせる。

- [ ] **Step 4: 対象行に detail pill と行末スパークラインを実装**

`itemRow(_:)` の `if let subject = item.subject { ... }` ブランチ（HStack 全体）を次に置き換える:

```swift
        if let subject = item.subject {
            HStack(alignment: .center, spacing: OikomiSpacing.s) {
                Text(subject)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: OikomiSpacing.s)

                if let trend = item.trend, trend.count >= 2 {
                    MiniSparkline(
                        series: trend.map { weightUnit.fromKilograms($0) },
                        tint: item.severity.coachingTint
                    )
                    .frame(width: 52, height: 22)
                }

                if let detail = item.detail {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(item.severity.coachingTint)
                        .lineLimit(1)
                        .padding(.horizontal, OikomiSpacing.s)
                        .padding(.vertical, 3)
                        .background(item.severity.coachingTint.opacity(0.12), in: Capsule())
                }
            }
        } else {
```

（`else { Text(item.message)... }` ブランチはそのまま残す。）

- [ ] **Step 5: `CoachingListView` に `weightUnit` を通す**

`CoachingListView.swift` の `struct CoachingListView: View {` 直後（`advice` プロパティの近く）に追加:

```swift
    var weightUnit: WeightUnit = .kg
```

`CoachingGroupedView(groups: Analytics.groupedCoaching(advice))` を次に変更:

```swift
                CoachingGroupedView(
                    groups: Analytics.groupedCoaching(advice), weightUnit: weightUnit)
```

`CoachingListView.swift` の冒頭に `import OikomiKit` が無ければ追加する（`WeightUnit` 参照のため。既存なら不要）。

- [ ] **Step 6: `HomeView` の呼び出しに `weightUnit` を渡す**

`HomeView.swift` の `coachingSection` 内:

`CoachingGroupedView(groups: shownGroups, maxItemsPerGroup: homeItemCap)` を次に変更:

```swift
            CoachingGroupedView(
                groups: shownGroups, maxItemsPerGroup: homeItemCap, weightUnit: weightUnit)
```

同 `coachingSection` 内の `CoachingListView(advice: allCoaching)` を次に変更:

```swift
                        CoachingListView(advice: allCoaching, weightUnit: weightUnit)
```

- [ ] **Step 7: ビルド**

Run: `/build`
Expected: BUILD SUCCEEDED。

- [ ] **Step 8: コミット**

```bash
git add App/iOS/DesignSystem/Components/CoachingGroupedView.swift App/iOS/Views/CoachingListView.swift App/iOS/Views/HomeView.swift
git commit -m "feat(home): コーチングカードを severity バッジ・detail pill・推定1RMスパークラインで刷新

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: 整形・最終ビルド・目視検証

**Files:** （変更なし。検証のみ）

- [ ] **Step 1: フォーマット**

Run: `/format`
Expected: 変更ファイルが swift-format 整形済みになる（差分が出たら次ステップでコミット）。

- [ ] **Step 2: lint**

Run: `/lint`
Expected: 違反なし。

- [ ] **Step 3: 最終ビルド & 全テスト**

Run: `/build` および `swift test --package-path Packages/OikomiKit`
Expected: BUILD SUCCEEDED / 全テスト PASS。

- [ ] **Step 4: シミュレータで目視確認**

Run: `/sim-run`
確認項目:
- コーチングカードで warning（橙）/ info（青）/ success（緑）がバッジの色面でひと目で識別できる。
- 複数対象のグループにタイトル右の件数チップが出る。
- detail（"先週比 38%" 等）が severity 色の pill で数値が立って見える。
- PR予測・停滞の行に推定1RM スパークラインが表示される（他の助言行には出ない）。
- 「直近の自己ベスト」カードのスパークラインが従来どおり描画される（MiniSparkline 抽出の非回帰）。

- [ ] **Step 5: 整形差分があればコミット**

```bash
git add -A
git commit -m "style: swift-format 整形

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

（差分が無ければスキップ。）

---

## Self-Review メモ

- **Spec coverage:** A（severity hierarchy）→ Task 3 Step 3 バッジ＋件数チップ。B（pill・ヘアライン）→ Task 3 Step 2/4。C（trend + MiniSparkline）→ Task 1（データ）+ Task 2（抽出）+ Task 3 Step 4（表示）。D（ヘッダ維持）→ 変更なしで担保。後方互換 → Task 1 で optional nil 追加・Step 7 で非回帰確認。
- **型整合:** `trend: [Double]?`(kg) を Task 1 で定義 → Task 3 Step 4 で `weightUnit.fromKilograms` 変換して `MiniSparkline(series:tint:)` に渡す。`MiniSparkline` の API は Task 2 で定義。`CoachingGroupedView.weightUnit` / `CoachingListView.weightUnit` の型は `WeightUnit`。
- **Placeholder スキャン:** 各コード手順に実コードを記載済み。曖昧表現なし。

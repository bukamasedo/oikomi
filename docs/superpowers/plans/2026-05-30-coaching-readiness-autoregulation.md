# コーチング拡充 Spec 1（レディネス & オートレギュレーション中核）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Oikomi のオンデバイス・コーチングに「コンディション総合スコア（HRV z-score 主）」「RPE オートレギュレーション」「PR 予測の高度化（RIR補正・停滞検出・信頼レンジ）」を追加し、Pro コーチングの中核を強化する。

**Architecture:** ビジネスロジックは `OikomiKit/Coaching` の純粋関数として実装（TDD・テスト容易）。HealthKit I/O は `HealthStore` の薄いラッパー1本に閉じ込め、UI（HomeView / TodayConditionCard）は計算済みの値を受け取って表示するだけにする。`ReadinessScore` は `[HealthTrendPoint]` 系列を入力に取る純粋計算で、Apple Watch 無し・非 Apple Intelligence 機種でも graceful に縮退する。

**Tech Stack:** Swift / SwiftData / Swift Testing（`import Testing`, `@Suite`, `@Test`, `#expect`）/ HealthKit（既存 `HealthStore` 経由）。テスト実行: `swift test --package-path Packages/OikomiKit`。ビルド: `/build`。整形: `/format`、lint: `/lint`。

---

## ファイル構成（責務）

| 区分 | パス | 責務 |
|---|---|---|
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/ReadinessScore.swift` | コンディション総合スコアの値型と純粋計算（z-score / 重み合成 / 部分入力 / confidence / ソースラベル） |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/OneRepMax.swift` | `estimate(weight:reps:rpe:)` 追加（レップ域別式 + RIR 補正）。既存 `epley/brzycki/best` は不変 |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift` | `readinessAdvice` 追加・`deloadAdvice` シグネチャ変更・`autoregulationAdvice` 追加・`prPredictions` 改修・`plateauAdvice` 追加・共有ヘルパー `sessionMaxEstimateSeries` 抽出 |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Models/HealthSnapshot.swift` | `readinessScore: Int?` フィールド追加（予約。populate は Spec 2 で行う） |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift` | `readinessSnapshot(referenceDate:calendar:) async -> ReadinessScore?` 薄い I/O ラッパー追加 |
| 改修 | `App/iOS/Views/HomeView.swift` | readiness を1回計算し、`deloadAdvice`/`autoregulationAdvice`/`plateauAdvice` を集約、`TodayConditionCard` に readiness を渡す |
| 改修 | `App/iOS/Views/Components/TodayConditionCard.swift` | 総合スコア + データソース注記の表示（`readiness` を受け取る） |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/ReadinessScoreTests.swift` | ReadinessScore の単体テスト |
| 改修 | `Packages/OikomiKit/Tests/OikomiKitTests/OneRepMaxTests.swift` | `estimate` のテスト追加 |
| 改修 | `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift` | readinessAdvice / deloadAdvice 移行 / autoregulation / prPredictions / plateau のテスト |
| 改修 | `docs/SPEC.md` | §4.2.2 を先行更新 |

### スコープ補足（設計書からの調整・YAGNI）
- **`readinessScore` の永続化（populate）は Spec 1 では行わない**。フィールドだけ追加し（`menstrualPhaseRawValue` と同じ「予約フィールド」パターン）、実際の書き込み・相関利用は Spec 2 に回す。理由: 書き込みには session 開始パスへの 60 日系列フェッチ追加が必要で、Spec 1 では何も読まないため。Spec 1 の readiness は UI で都度算出する。
- **`deloadAdvice` の `hrvSeries` 引数は `readiness` に置換**する（一本化）。唯一の呼び出し元は `HomeView.swift:73`。通知スケジューラは `deloadAdvice` を呼ばない（`prPredictions` のみ呼ぶ＝シグネチャ不変なので影響なし）。
- **通知（CoachingNotificationScheduler）の readiness 連動はこのスペックに含めない**（既存の HRV 通知ロジックは現状維持）。後続スペック/B で扱う。

---

## Task 1: `OneRepMax.estimate(weight:reps:rpe:)`

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/OneRepMax.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/OneRepMaxTests.swift`

- [ ] **Step 1: Write the failing tests**

`OneRepMaxTests.swift` の `struct OneRepMaxTests { ... }` 内（末尾の `}` 直前）に追記:

```swift
    @Test("estimate: rpe=nil・8レップは Brzycki を使う（6〜12 域）")
    func estimateMidRepUsesBrzycki() {
        // Brzycki(80,8) = 80*36/(37-8) = 99.310...
        let result = OneRepMax.estimate(weight: 80, reps: 8, rpe: nil)
        #expect(abs(result - 99.310) < 0.01)
    }

    @Test("estimate: rpe=nil・3レップは Epley を使う（1〜5 域）")
    func estimateLowRepUsesEpley() {
        // Epley(100,3) = 100*(1+3/30) = 110
        let result = OneRepMax.estimate(weight: 100, reps: 3, rpe: nil)
        #expect(abs(result - 110.0) < 0.01)
    }

    @Test("estimate: RPE8(RIR2) は実効レップ +2 で推定する")
    func estimateRIRAdjustment() {
        // (100kg, 5reps, RPE8) → effectiveReps 7 → Brzycki(100,7) = 100*36/30 = 120
        let result = OneRepMax.estimate(weight: 100, reps: 5, rpe: 8)
        #expect(abs(result - 120.0) < 0.01)
    }

    @Test("estimate: 不正入力は 0")
    func estimateInvalid() {
        #expect(OneRepMax.estimate(weight: 0, reps: 5, rpe: nil) == 0)
        #expect(OneRepMax.estimate(weight: 100, reps: 0, rpe: nil) == 0)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter OneRepMax`
Expected: コンパイルエラー（`estimate` 未定義）。

- [ ] **Step 3: Implement `estimate`**

`OneRepMax.swift` の `relativeIntensity(...)` メソッドの直後（`enum OneRepMax` 内の閉じ `}` の前）に追加:

```swift
    /// レップ域に応じた式選択 + RIR 補正つきの 1RM 推定。
    ///
    /// - RIR 補正: 実効レップ = reps + (10 - rpe)。RPE8(RIR2) のセットは「あと2レップ可能」とみなす。
    ///   rpe が nil のときは reps をそのまま使う（既存挙動互換）。
    /// - 式選択: 実効レップ 1〜5 → Epley、6 以上 → Brzycki（高レップで精度が落ちる Epley を避ける）。
    public static func estimate(weight: Double, reps: Int, rpe: Double?) -> Double {
        guard reps >= 1, weight > 0 else { return 0 }
        let rir = rpe.map { Int((10.0 - $0).rounded()) } ?? 0
        let effectiveReps = max(1, reps + max(0, rir))
        if effectiveReps <= 5 {
            return epley(weight: weight, reps: effectiveReps)
        }
        return brzycki(weight: weight, reps: effectiveReps)
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter OneRepMax`
Expected: PASS（既存 + 新規4件）。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/OneRepMax.swift Packages/OikomiKit/Tests/OikomiKitTests/OneRepMaxTests.swift
git commit -m "feat(coaching): OneRepMax.estimate にレップ域別式+RIR補正を追加"
```

---

## Task 2: `ReadinessScore` 値型と `compute`

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/ReadinessScore.swift`
- Create: `Packages/OikomiKit/Tests/OikomiKitTests/ReadinessScoreTests.swift`

- [ ] **Step 1: Write the failing tests**

新規 `ReadinessScoreTests.swift`:

```swift
import Foundation
import Testing

@testable import OikomiKit

@Suite("ReadinessScore")
struct ReadinessScoreTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }()

    /// 基準日から過去 `days` 日分、`baseline` 付近（±jitter）の系列を作り、最新日だけ `today` にする。
    private func series(today: Double, baseline: Double, jitter: Double, days: Int) -> [HealthTrendPoint] {
        let cal = Self.calendar
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 23))!
        var points: [HealthTrendPoint] = []
        for offset in 1..<days {
            let date = cal.date(byAdding: .day, value: -offset, to: now)!
            let v = baseline + (offset % 2 == 0 ? jitter : -jitter)
            points.append(HealthTrendPoint(date: date, value: v))
        }
        points.append(HealthTrendPoint(date: now, value: today))
        return points
    }

    private var referenceDate: Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 5, day: 23))!
    }

    @Test("compute: 信号が全く無ければ nil")
    func noSignalsReturnsNil() {
        let score = ReadinessScore.compute(
            hrvSeries: [], rhrSeries: [], sleepHours: nil,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score == nil)
    }

    @Test("compute: 睡眠のみ・6h は value 60・confidence low・ソース注記あり")
    func sleepOnly() {
        let score = ReadinessScore.compute(
            hrvSeries: [], rhrSeries: [], sleepHours: 6,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score?.value == 60)
        #expect(score?.confidence == .low)
        #expect(score?.band == .normal)
        #expect(score?.sourceNote != nil)
        #expect(score?.usedSignals == [.sleep])
    }

    @Test("compute: HRV が大きく低下していれば band は low")
    func lowHRVGivesLowBand() {
        // baseline≈60(±3), today=30 → z が強く負 → 低スコア
        let hrv = series(today: 30, baseline: 60, jitter: 3, days: 21)
        let score = ReadinessScore.compute(
            hrvSeries: hrv, rhrSeries: [], sleepHours: nil,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score?.band == .low)
        #expect((score?.hrvZ ?? 0) < -1)
    }

    @Test("compute: 3信号そろえば confidence high・ソース注記は nil")
    func threeSignalsHighConfidence() {
        let hrv = series(today: 62, baseline: 60, jitter: 3, days: 21)
        let rhr = series(today: 52, baseline: 52, jitter: 1, days: 21)
        let score = ReadinessScore.compute(
            hrvSeries: hrv, rhrSeries: rhr, sleepHours: 8,
            referenceDate: referenceDate, calendar: Self.calendar)
        #expect(score?.confidence == .high)
        #expect(score?.sourceNote == nil)
        #expect(score?.usedSignals.count == 3)
    }

    @Test("compute: 系列が 14 日未満なら HRV 成分は使わない")
    func insufficientHistorySkipsHRV() {
        let hrv = series(today: 30, baseline: 60, jitter: 3, days: 10)  // 10日 < 14
        let score = ReadinessScore.compute(
            hrvSeries: hrv, rhrSeries: [], sleepHours: 7,
            referenceDate: referenceDate, calendar: Self.calendar)
        // HRV は無視され、睡眠のみで算出される
        #expect(score?.usedSignals == [.sleep])
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter ReadinessScore`
Expected: コンパイルエラー（`ReadinessScore` 未定義）。

- [ ] **Step 3: Implement `ReadinessScore`**

新規 `ReadinessScore.swift`:

```swift
import Foundation

/// HRV・睡眠・安静時心拍を統合した「今日のコンディション（レディネス）」スコア。
///
/// すべて純粋関数。HealthKit I/O は持たず、`[HealthTrendPoint]` 系列と今日の睡眠時間を入力に取る。
/// Apple Watch 無し等で信号が欠ける場合は、利用可能な信号だけで重みを再配分して算出する（nil を 0 扱いしない）。
public struct ReadinessScore: Sendable, Hashable {

    public enum Band: String, Sendable { case low, normal, high }
    public enum Confidence: String, Sendable { case low, medium, high }
    public enum Signal: String, Sendable { case hrv, restingHeartRate, sleep }

    /// 0〜100。利用可能な信号のみで算出。
    public let value: Int
    public let band: Band
    public let confidence: Confidence
    /// HRV の z-score（将来の自然言語サマリ用・デバッグ用）。HRV 不使用時は nil。
    public let hrvZ: Double?
    public let usedSignals: [Signal]

    public init(value: Int, band: Band, confidence: Confidence, hrvZ: Double?, usedSignals: [Signal]) {
        self.value = value
        self.band = band
        self.confidence = confidence
        self.hrvZ = hrvZ
        self.usedSignals = usedSignals
    }

    /// UI に出すデータソース注記。3 信号そろい（confidence == .high）なら nil。
    public var sourceNote: String? {
        guard confidence != .high else { return nil }
        if usedSignals.isEmpty { return nil }
        if !usedSignals.contains(.hrv) {
            return "Apple Watch 未接続のため、利用可能なデータで算出しています。"
        }
        return "一部のデータが不足しているため、参考値です。"
    }

    // MARK: - 計算

    /// 重み（HRV 主）。将来 goal 別に差し替え可能なよう定数化。
    static let hrvWeight = 0.5
    static let sleepWeight = 0.3
    static let rhrWeight = 0.2

    /// レディネススコアを算出する。算出に使える信号が 1 つも無ければ nil。
    public static func compute(
        hrvSeries: [HealthTrendPoint],
        rhrSeries: [HealthTrendPoint],
        sleepHours: Double?,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ReadinessScore? {
        var subscores: [(signal: Signal, score: Double, weight: Double)] = []
        var hrvZValue: Double?

        // HRV: 高いほど良い
        if let z = zScore(series: hrvSeries) {
            hrvZValue = z
            subscores.append((.hrv, scoreFromZ(z), hrvWeight))
        }
        // 安静時心拍: 高いほど悪い → z を反転
        if let z = zScore(series: rhrSeries) {
            subscores.append((.restingHeartRate, scoreFromZ(-z), rhrWeight))
        }
        // 睡眠: 8h = 80 を基準に正規化（10h で 100 にキャップ）
        if let hours = sleepHours, hours > 0 {
            let s = min(min(hours / 8.0, 1.25) * 80.0, 100.0)
            subscores.append((.sleep, s, sleepWeight))
        }

        guard !subscores.isEmpty else { return nil }

        let totalWeight = subscores.reduce(0) { $0 + $1.weight }
        let weighted = subscores.reduce(0) { $0 + $1.score * $1.weight } / totalWeight
        let value = Int(weighted.rounded())

        // 暫定閾値（テストで調整可）
        let band: Band = value < 40 ? .low : (value < 70 ? .normal : .high)
        let confidence: Confidence =
            subscores.count >= 3 ? .high : (subscores.count == 2 ? .medium : .low)

        return ReadinessScore(
            value: value,
            band: band,
            confidence: confidence,
            hrvZ: hrvZValue,
            usedSignals: subscores.map(\.signal)
        )
    }

    /// 系列の「最新値 vs それ以前のベースライン」の z-score。
    /// 有効サンプル（value > 0）が 14 件未満、または SD が 0 のときは nil。
    static func zScore(series: [HealthTrendPoint]) -> Double? {
        let valid = series.filter { $0.value > 0 }.sorted { $0.date < $1.date }
        guard valid.count >= 14, let today = valid.last?.value else { return nil }
        let baseline = valid.dropLast().map(\.value)
        guard baseline.count >= 13 else { return nil }
        let mean = baseline.reduce(0, +) / Double(baseline.count)
        let variance = baseline.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(baseline.count)
        let sd = variance.squareRoot()
        guard sd > 0 else { return nil }
        return (today - mean) / sd
    }

    /// z-score を 0〜100 のサブスコアにマップ（z=0 → 50、z=±2 → 90/10、クランプ）。
    static func scoreFromZ(_ z: Double) -> Double {
        min(max(50.0 + z * 20.0, 0.0), 100.0)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter ReadinessScore`
Expected: PASS（5件）。

> 補足: `sleepOnly` の期待値 — 6h → `min(6/8,1.25)*80 = 60` → value 60、subscores 1件 → confidence .low、band は `40<=60<70` で .normal。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/ReadinessScore.swift Packages/OikomiKit/Tests/OikomiKitTests/ReadinessScoreTests.swift
git commit -m "feat(coaching): ReadinessScore（HRV z-score主のコンディション総合スコア）を追加"
```

---

## Task 3: `readinessAdvice(readiness:)`

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: Write the failing tests**

`AnalyticsTests.swift` の末尾 `}` の直前に、新しい MARK セクションとして追記:

```swift
    // MARK: - readinessAdvice

    @Test("readinessAdvice: low band で warning を返す")
    func readinessAdviceLow() {
        let r = ReadinessScore(value: 30, band: .low, confidence: .high, hrvZ: -1.5, usedSignals: [.hrv])
        let advice = Analytics.readinessAdvice(readiness: r)
        #expect(advice?.severity == .warning)
    }

    @Test("readinessAdvice: high band で success を返す")
    func readinessAdviceHigh() {
        let r = ReadinessScore(value: 85, band: .high, confidence: .high, hrvZ: 1.5, usedSignals: [.hrv])
        let advice = Analytics.readinessAdvice(readiness: r)
        #expect(advice?.severity == .success)
    }

    @Test("readinessAdvice: normal / nil では advice なし")
    func readinessAdviceNormalNil() {
        let r = ReadinessScore(value: 60, band: .normal, confidence: .high, hrvZ: 0, usedSignals: [.hrv])
        #expect(Analytics.readinessAdvice(readiness: r) == nil)
        #expect(Analytics.readinessAdvice(readiness: nil) == nil)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter AnalyticsTests`
Expected: コンパイルエラー（`readinessAdvice` 未定義）。

- [ ] **Step 3: Implement `readinessAdvice`**

`Analytics.swift` の `hrvDeloadAdvice(...)` メソッド全体を次の `readinessAdvice` に**置換**する（`hrvDeloadAdvice` は削除）:

```swift
    /// レディネススコアから単発の `CoachingAdvice` を生成する。
    ///
    /// low → 回復優先（warning）、high → PR 狙える日（success）、normal/nil → なし。
    static func readinessAdvice(readiness: ReadinessScore?) -> CoachingAdvice? {
        guard let readiness else { return nil }
        switch readiness.band {
        case .low:
            return CoachingAdvice(
                title: "今日は回復優先",
                message:
                    "コンディションスコアが \(readiness.value) と低めです。前回比 80% 程度の重量で軽めに組むことを検討してください。",
                severity: .warning,
                impact: Double(100 - readiness.value) * 100
            )
        case .high:
            return CoachingAdvice(
                title: "コンディション良好",
                message: "コンディションスコアが \(readiness.value) と好調です。PR を狙える日です。",
                severity: .success,
                impact: Double(readiness.value)
            )
        case .normal:
            return nil
        }
    }
```

- [ ] **Step 4: Run the tests to verify they pass (readinessAdvice のみ)**

Run: `swift test --package-path Packages/OikomiKit --filter readinessAdvice`
Expected: PASS（3件）。

> 注意: この時点で `deloadAdvice` 内が `hrvDeloadAdvice` を呼んでおりコンパイルが通らない。次の Task 4 で修正する。Task 3 の commit は Task 4 とまとめてよいが、ここでは `readinessAdvice` の実装だけ確認する。`deloadAdvice` の `hrvDeloadAdvice(...)` 呼び出しが残っていてビルドが赤い場合は Task 4 に直行する。

- [ ] **Step 5: （commit は Task 4 とまとめる）**

---

## Task 4: `deloadAdvice` を readiness ベースに変更 + 既存 HRV テスト移行

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift:198-272`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: 既存 HRV テスト3件を readiness ベースへ書き換え（失敗させる）**

`AnalyticsTests.swift` の `// MARK: - hrvDeloadAdvice` セクションの3テスト（`hrvDeloadFires` / `hrvDeloadStable` / `hrvDeloadInsufficientSamples`）を次の2テストに**置換**する:

```swift
    // MARK: - deloadAdvice × readiness

    @Test("deloadAdvice: readiness が low なら回復優先 advice を含む")
    func deloadIncludesReadinessLow() {
        let r = ReadinessScore(value: 30, band: .low, confidence: .high, hrvZ: -1.5, usedSignals: [.hrv])
        let advices = Analytics.deloadAdvice(
            sessions: [], sets: [], readiness: r, calendar: Self.calendar)
        #expect(advices.contains { $0.title.contains("回復優先") })
    }

    @Test("deloadAdvice: readiness が nil なら回復優先 advice は出ない")
    func deloadNoReadinessWhenNil() {
        let advices = Analytics.deloadAdvice(
            sessions: [], sets: [], readiness: nil, calendar: Self.calendar)
        #expect(!advices.contains { $0.title.contains("回復優先") })
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter AnalyticsTests`
Expected: コンパイルエラー（`deloadAdvice` が `readiness:` 引数を持たない / `hrvSeries:` を使う旧テストが消えた）。

- [ ] **Step 3: `deloadAdvice` のシグネチャと本体を変更**

`Analytics.swift` の `deloadAdvice` の宣言行（`hrvSeries: [HealthTrendPoint] = [],` を含む）を次に変更:

```swift
    public static func deloadAdvice(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        readiness: ReadinessScore? = nil,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
```

同メソッド内の「3) HRV 低下判定」ブロック（`if let advice = hrvDeloadAdvice(...) { advices.append(advice) }` の塊、コメント `// 3) HRV 低下判定...` から該当 `if let` まで）を次に**置換**:

```swift
        // 3) レディネス（HRV z-score 主・睡眠/安静時心拍 統合）判定
        if let advice = readinessAdvice(readiness: readiness) {
            advices.append(advice)
        }
```

ドキュメンテーションコメント（`/// HRV 系列は呼び出し側で...` の2行）も次に更新:

```swift
    /// レディネス（コンディション総合スコア）は呼び出し側で `HealthStore.readinessSnapshot()` を取得して渡す。
    /// Pro 未契約や HealthKit 未認可など readiness が nil の場合、レディネス判定はスキップして既存ロジックのみ動作する。
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter AnalyticsTests`
Expected: PASS。`deloadConsecutive5Days` / `deloadSingleDay` など既存テスト（`hrvSeries`/`readiness` を渡さない）はデフォルト引数で従来通り通る。

> 注意: `HomeView.swift:73` がまだ `hrvSeries:` を渡しておりアプリのビルドは赤いまま。OikomiKit のテストは緑。UI は Task 10 で直す。

- [ ] **Step 5: Commit（Task 3 + 4 まとめて）**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): ディロード判定をHRV単独からレディネス総合スコアへ一本化"
```

---

## Task 5: `autoregulationAdvice(sets:targetRPE:)`

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: Write the failing tests**

`AnalyticsTests.swift` の末尾 `}` の直前に追記:

```swift
    // MARK: - autoregulationAdvice

    /// 同一種目で指定 RPE のセットを N セッション分作るヘルパー。
    @discardableResult
    private func makeRPESessions(
        context: ModelContext, exercise: Exercise, weight: Double, rpe: Double, sessions: Int
    ) throws -> Void {
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<sessions {
            let date = cal.date(byAdding: .day, value: -(sessions - offset) * 2, to: now)!
            let s = try repo.startSession(at: date)
            let set = try repo.addSet(to: s, exercise: exercise, weight: weight, reps: 8, completedAt: date)
            set.rpe = rpe
            s.endedAt = date
        }
    }

    @Test("autoregulationAdvice: 直近2回とも RPE9 以上なら減量を提案")
    func autoregHighRPEDecrease() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 9.5, sessions: 2)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.contains { $0.title.contains("下げ") })
    }

    @Test("autoregulationAdvice: 直近2回とも RPE6 以下なら増量を提案")
    func autoregLowRPEIncrease() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 6.0, sessions: 2)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.contains { $0.title.contains("上げ") || $0.title.contains("増やし") })
    }

    @Test("autoregulationAdvice: RPE が適正（8前後）なら提案なし")
    func autoregMidRPENone() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 7.5, sessions: 2)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.isEmpty)
    }

    @Test("autoregulationAdvice: RPE 未入力なら提案なし")
    func autoregNoRPENone() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<2 {
            let date = cal.date(byAdding: .day, value: -(2 - offset) * 2, to: now)!
            let s = try repo.startSession(at: date)
            try repo.addSet(to: s, exercise: bench, weight: 100, reps: 8, completedAt: date)  // rpe nil
            s.endedAt = date
        }
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.isEmpty)
    }

    @Test("autoregulationAdvice: 1 セッションだけならデータ不足で提案なし")
    func autoregSingleSessionNone() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        try makeRPESessions(context: context, exercise: bench, weight: 100, rpe: 9.5, sessions: 1)

        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.autoregulationAdvice(sets: allSets, calendar: Self.calendar)
        #expect(advices.isEmpty)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter autoregulation`
Expected: コンパイルエラー（`autoregulationAdvice` 未定義）。

- [ ] **Step 3: Implement `autoregulationAdvice`**

`Analytics.swift` の `volumeAdvice(...)` メソッドの直後（`enum Analytics` 内の閉じ `}` の前）に追加:

```swift
    /// RPE オートレギュレーション（セッション間）。
    ///
    /// 種目ごとに直近 2 セッションの平均 RPE を見て、次回の推奨重量を提案する。
    /// - 直近 2 回とも RPE ≥ 9（重すぎ）→ 約 5% 減
    /// - 直近 2 回とも RPE ≤ 6（軽すぎ）→ 約 2.5% 増（漸進性過負荷）
    /// RPE 未入力の種目・データ不足（< 2 セッション）はスキップ。提案は読み取り専用。
    public static func autoregulationAdvice(
        sets: [SetRecord],
        targetRPE: Double = 8,
        minSessions: Int = 2,
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg
    ) -> [CoachingAdvice] {
        let working = sets.filter {
            !$0.isWarmup && $0.isCompleted && $0.rpe != nil && ($0.weight ?? 0) > 0
        }
        let byExercise = Dictionary(grouping: working) { $0.exercise?.id ?? UUID() }

        var advices: [CoachingAdvice] = []
        for (_, exSets) in byExercise {
            guard let exercise = exSets.first?.exercise else { continue }

            let bySession = Dictionary(grouping: exSets) { $0.session?.id ?? UUID() }
            let summaries =
                bySession.values
                .compactMap { s -> (date: Date, avgRPE: Double, topWeight: Double)? in
                    let rpes = s.compactMap(\.rpe)
                    guard !rpes.isEmpty, let date = s.map(\.completedAt).max() else { return nil }
                    let avg = rpes.reduce(0, +) / Double(rpes.count)
                    let topWeight = s.compactMap(\.weight).max() ?? 0
                    return (date, avg, topWeight)
                }
                .sorted { $0.date < $1.date }

            guard summaries.count >= minSessions else { continue }
            let recent = summaries.suffix(2)
            guard let lastWeight = recent.last?.topWeight, lastWeight > 0 else { continue }

            if recent.allSatisfy({ $0.avgRPE >= 9 }) {
                let suggested = roundToPlate(lastWeight * 0.95)
                guard suggested < lastWeight else { continue }
                advices.append(
                    CoachingAdvice(
                        title: "重量を少し下げましょう",
                        message:
                            "\(exercise.name)は直近2回とも高強度（RPE 9 以上）でした。次回は \(WeightFormatter.oneRM(kilograms: lastWeight, in: weightUnit)) → \(WeightFormatter.oneRM(kilograms: suggested, in: weightUnit)) を目安に。",
                        severity: .warning,
                        impact: (lastWeight - suggested) + 50
                    )
                )
            } else if recent.allSatisfy({ $0.avgRPE <= 6 }) {
                let suggested = roundToPlate(lastWeight * 1.025)
                guard suggested > lastWeight else { continue }
                advices.append(
                    CoachingAdvice(
                        title: "重量を上げてみましょう",
                        message:
                            "\(exercise.name)は直近2回とも余裕（RPE 6 以下）でした。次回は \(WeightFormatter.oneRM(kilograms: lastWeight, in: weightUnit)) → \(WeightFormatter.oneRM(kilograms: suggested, in: weightUnit)) を目安に。",
                        severity: .info,
                        impact: (suggested - lastWeight) + 50
                    )
                )
            }
        }
        return advices.sorted { $0.impact > $1.impact }
    }

    /// 2.5kg 刻みに丸める（プレート単位）。
    static func roundToPlate(_ weight: Double) -> Double {
        (weight / 2.5).rounded() * 2.5
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter autoregulation`
Expected: PASS（5件）。`roundToPlate(100*0.95)=95`、`roundToPlate(100*1.025)=102.5`。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): RPE オートレギュレーション（セッション間の重量提案）を追加"
```

---

## Task 6: 共有ヘルパー抽出 + `prPredictions` を RIR 推定・信頼レンジに改修

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: Write the failing test（CI 表記と既存挙動の維持）**

`AnalyticsTests.swift` の `// MARK: - prPredictions (線形回帰)` セクションの末尾（`prPredictionInsufficientSamples` の後）に追記:

```swift
    @Test("prPredictions: 予測メッセージに信頼レンジ（±）が含まれる")
    func prPredictionShowsConfidenceRange() throws {
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
        #expect(predictions.first?.message.contains("±") == true)
    }
```

既存の `prPredictionRisingTrend` / `prPredictionFlatTrend` / `prPredictionInsufficientSamples` は変更しない（新実装でも結果は同じはず — Step 4 で確認）。

- [ ] **Step 2: Run the tests to verify the new one fails**

Run: `swift test --package-path Packages/OikomiKit --filter prPrediction`
Expected: `prPredictionShowsConfidenceRange` が FAIL（`±` を含まない）。他は PASS。

- [ ] **Step 3: 共有ヘルパー抽出 + `prPredictions` 改修**

まず `Analytics.swift` の `linearRegression(...)` メソッドの直後に共有ヘルパーを追加:

```swift
    /// 指定種目のセットを「セッション単位の最高推定 1RM（RIR 補正つき）」の時系列にする。古い順、直近 `windowSize` 件。
    ///
    /// 保存済み `estimated1RM`（Epley 固定）ではなく `OneRepMax.estimate(weight:reps:rpe:)` で都度算出することで、
    /// レップ域別の式選択と RPE(RIR) 補正を効かせる。
    static func sessionMaxEstimateSeries(
        sets: [SetRecord],
        forExerciseId exerciseId: UUID,
        windowSize: Int
    ) -> [Double] {
        let exerciseSets = sets.filter { !$0.isWarmup && $0.exercise?.id == exerciseId }
        let bySession = Dictionary(grouping: exerciseSets) { $0.session?.id ?? UUID() }
        return
            bySession.values
            .compactMap { setsInSession -> (date: Date, max: Double)? in
                let estimates = setsInSession.compactMap { set -> Double? in
                    guard let w = set.weight, let r = set.reps, w > 0, r > 0 else { return nil }
                    return OneRepMax.estimate(weight: w, reps: r, rpe: set.rpe)
                }
                guard let maxRM = estimates.max(),
                    let latest = setsInSession.map(\.completedAt).max()
                else { return nil }
                return (date: latest, max: maxRM)
            }
            .sorted { $0.date < $1.date }
            .suffix(windowSize)
            .map(\.max)
    }

    /// 回帰の残差標準誤差を ± マージン（kg）として返す。点が 3 未満なら 0。
    static func predictionMargin(points: [(x: Double, y: Double)], fit: (slope: Double, intercept: Double, r2: Double)) -> Double {
        let n = Double(points.count)
        guard n > 2 else { return 0 }
        let ssRes = points.reduce(0) { acc, p in
            let pred = fit.intercept + fit.slope * p.x
            return acc + (p.y - pred) * (p.y - pred)
        }
        return (ssRes / (n - 2)).squareRoot()
    }
```

次に `prPredictions(...)` の `for pr in records { ... }` ループ本体（`let exerciseSets = ...` から `advices.append(...)` まで）を次に**置換**:

```swift
        for pr in records {
            guard let exercise = pr.exercise else { continue }

            // RIR 補正つきのセッション別最高 1RM 系列（古い順）
            let maxes = sessionMaxEstimateSeries(
                sets: sets, forExerciseId: exercise.id, windowSize: windowSize)
            guard maxes.count >= minSamples else { continue }

            let points = maxes.enumerated().map { (x: Double($0.offset), y: $0.element) }
            guard let fit = linearRegression(points) else { continue }
            guard fit.slope > 0, fit.r2 >= minR2 else { continue }

            let n = Double(points.count)
            let predicted = fit.intercept + fit.slope * n
            // 比較は同方式どうし（系列内の直近最高値）で apples-to-apples にする
            let seriesMax = maxes.max() ?? 0
            guard predicted > seriesMax else { continue }

            let margin = max(1, predictionMargin(points: points, fit: fit).rounded())
            let growth = predicted - seriesMax
            advices.append(
                CoachingAdvice(
                    title: "PR 更新の可能性",
                    message:
                        "次回\(exercise.name)で推定 \(WeightFormatter.oneRM(kilograms: predicted, in: weightUnit))（±\(Int(margin))kg）の PR を狙えます（直近\(points.count)セッションの上昇トレンドより）。",
                    severity: .info,
                    impact: predicted + growth
                )
            )
        }
```

> `pr.estimated1RM > 0` のガードは廃止（系列内比較に切り替えたため）。`exerciseId` ローカル変数は不要になったので、置換後に未使用の `let exerciseId = exercise.id` が残らないこと（上記置換で消える）を確認。

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter prPrediction`
Expected: 4件すべて PASS。
- `prPredictionRisingTrend`: 80→84kg×8 → Brzycki 系列が単調増加 → 発火（非空）。
- `prPredictionFlatTrend`: 全 80×8 → slope≈0 → 非発火（空）。
- `prPredictionInsufficientSamples`: 4 セッション < 5 → 空。
- `prPredictionShowsConfidenceRange`: message に `±` を含む。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): PR予測をRIR補正・系列内比較・信頼レンジ表示に高度化"
```

---

## Task 7: `plateauAdvice`（停滞検出）

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: Write the failing tests**

`AnalyticsTests.swift` の `// MARK: - prPredictions (線形回帰)` セクションの直後（`linearRegressionPerfectFit` の後）に新しい MARK を追記:

```swift
    // MARK: - plateauAdvice

    @Test("plateauAdvice: 横ばい 5 セッションで停滞 advice を出す")
    func plateauFlat() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
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
        #expect(advices.contains { $0.title.contains("停滞") })
    }

    @Test("plateauAdvice: 明確な上昇トレンドでは停滞を出さない")
    func plateauRisingNone() throws {
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
        let advices = Analytics.plateauAdvice(sets: allSets, records: records)
        #expect(advices.isEmpty)
    }

    @Test("plateauAdvice: サンプル不足では出さない")
    func plateauInsufficient() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let cal = Self.calendar
        let now = Date()
        for offset in 0..<4 {
            let date = cal.date(byAdding: .day, value: -(3 - offset) * 2, to: now)!
            let session = try repo.startSession(at: date)
            try repo.addSet(to: session, exercise: bench, weight: 80, reps: 8, completedAt: date)
            session.endedAt = date
        }
        let records = try context.fetch(FetchDescriptor<PersonalRecord>())
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())
        let advices = Analytics.plateauAdvice(sets: allSets, records: records)
        #expect(advices.isEmpty)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter plateau`
Expected: コンパイルエラー（`plateauAdvice` 未定義）。

- [ ] **Step 3: Implement `plateauAdvice`**

`Analytics.swift` の `prPredictions(...)` メソッドの直後に追加:

```swift
    /// 停滞（プラトー）検出。種目別に最高推定 1RM 系列の傾きがほぼ 0 のとき助言する。
    ///
    /// PR 予測とは別関数。`slopeEpsilon`（kg/セッション）未満の傾きを「停滞」とみなす。
    public static func plateauAdvice(
        sets: [SetRecord],
        records: [PersonalRecord],
        windowSize: Int = 10,
        minSamples: Int = 5,
        slopeEpsilon: Double = 0.25,
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        var advices: [CoachingAdvice] = []
        for pr in records {
            guard let exercise = pr.exercise else { continue }
            let maxes = sessionMaxEstimateSeries(
                sets: sets, forExerciseId: exercise.id, windowSize: windowSize)
            guard maxes.count >= minSamples else { continue }
            let points = maxes.enumerated().map { (x: Double($0.offset), y: $0.element) }
            guard let fit = linearRegression(points) else { continue }
            guard abs(fit.slope) < slopeEpsilon else { continue }
            advices.append(
                CoachingAdvice(
                    title: "停滞ぎみ",
                    message:
                        "\(exercise.name)はここ\(points.count)セッションほぼ横ばいです。レップ域・頻度・種目の変更を検討してください。",
                    severity: .info,
                    impact: Double(points.count)
                )
            )
        }
        return advices.sorted { $0.impact > $1.impact }
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter plateau`
Expected: PASS（3件）。横ばい → slope≈0 < 0.25 → 発火。上昇（Brzycki ≈ +1.24/session）→ slope > 0.25 → 非発火。4 セッション < 5 → 空。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): 種目別の停滞（プラトー）検出 plateauAdvice を追加"
```

---

## Task 8: `HealthSnapshot.readinessScore` フィールド追加（予約）

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Models/HealthSnapshot.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`（既存スイートに最小の生成テストを1件）

> **CLAUDE.md 規律:** SwiftData `@Model` の変更は `swift-data-modeler` サブエージェントで行うこと。追加は Optional フィールドのみ（CloudKit 互換・lightweight migration で既存データを壊さない）。`menstrualPhaseRawValue` と同じ「予約フィールド」パターンに従う。

- [ ] **Step 1: Write the failing test**

`AnalyticsTests.swift` の末尾 `}` の直前に追記:

```swift
    // MARK: - HealthSnapshot.readinessScore（予約フィールド）

    @Test("HealthSnapshot: readinessScore は既定 nil・代入で保持される")
    func healthSnapshotReadinessField() {
        let snap = HealthSnapshot(date: Date())
        #expect(snap.readinessScore == nil)
        snap.readinessScore = 72
        #expect(snap.readinessScore == 72)
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --package-path Packages/OikomiKit --filter healthSnapshotReadinessField`
Expected: コンパイルエラー（`readinessScore` 未定義）。

- [ ] **Step 3: Add the field（swift-data-modeler 経由）**

`HealthSnapshot.swift` を次のように変更:

`restingHeartRate` プロパティ宣言の直後に追加:

```swift
    /// コンディション総合スコア（0-100）のスナップショット。Spec 1 では予約のみ（populate は Spec 2）。
    public var readinessScore: Int?
```

`init` のシグネチャに引数を追加（`restingHeartRate: Int? = nil,` の直後）:

```swift
        readinessScore: Int? = nil,
```

`init` 本体に代入を追加（`self.restingHeartRate = restingHeartRate` の直後）:

```swift
        self.readinessScore = readinessScore
```

> `schemaModels`（`OikomiKit.swift`）は HealthSnapshot 型を既に含むため変更不要。Optional 追加は自動 lightweight migration の対象。

- [ ] **Step 4: Run the test to verify it passes**

Run: `swift test --package-path Packages/OikomiKit --filter healthSnapshotReadinessField`
Expected: PASS。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Models/HealthSnapshot.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(model): HealthSnapshot に readinessScore 予約フィールドを追加"
```

---

## Task 9: `HealthStore.readinessSnapshot(...)` ラッパー

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift`

> I/O 薄ラッパーのため単体テストは付けない（純粋計算 `ReadinessScore.compute` は Task 2 でテスト済み）。ビルドで型整合を確認する。

- [ ] **Step 1: 既存 API を確認**

Run: `grep -n "func dailySeries\|func todayValue\|enum HealthMetric\|canReadHealthData\|public static let shared\|class HealthStore\|actor HealthStore" Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift`
Expected: `dailySeries(for:days:) async -> [HealthTrendPoint]`、`todayValue(for:) async -> Double?`、`HealthMetric` に `.hrv`/`.restingHeartRate`/`.sleepHours`、`ProGate.canReadHealthData` ゲートの存在を確認。`HealthStore.shared` のアクセス形と `func` の隔離（`async`）を把握する。

- [ ] **Step 2: Implement the wrapper**

`HealthStore` 型の本体内（既存 `dailySeries`/`todayValue` と同じスコープ、末尾あたり）に追加:

```swift
    /// 今日のレディネス（コンディション総合スコア）を算出する薄いラッパー。
    ///
    /// HRV / 安静時心拍の 60 日系列と今日の睡眠時間を取得し `ReadinessScore.compute` に渡す。
    /// Pro 未契約・HealthKit 未認可なら（各 API が空/nil を返すため）結果は nil になりうる。
    public func readinessSnapshot(
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) async -> ReadinessScore? {
        guard ProGate.canReadHealthData else { return nil }
        async let hrv = dailySeries(for: .hrv, days: 60)
        async let rhr = dailySeries(for: .restingHeartRate, days: 60)
        async let sleep = todayValue(for: .sleepHours)
        let (hrvSeries, rhrSeries, sleepHours) = await (hrv, rhr, sleep)
        return ReadinessScore.compute(
            hrvSeries: hrvSeries,
            rhrSeries: rhrSeries,
            sleepHours: sleepHours,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }
```

> Step 1 の確認で `HealthStore` が `#if canImport(HealthKit)` 分岐や no-op フォールバックを持つ場合は、`readinessSnapshot` をそれらの外（常にコンパイルされる本体）に置き、内部で呼ぶ `dailySeries`/`todayValue` が両分岐に存在することを確認する。`ProGate.canReadHealthData` の参照可否（import）も既存 `dailySeries` と同じファイルなので問題ない。

- [ ] **Step 3: Build OikomiKit to verify it compiles**

Run: `swift build --package-path Packages/OikomiKit`
Expected: ビルド成功。

- [ ] **Step 4: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift
git commit -m "feat(health): HealthStore.readinessSnapshot ラッパーを追加"
```

---

## Task 10: HomeView を readiness ベースに配線

**Files:**
- Modify: `App/iOS/Views/HomeView.swift:35-128`

- [ ] **Step 1: HRV 系列の State を readiness に置換**

`HomeView.swift` の以下（35-37 行付近）:

```swift
    /// HealthStore から取得した直近 14 日の HRV 系列。Pro 未契約や HealthKit 未認可では空のまま。
    /// 値が入ると `coachingAdvice` の HRV 低下判定が動作する。
    @State private var hrvSeries: [HealthTrendPoint] = []
```

を次に置換:

```swift
    /// HealthStore から算出した今日のレディネス。Pro 未契約や HealthKit 未認可では nil のまま。
    /// 値が入ると `coachingAdvice` のレディネス判定が動作し、TodayConditionCard にも表示される。
    @State private var readiness: ReadinessScore?
```

- [ ] **Step 2: `coachingAdvice` を新アドバイス群に更新**

`coachingAdvice` 算出プロパティ（70-79 行）を次に置換:

```swift
    private var coachingAdvice: [CoachingAdvice] {
        guard ProGate.canUseAICoaching else { return [] }
        let allSets = completedSessions.flatMap { $0.sets ?? [] }
        let deload = Analytics.deloadAdvice(
            sessions: completedSessions, sets: allSets, readiness: readiness)
        let volume = Analytics.volumeAdvice(from: allSets)
        let autoreg = Analytics.autoregulationAdvice(sets: allSets, weightUnit: weightUnit)
        let prPredictions = Analytics.prPredictions(
            sets: allSets, records: personalRecords, weightUnit: weightUnit)
        let plateau = Analytics.plateauAdvice(sets: allSets, records: personalRecords)
        return Array((deload + autoreg + prPredictions + plateau + volume).prefix(3))
    }
```

- [ ] **Step 3: `TodayConditionCard()` に readiness を渡す**

`body` 内（93 行付近）の:

```swift
                    TodayConditionCard()
```

を次に置換:

```swift
                    TodayConditionCard(readiness: readiness)
```

- [ ] **Step 4: 取得処理を readiness に置換**

`refreshHRVSeries()`（120-128 行）を次に置換:

```swift
    /// HealthStore から今日のレディネスを取り直す。Pro/権限がなければ nil。
    @MainActor
    private func refreshHealthSignals() async {
        guard ProGate.canReadHealthData else {
            readiness = nil
            return
        }
        readiness = await HealthStore.shared.readinessSnapshot()
    }
```

そして `body` の `.task(id: ProGate.isProActive)`（114-116 行）内の呼び出しを変更:

```swift
            .task(id: ProGate.isProActive) {
                await refreshHealthSignals()
            }
```

- [ ] **Step 5: Build the iOS app**

Run: `/build`（または `xcodebuild` 相当）
Expected: ビルド成功（`hrvSeries` / `refreshHRVSeries` の参照が残っていないこと）。

- [ ] **Step 6: Commit**

```bash
git add App/iOS/Views/HomeView.swift
git commit -m "feat(home): コーチングをレディネス＋オートレギュレーション＋停滞検出に配線"
```

---

## Task 11: TodayConditionCard に総合スコアとソース注記を表示

**Files:**
- Modify: `App/iOS/Views/Components/TodayConditionCard.swift`

- [ ] **Step 1: `readiness` プロパティを追加**

`TodayConditionCard` の State 宣言群（11-14 行）の直前に追加:

```swift
    /// 親（HomeView）が算出して渡すレディネス。nil なら総合スコア行は出さない。
    var readiness: ReadinessScore? = nil
```

- [ ] **Step 2: 総合スコア行を `proContent` に追加**

`proContent`（53-80 行）の `HStack(alignment: .top, spacing: 0) { ... }` を `VStack` で包み、その先頭にスコア行を入れる。`proContent` 全体を次に置換:

```swift
    @ViewBuilder
    private var proContent: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            if let readiness {
                readinessRow(readiness)
            }
            HStack(alignment: .top, spacing: 0) {
                metricCell(
                    title: "HRV",
                    value: hrv.map { "\(Int($0.rounded()))" } ?? "—",
                    unit: "ms",
                    systemImage: "waveform.path.ecg",
                    tint: OikomiColor.statPink
                )
                divider
                metricCell(
                    title: "安静時心拍",
                    value: rhr.map { "\($0)" } ?? "—",
                    unit: "bpm",
                    systemImage: "heart.fill",
                    tint: OikomiColor.statRed
                )
                divider
                metricCell(
                    title: "睡眠",
                    value: sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—",
                    unit: "h",
                    systemImage: "moon.zzz.fill",
                    tint: OikomiColor.statIndigo
                )
            }
        }
    }

    @ViewBuilder
    private func readinessRow(_ readiness: ReadinessScore) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("コンディション")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(readiness.value)")
                    .font(OikomiFont.statValueCompact)
                    .foregroundStyle(readinessColor(readiness.band))
                Text("/ 100")
                    .font(OikomiFont.metricUnit)
                    .foregroundStyle(.secondary)
            }
            if let note = readiness.sourceNote {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func readinessColor(_ band: ReadinessScore.Band) -> Color {
        switch band {
        case .low: return OikomiColor.statRed
        case .normal: return .primary
        case .high: return OikomiColor.statGreen
        }
    }
```

> `OikomiColor.statGreen` が存在しない場合は、`/lint` 前に `grep -n "static.*stat" App/iOS/DesignSystem` で実在する success 系カラー（例: `statGreen` / `severitySuccess` / `brandPrimary`）を確認し、存在するトークンに置換する。`.low` の `statRed` は `metricCell` で既に使用済みのため実在する。

- [ ] **Step 3: Build the iOS app**

Run: `/build`
Expected: ビルド成功。`TodayConditionCard(readiness:)` と引数なし `TodayConditionCard()`（#Preview）の両方がコンパイルできる（`readiness` はデフォルト nil）。

- [ ] **Step 4: Commit**

```bash
git add App/iOS/Views/Components/TodayConditionCard.swift
git commit -m "feat(home): TodayConditionCard にコンディション総合スコアとデータソース注記を表示"
```

---

## Task 12: SPEC.md §4.2.2 を先行更新

**Files:**
- Modify: `docs/SPEC.md`（§4.2.2 AI コーチング、177-187 行付近）

- [ ] **Step 1: 現状の §4.2.2 を確認**

Run: `sed -n '170,195p' docs/SPEC.md`
Expected: 「v1.0 では 3つに絞る」とディロード/PR予測/ボリューム警告の表。

- [ ] **Step 2: §4.2.2 を更新**

§4.2.2 の本文を、以下の要点を反映するよう編集する（既存の体裁・見出し階層に合わせて自然な日本語で記述。新規コピーは機械翻訳調にしない）:

- ディロード判定を **HRV 単独から「コンディション総合スコア（HRV z-score を主軸に睡眠・安静時心拍を統合、0-100）」へ一本化**したこと。
- **RPE オートレギュレーション**（セッション間の次回推奨重量の自動提案）を新コーチングタイプとして追加したこと。
- **PR 予測に RIR 補正・停滞検出・信頼レンジ**を追加したこと。
- これは v1.0 コーチング柱の**意図的なスコープ拡張**（Pro 収益の核を強化する判断）であること。
- **Pro 訴求は「Apple Intelligence」ではなく「HealthKit 連動コーチング」**であり、自然言語サマリ（v1.2）は「対応機種で点灯するボーナス」。**非 Apple Intelligence 機種・Apple Watch 非使用でも、Spec 1/2 のコーチングはフル機能で動作**（RPE オートレギュレーション・PR 予測は HealthKit 非依存、レディネスは利用可能な信号で graceful に縮退）すること。

設計の一次ソースは `docs/superpowers/specs/2026-05-30-coaching-readiness-autoregulation-design.md` を参照する旨を1行添える。

- [ ] **Step 3: Commit**

```bash
git add docs/SPEC.md
git commit -m "docs(spec): §4.2.2 をレディネス統合・RPE自動調整・PR予測高度化に更新"
```

---

## Task 13: 全体検証（テスト・ビルド・整形）

**Files:** なし（検証のみ。整形差分が出たらコミット）

- [ ] **Step 1: OikomiKit 全テスト**

Run: `swift test --package-path Packages/OikomiKit`
Expected: 既存 99 件 + 本スペックの新規（OneRepMax 4 / ReadinessScore 5 / readinessAdvice 3 / deload×readiness 2 / autoregulation 5 / prPrediction +1 / plateau 3 / HealthSnapshot 1）すべて PASS。失敗があれば `superpowers:systematic-debugging` で原因を特定（推測修正しない）。

- [ ] **Step 2: iOS ビルド**

Run: `/build`
Expected: ビルド成功。

- [ ] **Step 3: 整形と lint**

Run: `/format` のあと `/lint`
Expected: lint 違反なし。`/format` が差分を出した場合のみ:

```bash
git add -A
git commit -m "style: swift-format 整形"
```

- [ ] **Step 4: シナリオ確認（手動・任意）**

`/sim-run` で起動し、以下を目視:
- Pro 有効・健康データありで Home の「コンディション」スコアとコーチングチップが出る。
- Pro 有効・Apple Watch 無し（HRV 欠損）でクラッシュせず、`sourceNote`（データソース注記）が表示される。
- Free でコーチングチップが出ない（従来通り）。

---

## Self-Review（この計画の自己点検）

**1. Spec coverage（設計書 §4 の各項目 → 実装タスク）**
- A2 コンディション総合スコア → Task 2（compute）+ Task 9（I/O）+ Task 11（表示）✅
- C3 HRV 統計化（z-score / ベースライン）→ Task 2（`zScore`）✅
- 一本化（既存 HRV ディロード置換）→ Task 3 + Task 4 ✅
- 部分入力・confidence・ソースラベル → Task 2 + Task 11 ✅
- A1 RPE オートレギュレーション（セッション間）→ Task 5 ✅
- C1 PR 予測高度化（レップ域別式/RIR/停滞/信頼レンジ）→ Task 1 + Task 6 + Task 7 ✅
- `readinessScore` フィールド（予約）→ Task 8 ✅（populate は意図的に Spec 2 へ — スコープ補足に明記）
- SPEC.md 先行更新 → Task 12 ✅
- 露出（Home チップ再利用 + TodayConditionCard）→ Task 10 + Task 11 ✅

**2. Placeholder scan:** 「TBD/後で」等なし。各コードステップは実コードを掲載。例外的に Task 12（SPEC.md 散文更新）と Task 11 のカラートークン確認は、既存文体・既存トークンに合わせるため確認手順つきで指示（プレースホルダではなく、実在物に合わせる手続き）。

**3. Type consistency:**
- `ReadinessScore`（`value:Int`, `band:Band`, `confidence:Confidence`, `hrvZ:Double?`, `usedSignals:[Signal]`, `sourceNote:String?`）は Task 2 で定義し、Task 3/4/9/11 で同名参照。✅
- `Band`（low/normal/high）/ `Confidence`（low/medium/high）/ `Signal`（hrv/restingHeartRate/sleep）は Task 2 定義と Task 3/11 利用が一致。✅
- `OneRepMax.estimate(weight:reps:rpe:)` は Task 1 定義、Task 6 の `sessionMaxEstimateSeries` で利用。✅
- `Analytics.sessionMaxEstimateSeries` / `predictionMargin` / `roundToPlate` は Task 5/6 で定義し Task 6/7 で再利用（命名一貫）。✅
- `deloadAdvice(... readiness:)` の新シグネチャは Task 4 定義・Task 10 呼び出しで一致。✅
- `HealthStore.readinessSnapshot()` は Task 9 定義・Task 10 呼び出しで一致。✅
- `HealthMetric` の `.hrv/.restingHeartRate/.sleepHours` は実在（grep 済み）。`dailySeries(for:days:)` / `todayValue(for:)` も実在。✅

---

## Execution Handoff

実装計画は `docs/superpowers/plans/2026-05-30-coaching-readiness-autoregulation.md` に保存済み。2 つの実行方法:

1. **Subagent-Driven（推奨）** — タスクごとに新しいサブエージェントを割り当て、タスク間でレビュー。`superpowers:subagent-driven-development` を使用。Task 8 の `@Model` 変更は `swift-data-modeler` サブエージェントで行う。
2. **Inline Execution** — このセッションで `superpowers:executing-plans` を用いバッチ実行＋チェックポイント。

どちらで進めますか？

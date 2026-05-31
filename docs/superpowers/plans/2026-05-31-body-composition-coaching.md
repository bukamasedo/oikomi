# 体組成連動コーチング（A3）実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 体組成データ（体重・PR）をコーチングに接続し、相対筋力（1RM/体重）の一覧表示と増量/減量フェーズ判定 + 文脈コーチングを実装する。

**Architecture:** ビジネスロジックは `OikomiKit` の純粋関数（`RelativeStrength` / `BodyPhase`）に集約。`HealthStore.bodyPhase()` ラッパーが体重系列を取得して判定し、`combinedCoachingAdvice` に `bodyPhase` を渡してフェーズ提案をマージ。UI は「ボディ」分析セクションに相対筋力カードとフェーズバッジを追加し、ホームはコーチング統合のみ。新規 `@Model` なし・オンデバイス計算のみ。

**Tech Stack:** Swift / SwiftUI / SwiftData / HealthKit / Swift Testing / OikomiKit(SPM)

**設計書:** `docs/superpowers/specs/2026-05-31-body-composition-coaching-design.md`

---

## ファイル構成

| 区分 | パス | 責務 |
|---|---|---|
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/RelativeStrength.swift` | 相対筋力（1RM/体重）純粋関数 + 行モデル |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/BodyPhase.swift` | フェーズ判定 enum + detect + phaseAdvice |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift` | `bodyPhase()` ラッパー（30日体重系列→判定） |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift` | `combinedCoachingAdvice` に `bodyPhase` 引数 + マージ |
| 改修 | `App/iOS/Views/Analysis/BodyAnalysisSection.swift` | 相対筋力カード + フェーズバッジ |
| 改修 | `App/iOS/Views/AnalysisTabView.swift` | `BodyAnalysisSection(records:)` に PR を渡す |
| 改修 | `App/iOS/Views/HomeView.swift` | `bodyPhase` 取得 + `combinedCoachingAdvice` へ受け渡し |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/RelativeStrengthTests.swift` | 相対筋力テスト |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/BodyPhaseTests.swift` | フェーズ判定テスト |
| 改修 | `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift` | フェーズ統合テスト追記 |

**検証コマンド:**
- ユニットテスト: `swift test --package-path Packages/OikomiKit`
- iOS ビルド: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`（= `/build`）
- lint: `swift-format lint`（= `/lint`）

---

## Task 1: 相対筋力エンジン（RelativeStrength）

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/RelativeStrength.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/RelativeStrengthTests.swift`

- [ ] **Step 1: 失敗するテストを書く**

Create `Packages/OikomiKit/Tests/OikomiKitTests/RelativeStrengthTests.swift`:

```swift
import Foundation
import Testing

@testable import OikomiKit

@Suite("RelativeStrength")
struct RelativeStrengthTests {

    @Test("体重比 = 1RM / 体重")
    func ratioComputed() {
        let bench = Exercise(name: "ベンチプレス")
        let pr = PersonalRecord(exercise: bench, weight: 90, reps: 1, estimated1RM: 100)
        let rows = RelativeStrength.report(records: [pr], bodyweightKg: 80)
        #expect(rows.count == 1)
        #expect(rows[0].exerciseName == "ベンチプレス")
        #expect(abs(rows[0].ratio - 1.25) < 0.0001)
    }

    @Test("体重比降順でソートされる")
    func sortedByRatioDesc() {
        let squat = Exercise(name: "スクワット")
        let curl = Exercise(name: "アームカール")
        let prSquat = PersonalRecord(exercise: squat, estimated1RM: 160)  // 2.0x
        let prCurl = PersonalRecord(exercise: curl, estimated1RM: 40)     // 0.5x
        let rows = RelativeStrength.report(records: [prCurl, prSquat], bodyweightKg: 80)
        #expect(rows.map(\.exerciseName) == ["スクワット", "アームカール"])
    }

    @Test("自重種目（estimated1RM <= 0）は除外")
    func excludesZeroOneRM() {
        let pullup = Exercise(name: "懸垂")
        let pr = PersonalRecord(exercise: pullup, estimated1RM: 0)
        let rows = RelativeStrength.report(records: [pr], bodyweightKg: 80)
        #expect(rows.isEmpty)
    }

    @Test("体重未取得（<= 0）で空配列")
    func emptyWhenNoBodyweight() {
        let bench = Exercise(name: "ベンチプレス")
        let pr = PersonalRecord(exercise: bench, estimated1RM: 100)
        #expect(RelativeStrength.report(records: [pr], bodyweightKg: 0).isEmpty)
    }
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `swift test --package-path Packages/OikomiKit --filter RelativeStrength`
Expected: コンパイルエラー（`RelativeStrength` 未定義）

- [ ] **Step 3: 最小実装を書く**

Create `Packages/OikomiKit/Sources/OikomiKit/Coaching/RelativeStrength.swift`:

```swift
import Foundation

/// 1 種目の相対筋力（推定 1RM ÷ 体重）を表す行モデル。
public struct RelativeStrengthRow: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let exerciseName: String
    public let estimated1RM: Double  // kg
    public let ratio: Double         // estimated1RM / 体重

    public init(id: UUID, exerciseName: String, estimated1RM: Double, ratio: Double) {
        self.id = id
        self.exerciseName = exerciseName
        self.estimated1RM = estimated1RM
        self.ratio = ratio
    }
}

public enum RelativeStrength {
    /// 重量種目の PR から相対筋力（1RM/体重）を計算し、体重比降順で返す。
    /// 自重種目（estimated1RM <= 0）と体重未取得（bodyweightKg <= 0）は除外する。
    public static func report(
        records: [PersonalRecord],
        bodyweightKg: Double
    ) -> [RelativeStrengthRow] {
        guard bodyweightKg > 0 else { return [] }
        let rows: [RelativeStrengthRow] = records.compactMap { record in
            guard let exercise = record.exercise, record.estimated1RM > 0 else { return nil }
            return RelativeStrengthRow(
                id: record.id,
                exerciseName: exercise.name,
                estimated1RM: record.estimated1RM,
                ratio: record.estimated1RM / bodyweightKg
            )
        }
        return rows.sorted { lhs, rhs in
            if lhs.ratio != rhs.ratio { return lhs.ratio > rhs.ratio }
            return lhs.exerciseName < rhs.exerciseName
        }
    }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `swift test --package-path Packages/OikomiKit --filter RelativeStrength`
Expected: PASS（4 テスト）

- [ ] **Step 5: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/RelativeStrength.swift Packages/OikomiKit/Tests/OikomiKitTests/RelativeStrengthTests.swift
git commit -m "feat(coaching): 相対筋力（1RM/体重）エンジンを追加"
```

---

## Task 2: フェーズ判定エンジン（BodyPhase）

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/BodyPhase.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/BodyPhaseTests.swift`

依存: `Analytics.linearRegression(_:) -> (slope:Double,intercept:Double,r2:Double)?`（同モジュール internal static、`Analytics.swift:396`）、`HealthTrendPoint{date,value}`、`CoachingAdvice(title:message:severity:impact:)`。

- [ ] **Step 1: 失敗するテストを書く**

Create `Packages/OikomiKit/Tests/OikomiKitTests/BodyPhaseTests.swift`:

```swift
import Foundation
import Testing

@testable import OikomiKit

@Suite("BodyPhase")
struct BodyPhaseTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2
        return cal
    }()

    /// 起点日から day0,3,6,... と weight を与える系列を作る。
    private func series(start: Date, weights: [Double]) -> [HealthTrendPoint] {
        weights.enumerated().map { index, w in
            let date = Self.calendar.date(byAdding: .day, value: index * 3, to: start)!
            return HealthTrendPoint(date: date, value: w)
        }
    }

    private var start: Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
    }

    @Test("増加系列 → 増量期（kgPerMonth > 0）")
    func bulk() {
        // 8点・3日間隔で +0.2kg/点 ≒ +2kg/月
        let pts = series(start: start, weights: (0..<8).map { 70.0 + Double($0) * 0.2 })
        let result = BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar)
        #expect(result?.phase == .bulk)
        #expect((result?.kgPerMonth ?? 0) > 0)
    }

    @Test("減少系列 → 減量期（kgPerMonth < 0）")
    func cut() {
        let pts = series(start: start, weights: (0..<8).map { 70.0 - Double($0) * 0.2 })
        let result = BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar)
        #expect(result?.phase == .cut)
        #expect((result?.kgPerMonth ?? 0) < 0)
    }

    @Test("平坦系列 → 維持期")
    func maintenance() {
        let pts = series(start: start, weights: Array(repeating: 70.0, count: 8))
        let result = BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar)
        #expect(result?.phase == .maintenance)
    }

    @Test("サンプル不足（< 6 点）で nil")
    func insufficientSamples() {
        let pts = series(start: start, weights: [70, 71, 72, 73, 74])  // 5 点
        #expect(BodyPhase.detect(bodyMassSeries: pts, calendar: Self.calendar) == nil)
    }

    @Test("phaseAdvice: 増量/減量は 1 件 info、維持/nil は空")
    func phaseAdvice() {
        let bulk = BodyPhase.phaseAdvice(BodyPhaseResult(phase: .bulk, kgPerMonth: 1.5))
        #expect(bulk.count == 1)
        #expect(bulk.first?.severity == .info)
        #expect(bulk.first?.title == "増量期")

        let cut = BodyPhase.phaseAdvice(BodyPhaseResult(phase: .cut, kgPerMonth: -1.2))
        #expect(cut.first?.title == "減量期")

        #expect(BodyPhase.phaseAdvice(BodyPhaseResult(phase: .maintenance, kgPerMonth: 0.1)).isEmpty)
        #expect(BodyPhase.phaseAdvice(nil).isEmpty)
    }
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `swift test --package-path Packages/OikomiKit --filter BodyPhase`
Expected: コンパイルエラー（`BodyPhase` 未定義）

- [ ] **Step 3: 最小実装を書く**

Create `Packages/OikomiKit/Sources/OikomiKit/Coaching/BodyPhase.swift`:

```swift
import Foundation

/// 体重トレンドから推定するトレーニングフェーズ。
public enum BodyPhase: String, Sendable, CaseIterable {
    case bulk         // 増量期
    case cut          // 減量期
    case maintenance  // 維持期

    public var displayName: String {
        switch self {
        case .bulk: return "増量期"
        case .cut: return "減量期"
        case .maintenance: return "維持期"
        }
    }

    private static let minSamples = 6
    private static let monthlyThresholdKg = 0.5

    /// 体重系列の傾きからフェーズを判定。サンプル不足なら nil。
    /// x は最初の計測点からの経過日数（不規則な計測間隔に対応）、y は kg。
    public static func detect(
        bodyMassSeries: [HealthTrendPoint],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> BodyPhaseResult? {
        let valid = bodyMassSeries.filter { $0.value > 0 }.sorted { $0.date < $1.date }
        guard valid.count >= minSamples, let first = valid.first else { return nil }
        let points: [(x: Double, y: Double)] = valid.map { point in
            let days = calendar.dateComponents([.day], from: first.date, to: point.date).day ?? 0
            return (x: Double(days), y: point.value)
        }
        guard let fit = Analytics.linearRegression(points) else { return nil }
        let kgPerMonth = fit.slope * 30
        let phase: BodyPhase
        if kgPerMonth > monthlyThresholdKg {
            phase = .bulk
        } else if kgPerMonth < -monthlyThresholdKg {
            phase = .cut
        } else {
            phase = .maintenance
        }
        return BodyPhaseResult(phase: phase, kgPerMonth: kgPerMonth)
    }

    /// フェーズに応じた文脈コーチングを 0〜1 件返す。維持期・nil は空。
    public static func phaseAdvice(_ result: BodyPhaseResult?) -> [CoachingAdvice] {
        guard let result else { return [] }
        let formatted = String(format: "%.1f", abs(result.kgPerMonth))
        switch result.phase {
        case .bulk:
            return [
                CoachingAdvice(
                    title: "増量期",
                    message: "体重が +\(formatted) kg/月 で増加中。PR を伸ばしやすい時期です。",
                    severity: .info,
                    impact: 110
                )
            ]
        case .cut:
            return [
                CoachingAdvice(
                    title: "減量期",
                    message: "体重が -\(formatted) kg/月 で減少中。筋力を維持できていれば成功です。",
                    severity: .info,
                    impact: 110
                )
            ]
        case .maintenance:
            return []
        }
    }
}

/// フェーズ判定結果。
public struct BodyPhaseResult: Sendable, Hashable {
    public let phase: BodyPhase
    public let kgPerMonth: Double  // 体重変化率（符号付き）

    public init(phase: BodyPhase, kgPerMonth: Double) {
        self.phase = phase
        self.kgPerMonth = kgPerMonth
    }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `swift test --package-path Packages/OikomiKit --filter BodyPhase`
Expected: PASS（5 テスト）

- [ ] **Step 5: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/BodyPhase.swift Packages/OikomiKit/Tests/OikomiKitTests/BodyPhaseTests.swift
git commit -m "feat(coaching): 増量/減量フェーズ判定エンジンを追加"
```

---

## Task 3: HealthStore.bodyPhase ラッパー

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift`（`readinessSnapshot` の直後、現状 290 行付近）

純粋関数のため新規ユニットテストは追加しない（HealthKit 依存・既存 `readinessSnapshot` と同型で薄い）。Task 4 のビルドで疎通確認する。

- [ ] **Step 1: ラッパーを追加**

`readinessSnapshot(...)` メソッドの閉じ `}`（`HealthStore.swift:290`）の直後に以下を挿入:

```swift
    /// 直近 30 日の体重系列から増量/減量フェーズを判定する。
    /// Pro 未契約や HealthKit 未認可（体重データなし）の場合は nil。
    public func bodyPhase(
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) async -> BodyPhaseResult? {
        guard ProGate.canReadHealthData else { return nil }
        let series = await dailySeries(for: .bodyMass, days: 30)
        return BodyPhase.detect(
            bodyMassSeries: series, referenceDate: referenceDate, calendar: calendar)
    }
```

- [ ] **Step 2: ビルドが通ることを確認**

Run: `swift build --package-path Packages/OikomiKit`
Expected: ビルド成功

- [ ] **Step 3: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Health/HealthStore.swift
git commit -m "feat(health): bodyPhase ラッパー（30日体重系列→フェーズ判定）を追加"
```

---

## Task 4: combinedCoachingAdvice にフェーズ統合

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift:649-672`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`（追記）

- [ ] **Step 1: 失敗するテストを書く**

`AnalyticsTests.swift`（`@Suite("Analytics") @MainActor struct AnalyticsTests`）の「combinedCoachingAdvice（統合パイプライン）」セクション（`:859` 以降）内、既存の `combinedCoachingAdvice` テスト群の直後に以下のテストを追記する:

```swift
    @Test("combinedCoachingAdvice: bodyPhase を渡すとフェーズ提案がマージされる")
    func bodyPhaseMerged() {
        let cut = BodyPhaseResult(phase: .cut, kgPerMonth: -1.2)
        let withPhase = Analytics.combinedCoachingAdvice(
            sessions: [], sets: [], records: [], readiness: nil,
            limit: .max, bodyPhase: cut)
        let withoutPhase = Analytics.combinedCoachingAdvice(
            sessions: [], sets: [], records: [], readiness: nil,
            limit: .max, bodyPhase: nil)
        #expect(withPhase.contains { $0.title == "減量期" })
        #expect(!withoutPhase.contains { $0.title == "減量期" })
    }
```

> 注: `bodyPhase` は `profile` より後ろの省略可能引数。上記呼び出しは `weightUnit`/`profile` を省略しているため、`bodyPhase:` をラベル付きで渡す。

- [ ] **Step 2: テストが失敗することを確認**

Run: `swift test --package-path Packages/OikomiKit --filter bodyPhaseMerged`
Expected: コンパイルエラー（`combinedCoachingAdvice` に `bodyPhase` 引数なし）

- [ ] **Step 3: 実装を変更**

`combinedCoachingAdvice` のシグネチャ（`Analytics.swift:649-659`）に `bodyPhase` 引数を `profile` の後ろへ追加:

```swift
    public static func combinedCoachingAdvice(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        readiness: ReadinessScore?,
        limit: Int = 3,
        referenceDate: Date = Date(),
        calendar: Calendar = .current,
        weightUnit: WeightUnit = .kg,
        profile: TrainingProfile = .default,
        bodyPhase: BodyPhaseResult? = nil
    ) -> [CoachingAdvice] {
```

`let all = ...` のマージ式（`Analytics.swift:660-672`）の末尾に `BodyPhase.phaseAdvice` を追加。`ProgressiveOverload.progressiveOverloadAdvice(...)` の行の末尾に `+ BodyPhase.phaseAdvice(bodyPhase)` を足す:

```swift
            + ProgressiveOverload.progressiveOverloadAdvice(
                sets: sets, profile: profile, referenceDate: referenceDate, calendar: calendar)
            + BodyPhase.phaseAdvice(bodyPhase)
```

ソート / `limit` 部分（`674-682`）は変更しない。

- [ ] **Step 4: テストが通ることを確認**

Run: `swift test --package-path Packages/OikomiKit`
Expected: 全テスト PASS（既存 + 新規 Task1/2/4）

- [ ] **Step 5: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): combinedCoachingAdvice にフェーズ提案を統合"
```

---

## Task 5: ボディ分析セクションに相対筋力カード + フェーズバッジ

**Files:**
- Modify: `App/iOS/Views/Analysis/BodyAnalysisSection.swift`
- Modify: `App/iOS/Views/AnalysisTabView.swift:154`

UI のため自動テストは追加せず、ビルド + lint + 手動確認で検証する。

- [ ] **Step 1: `BodyAnalysisSection` に PR・体重・フェーズの状態を追加**

`BodyAnalysisSection.swift` の構造体冒頭（`@State private var lbmSeries` 群の付近、`:8-11`）に以下を追加:

```swift
    let records: [PersonalRecord]

    @State private var bodyweightKg: Double?
    @State private var bodyPhase: BodyPhaseResult?
```

> `records` は `let`（呼び出し側から注入）。SwiftUI の `struct` メンバ初期化子が自動で `BodyAnalysisSection(records:)` を生成する。既存 `@State`/`@AppStorage` はデフォルト値があるため引数化されない。

- [ ] **Step 2: `refresh()` で体重とフェーズも取得**

`refresh()`（`:184-194`）を以下に置き換える:

```swift
    private func refresh() async {
        isLoading = true
        async let weight = HealthStore.shared.dailySeries(for: .bodyMass, days: days)
        async let fat = HealthStore.shared.dailySeries(for: .bodyFatPercentage, days: days)
        async let lbm = HealthStore.shared.dailySeries(for: .leanBodyMass, days: days)
        async let bw = HealthStore.shared.todayValue(for: .bodyMass)
        async let phase = HealthStore.shared.bodyPhase()
        let (w, f, l, b, p) = await (weight, fat, lbm, bw, phase)
        weightSeries = w
        fatSeries = f
        lbmSeries = l
        bodyweightKg = b
        bodyPhase = p
        isLoading = false
    }
```

- [ ] **Step 3: 相対筋力カードとフェーズバッジを `body` に追加**

`body`（`:21-58`）の `VStack(spacing: OikomiSpacing.l) { ... }` 内で、体重 `metricCard` の直後に相対筋力カードを挿入する。`body` 全体を以下に置き換える:

```swift
    var body: some View {
        let convertedWeight = weightSeries.map {
            HealthTrendPoint(date: $0.date, value: weightUnit.fromKilograms($0.value))
        }
        let convertedLBM = lbmSeries.map {
            HealthTrendPoint(date: $0.date, value: weightUnit.fromKilograms($0.value))
        }
        let relativeRows = Array(
            RelativeStrength.report(records: records, bodyweightKg: bodyweightKg ?? 0).prefix(5))
        VStack(spacing: OikomiSpacing.l) {
            metricCard(
                title: "体重",
                subtitle: "直近 90 日",
                unit: weightUnit.symbol,
                series: convertedWeight,
                tint: OikomiColor.textSecondary,
                systemImage: "scalemass.fill",
                badge: bodyPhase?.phase.displayName
            )
            relativeStrengthCard(rows: relativeRows)
            metricCard(
                title: "体脂肪率",
                subtitle: "直近 90 日",
                unit: "%",
                series: fatSeries.map { HealthTrendPoint(date: $0.date, value: $0.value * 100) },
                tint: OikomiColor.statOrange,
                systemImage: "percent"
            )
            metricCard(
                title: "除脂肪体重 (LBM)",
                subtitle: "直近 90 日",
                unit: weightUnit.symbol,
                series: convertedLBM,
                tint: OikomiColor.statGreen,
                systemImage: "figure.strengthtraining.traditional"
            )
            healthAppLinkCard
        }
        .task {
            await refresh()
        }
    }
```

- [ ] **Step 4: `metricCard` に `badge` 引数を追加**

`metricCard(...)`（`:60-118`）のシグネチャに `badge: String? = nil` を足し、ヘッダの `Spacer()` の前にバッジを表示する。シグネチャと `HStack` ヘッダ部分を以下に変更:

```swift
    @ViewBuilder
    private func metricCard(
        title: String,
        subtitle: String,
        unit: String,
        series: [HealthTrendPoint],
        tint: Color,
        systemImage: String,
        badge: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(tint)
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, OikomiSpacing.s)
                        .padding(.vertical, 2)
                        .background(tint.opacity(0.15), in: Capsule())
                        .foregroundStyle(tint)
                }
                Spacer()
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
```

> 以降（`if isLoading { ... }` 〜 カード末尾の `.background(...)`）は既存のまま変更しない。

- [ ] **Step 5: `relativeStrengthCard` を追加**

`healthAppLinkCard`（`:164` 付近）の定義の直前に、新しいカードビルダーを追加:

```swift
    @ViewBuilder
    private func relativeStrengthCard(rows: [RelativeStrengthRow]) -> some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label("相対筋力", systemImage: "figure.strengthtraining.functional")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(OikomiColor.statBlue)
                Spacer()
                Text("1RM ÷ 体重")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OikomiSpacing.xl)
            } else if rows.isEmpty {
                HStack(spacing: OikomiSpacing.s) {
                    Image(systemName: "figure.strengthtraining.functional")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("体重と種目の自己ベストを記録すると、体重比が表示されます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, OikomiSpacing.m)
            } else {
                VStack(spacing: OikomiSpacing.s) {
                    ForEach(rows) { row in
                        HStack {
                            Text(row.exerciseName)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text(row.ratio, format: .number.precision(.fractionLength(2)))
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(OikomiColor.statBlue)
                            Text("×")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground,
            in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }
```

- [ ] **Step 6: `AnalysisTabView` から PR を渡す**

`App/iOS/Views/AnalysisTabView.swift:154` の `BodyAnalysisSection()` を以下に変更:

```swift
            BodyAnalysisSection(records: personalRecords)
```

- [ ] **Step 7: ビルドと lint**

Run: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`
Expected: `** BUILD SUCCEEDED **`

Run: `swift-format lint --recursive App/iOS/Views/Analysis/BodyAnalysisSection.swift App/iOS/Views/AnalysisTabView.swift`
Expected: 新規違反なし

- [ ] **Step 8: コミット**

```bash
git add App/iOS/Views/Analysis/BodyAnalysisSection.swift App/iOS/Views/AnalysisTabView.swift
git commit -m "feat(analysis): ボディに相対筋力カードとフェーズバッジを追加"
```

---

## Task 6: ホームにフェーズコーチングを統合

**Files:**
- Modify: `App/iOS/Views/HomeView.swift`（`:50` 付近 / `:85-97` / `:146-152`）

- [ ] **Step 1: `bodyPhase` 状態を追加**

`HomeView.swift` の `@State private var readiness: ReadinessScore?`（`:50`）の直後に追加:

```swift
    @State private var bodyPhase: BodyPhaseResult?
```

- [ ] **Step 2: `allCoaching` でフェーズを渡す**

`allCoaching`（`:88-96`）の `combinedCoachingAdvice` 呼び出しに `bodyPhase: bodyPhase` を追加:

```swift
        return Analytics.combinedCoachingAdvice(
            sessions: completedSessions,
            sets: allSets,
            records: personalRecords,
            readiness: readiness,
            limit: .max,
            weightUnit: weightUnit,
            profile: trainingProfile,
            bodyPhase: bodyPhase
        )
```

- [ ] **Step 3: `refreshHealthSignals` でフェーズも取得**

`refreshHealthSignals()`（`:146-152`）を以下に置き換える:

```swift
    @MainActor
    private func refreshHealthSignals() async {
        guard ProGate.canReadHealthData else {
            readiness = nil
            bodyPhase = nil
            return
        }
        readiness = await HealthStore.shared.readinessSnapshot()
        bodyPhase = await HealthStore.shared.bodyPhase()
    }
```

- [ ] **Step 4: ビルドと lint**

Run: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`
Expected: `** BUILD SUCCEEDED **`

Run: `swift-format lint --recursive App/iOS/Views/HomeView.swift`
Expected: 新規違反なし

- [ ] **Step 5: コミット**

```bash
git add App/iOS/Views/HomeView.swift
git commit -m "feat(home): フェーズコーチングをホームのコーチングへ統合"
```

---

## 完了後の最終検証

1. `swift test --package-path Packages/OikomiKit` → 全テスト PASS（既存 + RelativeStrength 4 + BodyPhase 5 + Analytics 1）。
2. `/build` → `** BUILD SUCCEEDED **`。
3. `/lint` → 新規違反ゼロ。
4. 手動（任意・`/sim-run`）:
   - Pro + 体重 + PR あり → 「ボディ」に相対筋力カード（体重比降順）、体重カードにフェーズバッジ。
   - 体重トレンドが増加/減少 → ホームのコーチングに「増量期/減量期」提案。
   - 体重データなし / Free → 相対筋力はプレースホルダ、バッジ非表示、フェーズ提案なし、クラッシュなし。

## スコープ外（このプランでやらない）
- 自重種目への体重結合（実効負荷・PR・ボリューム計上）。
- 相対筋力マイルストーン演出。
- オンボーディングでの体組成・目標捕捉。

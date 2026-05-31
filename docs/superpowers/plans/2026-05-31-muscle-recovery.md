# 部位別リカバリー（Spec 2-A4）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 部位ごとの回復状態（回復済/回復中/疲労/未実施）と回復率(0-100%)を `SetRecord` から純粋関数で導出し、分析タブ「部位別」に表示し、「回復済みの部位」コーチング提案を `combinedCoachingAdvice` に流す。

**Architecture:** すべて `OikomiKit/Coaching` のオンデバイス純粋関数。新ファイル `MuscleRecovery.swift` に値型＋部位別基準回復時間テーブル＋ `report`/`recoveryAdvice` を置き、既存の部位別 fan-out（`Exercise.muscleGroups`）と `MuscleGroup` を流用。回復時間 = 部位別基準（大72/中48/小36h）＋ 前回セッションのセット数・RPE で伸縮。UI は既存 `MuscleGroupAnalysisSection` の行/バー/チップパターンを踏襲。新スキーマ・自重・HealthKit 不要。

**Tech Stack:** Swift / SwiftData（読みのみ）/ Swift Testing（`import Testing`, `@Test`, `#expect`）。テスト: `swift test --package-path Packages/OikomiKit`。iOS ビルド: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`。

---

## ファイル構成（責務）

| 区分 | パス | 責務 |
|---|---|---|
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleRecovery.swift` | `RecoveryState` / `MuscleRecoveryRow` / 部位別基準時間 / `report` / `recoveryAdvice`（純粋関数） |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift` | `combinedCoachingAdvice` の統合リストに `MuscleRecovery.recoveryAdvice` を追加 |
| 改修 | `App/iOS/Views/Analysis/MuscleGroupAnalysisSection.swift` | 「部位の回復状態」カードを追加 |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/MuscleRecoveryTests.swift` | `report`/`recoveryAdvice` の単体テスト |
| 改修 | `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift` | `combinedCoachingAdvice` に回復提案が混ざる統合テスト |

注: SourceKit/IDE 診断はこのリポジトリでは遅延・誤検知する（"No such module 'Testing'" 等）。**唯一の正は `swift test` / `xcodebuild` の成否**。

---

## Task 1: `MuscleRecovery` 値型 + `report`（純粋関数）

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleRecovery.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/MuscleRecoveryTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `MuscleRecoveryTests.swift` with EXACTLY:

```swift
import Foundation
import Testing

@testable import OikomiKit

@Suite("MuscleRecovery")
struct MuscleRecoveryTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }()

    private var now: Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 5, day: 31, hour: 12))!
    }

    /// `hoursAgo` 時間前に `muscles` を `setCount` セット鍛えたワーキングセット群を作る（context 不要・スタンドアロン）。
    private func sets(
        _ muscles: [MuscleGroup], hoursAgo: Double, setCount: Int = 1,
        rpe: Double? = nil, isWarmup: Bool = false, isCompleted: Bool = true
    ) -> [SetRecord] {
        let date = now.addingTimeInterval(-hoursAgo * 3600)
        let ex = Exercise(name: "t", muscleGroups: muscles)
        return (0..<setCount).map { _ in
            SetRecord(
                exercise: ex, weight: 60, reps: 8, rpe: rpe,
                isWarmup: isWarmup, completedAt: date, isCompleted: isCompleted)
        }
    }

    private func row(_ rows: [MuscleRecoveryRow], _ muscle: MuscleGroup) -> MuscleRecoveryRow? {
        rows.first { $0.muscle == muscle }
    }

    @Test("report: 記録のない筋群は untrained・daysSince nil")
    func untrained() {
        let rows = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 10), referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .quads)?.state == .untrained)
        #expect(row(rows, .quads)?.daysSinceLastTrained == nil)
    }

    @Test("report: fullBody は含まれない / abs は含まれる")
    func trackedFilter() {
        let rows = MuscleRecovery.report(sets: [], referenceDate: now, calendar: Self.calendar)
        #expect(!rows.contains { $0.muscle == .fullBody })
        #expect(rows.contains { $0.muscle == .abs })
    }

    @Test("report: 直後は fatigued、ウィンドウ半ばは recovering、超過は recovered")
    func stateThresholds() {
        let f = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 6), referenceDate: now, calendar: Self.calendar)
        #expect(row(f, .chest)?.state == .fatigued)  // 6/48 = 0.125
        let r = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 30), referenceDate: now, calendar: Self.calendar)
        #expect(row(r, .chest)?.state == .recovering)  // 30/48 = 0.625
        let d = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 50), referenceDate: now, calendar: Self.calendar)
        #expect(row(d, .chest)?.state == .recovered)  // 50/48 >= 1
    }

    @Test("report: 高ボリュームは回復ウィンドウを延ばす")
    func loadExtendsWindow() {
        // chest 48h ago。6セット→window48→recovered。14セット→window72→未回復。
        let light = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, setCount: 6), referenceDate: now, calendar: Self.calendar)
        #expect(row(light, .chest)?.state == .recovered)
        let heavy = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, setCount: 14), referenceDate: now, calendar: Self.calendar)
        #expect(row(heavy, .chest)?.state != .recovered)
    }

    @Test("report: 高RPEは回復ウィンドウを延ばす")
    func rpeExtendsWindow() {
        let easy = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, rpe: nil), referenceDate: now, calendar: Self.calendar)
        #expect(row(easy, .chest)?.state == .recovered)
        let hard = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48, rpe: 9), referenceDate: now, calendar: Self.calendar)
        #expect(row(hard, .chest)?.state == .recovering)  // window 54 → 48/54 = 0.889
    }

    @Test("report: 大筋群は小筋群より回復が遅い")
    func baseHoursBySize() {
        // 60h ago。quads base72 → 0.83 recovering。biceps base36 → recovered。
        let s = sets([.quads], hoursAgo: 60) + sets([.biceps], hoursAgo: 60)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .quads)?.state == .recovering)
        #expect(row(rows, .biceps)?.state == .recovered)
    }

    @Test("report: warmup と未完了セットは無視")
    func excludesWarmupAndIncomplete() {
        let s =
            sets([.chest], hoursAgo: 6, isWarmup: true)
            + sets([.chest], hoursAgo: 6, isCompleted: false)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .chest)?.state == .untrained)
    }

    @Test("report: 複合種目は関与する全筋群を鍛えた扱い")
    func compoundHitsAllMuscles() {
        let s = sets([.chest, .triceps, .shoulders], hoursAgo: 6)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .chest)?.state == .fatigued)
        #expect(row(rows, .triceps)?.state == .fatigued)
        #expect(row(rows, .shoulders)?.state == .fatigued)
    }

    @Test("report: untrained は末尾、残りは回復率降順")
    func sortOrder() {
        let s = sets([.chest], hoursAgo: 6) + sets([.biceps], hoursAgo: 60)
        let rows = MuscleRecovery.report(sets: s, referenceDate: now, calendar: Self.calendar)
        let trained = Array(rows.prefix { $0.state != .untrained })
        #expect(rows.suffix(from: trained.count).allSatisfy { $0.state == .untrained })
        let fractions = trained.map(\.recoveryFraction)
        #expect(fractions == fractions.sorted(by: >))
    }

    @Test("report: daysSinceLastTrained を日数で返す")
    func daysSince() {
        let rows = MuscleRecovery.report(
            sets: sets([.chest], hoursAgo: 48), referenceDate: now, calendar: Self.calendar)
        #expect(row(rows, .chest)?.daysSinceLastTrained == 2)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter MuscleRecovery`
Expected: コンパイルエラー（`MuscleRecovery` / `MuscleRecoveryRow` / `RecoveryState` 未定義）。

- [ ] **Step 3: Implement `MuscleRecovery.swift`**

Create `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleRecovery.swift` with EXACTLY:

```swift
import Foundation

/// 部位の回復状態。
public enum RecoveryState: String, Sendable {
    case recovered  // 回復済
    case recovering  // 回復中
    case fatigued  // 疲労
    case untrained  // 未実施
}

/// 1 部位の回復状態を表す表示用の行。
public struct MuscleRecoveryRow: Sendable, Identifiable, Hashable {
    public var id: MuscleGroup { muscle }
    public let muscle: MuscleGroup
    /// 最終トレ日からの経過日数。未実施は nil。
    public let daysSinceLastTrained: Int?
    /// 回復率 0...1（バー表示用）。
    public let recoveryFraction: Double
    public let state: RecoveryState

    public init(
        muscle: MuscleGroup, daysSinceLastTrained: Int?,
        recoveryFraction: Double, state: RecoveryState
    ) {
        self.muscle = muscle
        self.daysSinceLastTrained = daysSinceLastTrained
        self.recoveryFraction = recoveryFraction
        self.state = state
    }
}

/// 部位別リカバリーの純粋計算。SetRecord の completedAt と Exercise.muscleGroups だけから導出する。
public enum MuscleRecovery {

    // 暫定定数（テストで調整可）。
    static let freeSets = 6  // これ以下のセット数は回復時間を延ばさない
    static let hoursPerExtraSet = 3.0  // freeSets 超 1 セットあたりの延長時間
    static let maxExtraHours = 24.0  // 負荷による延長の上限
    static let highRPE = 8.5  // これ以上の平均 RPE で回復時間 +rpeAdjustHours
    static let lowRPE = 6.0  // これ以下で -rpeAdjustHours
    static let rpeAdjustHours = 6.0
    static let recentTrainingDays = 10  // recoveryAdvice の対象とする「直近トレ」の窓（日）

    /// 部位別の基準回復時間（時間）。大筋群ほど長い。fullBody は untracked。
    static func baseHours(for muscle: MuscleGroup) -> Double {
        switch muscle {
        case .quads, .hamstrings, .glutes, .back: return 72
        case .chest, .shoulders: return 48
        case .biceps, .triceps, .forearms, .calves, .abs, .obliques: return 36
        case .fullBody: return 0
        }
    }

    /// 全 tracked 筋群の回復状態。並び: untrained を末尾に固定し、残りを recoveryFraction 降順
    /// （タイブレーク muscle.rawValue 昇順）。
    public static func report(
        sets: [SetRecord],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [MuscleRecoveryRow] {
        let working = sets.filter { !$0.isWarmup && $0.isCompleted }

        // muscle -> その筋群を刺激したワーキングセット
        var byMuscle: [MuscleGroup: [SetRecord]] = [:]
        for set in working {
            for group in (set.exercise?.muscleGroups ?? []) where group.weeklySetTarget.isTracked {
                byMuscle[group, default: []].append(set)
            }
        }

        let referenceDay = calendar.startOfDay(for: referenceDate)
        var rows: [MuscleRecoveryRow] = []

        for muscle in MuscleGroup.allCases where muscle.weeklySetTarget.isTracked {
            let muscleSets = byMuscle[muscle] ?? []
            guard let lastTrained = muscleSets.map(\.completedAt).max() else {
                rows.append(
                    MuscleRecoveryRow(
                        muscle: muscle, daysSinceLastTrained: nil,
                        recoveryFraction: 1.0, state: .untrained))
                continue
            }

            // 直近トレ日（同一カレンダー日）の負荷
            let lastDaySets = muscleSets.filter {
                calendar.isDate($0.completedAt, inSameDayAs: lastTrained)
            }
            let setCount = lastDaySets.count
            let rpes = lastDaySets.compactMap(\.rpe)
            let avgRPE: Double? = rpes.isEmpty ? nil : rpes.reduce(0, +) / Double(rpes.count)

            let base = baseHours(for: muscle)
            let loadExtra = min(maxExtraHours, Double(max(0, setCount - freeSets)) * hoursPerExtraSet)
            var rpeAdjust = 0.0
            if let avgRPE {
                if avgRPE >= highRPE {
                    rpeAdjust = rpeAdjustHours
                } else if avgRPE <= lowRPE {
                    rpeAdjust = -rpeAdjustHours
                }
            }
            let window = max(base * 0.5, base + loadExtra + rpeAdjust)

            let elapsedHours = referenceDate.timeIntervalSince(lastTrained) / 3600.0
            let fraction = min(max(elapsedHours / window, 0.0), 1.0)
            let days =
                calendar.dateComponents(
                    [.day], from: calendar.startOfDay(for: lastTrained), to: referenceDay
                ).day ?? 0

            let state: RecoveryState =
                fraction >= 1.0 ? .recovered : (fraction >= 0.5 ? .recovering : .fatigued)
            rows.append(
                MuscleRecoveryRow(
                    muscle: muscle, daysSinceLastTrained: days,
                    recoveryFraction: fraction, state: state))
        }

        return rows.sorted { lhs, rhs in
            let lu = lhs.state == .untrained ? 1 : 0
            let ru = rhs.state == .untrained ? 1 : 0
            if lu != ru { return lu < ru }
            if lhs.recoveryFraction != rhs.recoveryFraction {
                return lhs.recoveryFraction > rhs.recoveryFraction
            }
            return lhs.muscle.rawValue < rhs.muscle.rawValue
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter MuscleRecovery`
Expected: PASS（10件）。

> もし `set.exercise?.muscleGroups` がスタンドアロン構築で nil を返してテストが失敗する場合（SwiftData のリレーション挙動）、テストヘルパー `sets(...)` を in-memory `ModelContext`（`AnalyticsTests.makeContext` と同じ）に `context.insert(ex)` / `context.insert(set)` してから配列を返す形に切り替える。実装側 `report` は変更不要。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleRecovery.swift Packages/OikomiKit/Tests/OikomiKitTests/MuscleRecoveryTests.swift
git commit -m "feat(coaching): 部位別リカバリーの純粋関数 MuscleRecovery.report を追加"
```

---

## Task 2: `MuscleRecovery.recoveryAdvice`

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleRecovery.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/MuscleRecoveryTests.swift`

- [ ] **Step 1: Write the failing tests**

`MuscleRecoveryTests.swift` の `struct MuscleRecoveryTests` の末尾（最後の `}` の直前）に追記:

```swift
    @Test("recoveryAdvice: 回復済み（直近10日内）の筋群を1チップに集約")
    func adviceListsRecovered() {
        // biceps 回復済(48h前)、chest 疲労(6h前)
        let s = sets([.biceps], hoursAgo: 48) + sets([.chest], hoursAgo: 6)
        let advice = MuscleRecovery.recoveryAdvice(sets: s, referenceDate: now, calendar: Self.calendar)
        #expect(advice.count == 1)
        #expect(advice.first?.severity == .info)
        #expect(advice.first?.message.contains("上腕二頭筋") == true)
        #expect(advice.first?.message.contains("胸") == false)
    }

    @Test("recoveryAdvice: 未実施・10日超は対象外、対象ゼロで空")
    func adviceExcludesUntrainedAndStale() {
        // biceps を 300h(=12.5日)前 → recovered だが stale → 対象外
        let advice = MuscleRecovery.recoveryAdvice(
            sets: sets([.biceps], hoursAgo: 300), referenceDate: now, calendar: Self.calendar)
        #expect(advice.isEmpty)
    }
```

- [ ] **Step 2: Run to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter "adviceListsRecovered|adviceExcludesUntrainedAndStale"`
Expected: コンパイルエラー（`recoveryAdvice` 未定義）。

- [ ] **Step 3: Implement `recoveryAdvice`**

`MuscleRecovery.swift` の `report(...)` メソッドの直後（`enum MuscleRecovery` 内）に追加:

```swift
    /// 直近 `recentTrainingDays` 日に鍛えて今 `.recovered` の筋群を「次のトレ候補」として最大1件にまとめる。
    /// 未実施・長期未トレは対象外（ボリューム不足は MEV/MAV 側の責務）。対象ゼロなら空配列。
    public static func recoveryAdvice(
        sets: [SetRecord],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        let ready =
            report(sets: sets, referenceDate: referenceDate, calendar: calendar)
            .filter { row in
                guard let days = row.daysSinceLastTrained else { return false }
                return days <= recentTrainingDays && row.state == .recovered
            }
        guard !ready.isEmpty else { return [] }

        let shown = ready.prefix(4)
        var names = shown.map(\.muscle.displayName).joined(separator: "・")
        if ready.count > 4 { names += " など" }

        return [
            CoachingAdvice(
                title: "回復済みの部位",
                message: "\(names) が回復済みです。次のトレーニング候補です。",
                severity: .info,
                impact: 100 + Double(ready.count) * 10
            )
        ]
    }
```

> `CoachingAdvice` は `Analytics.swift` 定義の同一モジュール型。`import` 追加は不要（同 module）。

- [ ] **Step 4: Run to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter MuscleRecovery`
Expected: PASS（12件）。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleRecovery.swift Packages/OikomiKit/Tests/OikomiKitTests/MuscleRecoveryTests.swift
git commit -m "feat(coaching): 回復済み部位を提案する recoveryAdvice を追加"
```

---

## Task 3: `combinedCoachingAdvice` に回復提案を統合

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift`（`combinedCoachingAdvice` の `let all = ...` 連結）
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: Write the failing test**

`AnalyticsTests.swift` の `// MARK: - combinedCoachingAdvice（統合パイプライン）` セクション内（`combinedLimitReturnsAll` の後あたり、struct 内ならどこでも可）に追記:

```swift
    @Test("combinedCoachingAdvice: 回復済み部位の提案が統合される")
    func combinedIncludesRecovery() {
        let cal = Self.calendar
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 31, hour: 12))!
        // biceps を 48h 前に 3 セット → 回復済（base 36h）・2日前 → recoveryAdvice 発火
        let ex = Exercise(name: "カール", muscleGroups: [.biceps])
        let bicepsSets = (0..<3).map { _ in
            SetRecord(
                exercise: ex, weight: 20, reps: 10,
                completedAt: now.addingTimeInterval(-48 * 3600))
        }
        let advices = Analytics.combinedCoachingAdvice(
            sessions: [], sets: bicepsSets, records: [], readiness: nil,
            limit: 10, referenceDate: now, calendar: cal)
        #expect(advices.contains { $0.title == "回復済みの部位" })
    }
```

- [ ] **Step 2: Run to verify it fails**

Run: `swift test --package-path Packages/OikomiKit --filter combinedIncludesRecovery`
Expected: FAIL（回復提案がまだ統合リストに無い）。

- [ ] **Step 3: Add the recovery term to `combinedCoachingAdvice`**

`Analytics.swift` の `combinedCoachingAdvice(...)` 内、`let all =` の連結に `MuscleRecovery.recoveryAdvice` を追加する。現在:

```swift
        let all =
            deloadAdvice(
                sessions: sessions, sets: sets, readiness: readiness,
                referenceDate: referenceDate, calendar: calendar)
            + autoregulationAdvice(sets: sets, calendar: calendar, weightUnit: weightUnit)
            + prPredictions(
                sets: sets, records: records, calendar: calendar, weightUnit: weightUnit)
            + plateauAdvice(sets: sets, records: records, calendar: calendar)
            + volumeAdvice(from: sets, referenceDate: referenceDate, calendar: calendar)
```

を、最後に1項足して次に変更:

```swift
        let all =
            deloadAdvice(
                sessions: sessions, sets: sets, readiness: readiness,
                referenceDate: referenceDate, calendar: calendar)
            + autoregulationAdvice(sets: sets, calendar: calendar, weightUnit: weightUnit)
            + prPredictions(
                sets: sets, records: records, calendar: calendar, weightUnit: weightUnit)
            + plateauAdvice(sets: sets, records: records, calendar: calendar)
            + volumeAdvice(from: sets, referenceDate: referenceDate, calendar: calendar)
            + MuscleRecovery.recoveryAdvice(
                sets: sets, referenceDate: referenceDate, calendar: calendar)
```

doc コメント（`/// 各ジェネレータ（…）の出力を統合し、`）の列挙に「・回復」も足す（任意・整合のため）。

- [ ] **Step 4: Run to verify it passes + full suite**

Run: `swift test --package-path Packages/OikomiKit --filter combined`
Expected: PASS（既存の combined テスト群 + `combinedIncludesRecovery`）。
Run: `swift test --package-path Packages/OikomiKit 2>&1 | tail -3`
Expected: 全成功。

- [ ] **Step 5: Commit**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): combinedCoachingAdvice に部位別リカバリー提案を統合"
```

---

## Task 4: 分析タブ「部位別」に回復状態カードを追加

**Files:**
- Modify: `App/iOS/Views/Analysis/MuscleGroupAnalysisSection.swift`

- [ ] **Step 1: Add the recovery report property**

`MuscleGroupAnalysisSection.swift` の `report` 算出プロパティ（`private var report: [MuscleSetCountRow] { ... }`）の直後に追加:

```swift
    private var recoveryReport: [MuscleRecoveryRow] {
        MuscleRecovery.report(sets: sets)
    }
```

- [ ] **Step 2: Insert the recovery card into `body`**

`body` を次に変更（`setsCard` と `volumeCard` の間に `recoveryCard` を挿入）:

```swift
    var body: some View {
        VStack(spacing: OikomiSpacing.l) {
            setsCard
            recoveryCard
            volumeCard
            legendCard
        }
    }
```

- [ ] **Step 3: Add the recovery card + helpers**

`statusChip` / `barColor` 等のヘルパー群がある「MARK: - Sets per muscle」と「MARK: - Volume kg per muscle」の間（`barColor(for status:)` メソッドの直後）に、新しい MARK セクションとして追加:

```swift
    // MARK: - Recovery per muscle

    @ViewBuilder
    private var recoveryCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack {
                Label("部位の回復状態", systemImage: "bolt.heart.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            VStack(spacing: OikomiSpacing.s) {
                ForEach(recoveryReport) { row in
                    HStack(spacing: OikomiSpacing.m) {
                        Text(row.muscle.displayName)
                            .font(.callout)
                            .frame(width: 70, alignment: .leading)
                        recoveryBar(for: row)
                        Text(lastTrainedText(for: row))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                        recoveryChip(for: row)
                    }
                }
            }

            Text("基準回復時間にトレ量・強度を加味した目安です。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(OikomiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func recoveryBar(for row: MuscleRecoveryRow) -> some View {
        let displayFraction = row.state == .untrained ? 0 : row.recoveryFraction
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(OikomiColor.elevatedBackground)
                Capsule()
                    .fill(recoveryColor(for: row.state))
                    .frame(width: max(0, CGFloat(displayFraction) * geo.size.width))
            }
        }
        .frame(height: 10)
    }

    @ViewBuilder
    private func recoveryChip(for row: MuscleRecoveryRow) -> some View {
        Text(recoveryLabel(for: row.state))
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(recoveryColor(for: row.state).opacity(0.15), in: Capsule())
            .foregroundStyle(recoveryColor(for: row.state))
    }

    private func lastTrainedText(for row: MuscleRecoveryRow) -> String {
        guard let days = row.daysSinceLastTrained else { return "—" }
        return days == 0 ? "今日" : "\(days)日前"
    }

    private func recoveryLabel(for state: RecoveryState) -> String {
        switch state {
        case .recovered: return "回復済"
        case .recovering: return "回復中"
        case .fatigued: return "疲労"
        case .untrained: return "未実施"
        }
    }

    private func recoveryColor(for state: RecoveryState) -> Color {
        switch state {
        case .recovered: return OikomiColor.statGreen
        case .recovering: return OikomiColor.statOrange
        case .fatigued: return OikomiColor.statRed
        case .untrained: return .gray
        }
    }
```

> 使用トークンはすべて既存ファイル内で使用実績あり（`OikomiColor.statGreen/statOrange/statRed/elevatedBackground/cardBackground`、`OikomiSpacing.*`、`OikomiRadius.card`）。SF Symbol `bolt.heart.fill` は iOS 16+ で利用可。

- [ ] **Step 4: Build the iOS app**

Run:
```bash
xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | head -20
```
Expected: `** BUILD SUCCEEDED **`。（`MuscleRecovery.swift` は既存の `Packages/OikomiKit` 内なので regen 不要。`MuscleGroupAnalysisSection.swift` も既存ファイルの編集なので regen 不要。）

- [ ] **Step 5: Commit**

```bash
git add App/iOS/Views/Analysis/MuscleGroupAnalysisSection.swift
git commit -m "feat(analysis): 部位別タブに回復状態カードを追加"
```

---

## Task 5: 全体検証

**Files:** なし（検証のみ。整形差分が出たらコミット）

- [ ] **Step 1: OikomiKit 全テスト**

Run: `swift test --package-path Packages/OikomiKit`
Expected: 既存（210）+ 新規（MuscleRecovery 12 + combined 統合 1）すべて PASS。失敗時は `superpowers:systematic-debugging` で原因特定（推測修正しない）。

- [ ] **Step 2: iOS ビルド**

Run: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | head`
Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 3: 整形と lint**

Run: `xcrun swift-format lint --recursive --configuration .swift-format App Packages/OikomiKit/Sources Packages/OikomiKit/Tests 2>&1 | grep -v "SilentSetAlternateIcon" | head`
Expected: 出力なし（新規違反ゼロ。既存の `SilentSetAlternateIcon` 警告のみ無視）。差分が出る場合は `xcrun swift-format format --in-place --recursive --configuration .swift-format App Packages/OikomiKit/Sources Packages/OikomiKit/Tests` のうえ:
```bash
git add -A && git commit -m "style: swift-format 整形"
```

- [ ] **Step 4: シナリオ確認（手動・任意）**

`xcrun simctl` / Xcode で起動し、分析タブ「部位別」に「部位の回復状態」カードが出る／最近鍛えた部位が回復中→回復済と推移する／未実施部位が「未実施」表示。Home/全件コーチングに「回復済みの部位」チップが出る（回復済み部位がある時）。

---

## Self-Review（この計画の自己点検）

**1. Spec coverage（設計書 §4 の各項目 → タスク）**
- §4.1 回復モデル（基準時間/負荷伸縮/RPE/回復率/4状態）→ Task 1 `report` ✅
- §4.2 値型・API（RecoveryState / MuscleRecoveryRow / report / recoveryAdvice / 新ファイル分離）→ Task 1 + Task 2 ✅
- §4.3 コーチング提案（直近10日・回復済の集約・最大1件・未実施除外）→ Task 2 ✅
- §4.3 combinedCoachingAdvice 統合 → Task 3 ✅
- §4.4 露出（部位別タブ・バー・状態チップ・最終N日前・ソート）→ Task 4 ✅
- §6 テスト → Task 1/2/3 に分散、§7 エッジ（同日合算・compound・未実施・warmup・RPE欠損・fullBody除外）→ Task 1 テストで網羅 ✅
- 完了の定義（テスト/build/format/lint）→ Task 5 ✅

**2. Placeholder scan:** 「TBD/後で」なし。各コードステップは実コード掲載。Task 1 Step 4 のスタンドアロン懸念はフォールバック手順つき（プレースホルダではなく具体手順）。

**3. Type consistency:**
- `RecoveryState`（recovered/recovering/fatigued/untrained）/ `MuscleRecoveryRow`（muscle/daysSinceLastTrained/recoveryFraction/state）は Task 1 定義、Task 2/4 で同名参照。✅
- `MuscleRecovery.report` / `MuscleRecovery.recoveryAdvice` のシグネチャは Task 1/2 定義、Task 3（combined）・Task 4（report）で一致。✅
- `CoachingAdvice(title:message:severity:impact:)` / `.info` は既存定義と一致。✅
- 既存トークン（`OikomiColor.*`/`OikomiSpacing.*`/`OikomiRadius.card`）・`MuscleGroup.displayName`・`weeklySetTarget.isTracked` は実在（参照済み）。✅

---

## Execution Handoff

実装計画は `docs/superpowers/plans/2026-05-31-muscle-recovery.md` に保存。2 つの実行方法:

1. **Subagent-Driven（推奨）** — タスクごとに新サブエージェント＋2段階レビュー（仕様適合→コード品質）。
2. **Inline Execution** — このセッションで `superpowers:executing-plans` を用いバッチ実行＋チェックポイント。

どちらで進めますか？

# NLP 月次振り返り（Spec 3）実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apple Intelligence / Foundation Models（オンデバイス）で、月の構造化データから自然言語の月次振り返りを生成・保存・表示する。

**Architecture:** ビジネスロジック（月次ダイジェスト・プロンプト生成・永続化）は `OikomiKit` の純粋関数/`@Model` に置きテスト可能にする。端末依存の LLM 呼び出し・`@Generable` 出力型・UI は **iOS アプリターゲット**に隔離し、watchOS（Apple Intelligence 非対応）を汚染しない。対応機種で点灯する Pro ボーナス。

**Tech Stack:** Swift / SwiftUI / SwiftData / FoundationModels(iOS 26) / Swift Testing / OikomiKit(SPM)

**設計書:** `docs/superpowers/specs/2026-05-31-nlp-monthly-summary-design.md`

**検証 API（Web 検証済み）:**
- 可用性: `switch SystemLanguageModel.default.availability { case .available: …; case .unavailable(let reason): … }`
- セッション: `LanguageModelSession { "instructions…" }`
- 構造化生成: `try await session.respond(to: prompt, generating: MonthlySummaryContent.self).content`
- `@Generable struct` + `@Guide(description: "…")`

**検証コマンド:**
- ユニットテスト: `swift test --package-path Packages/OikomiKit`
- iOS ビルド（= /build）: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`
- `.xcodeproj` 再生成（新規ファイル追加後に必要なら）: `xcodegen generate`（= /regen）
- lint: `swift-format lint`

> **重要（新規ファイルとビルド）:** 本プロジェクトは XcodeGen 管理。新規ファイルを追加したタスクで iOS ビルドする前に `xcodegen generate` が必要な場合がある（OikomiKit は SPM なので `swift test` には不要）。iOS ビルドを行う Task 6〜8 では、ビルド前に必ず `xcodegen generate` を実行する。

---

## ファイル構成

| 区分 | パス | 責務 |
|---|---|---|
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/ReadinessScore.swift` | `band(for:)` DRY ヘルパー |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlyDigest.swift` | digest 型 + build |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlySummaryPrompt.swift` | prompt 生成 |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Models/MonthlySummary.swift` | @Model（swift-data-modeler） |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/OikomiKit.swift` | `schemaModels` に登録 |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Repositories/MonthlySummaryRepository.swift` | CRUD |
| 新規 | `App/iOS/Intelligence/MonthlySummaryContent.swift` | @Generable |
| 新規 | `App/iOS/Intelligence/MonthlySummaryGenerator.swift` | FM ラッパー + 可用性 |
| 新規 | `App/iOS/Views/MonthlySummaryView.swift` | 月次振り返り詳細画面 |
| 新規 | `App/iOS/Views/MonthlySummaryHistoryView.swift` | 履歴一覧 |
| 改修 | `App/iOS/Views/HomeView.swift` | 「先月の振り返り」カード |
| 改修 | `App/iOS/Views/AnalysisTabView.swift` | 履歴へのエントリ |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/MonthlyDigestTests.swift` | テスト |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryPromptTests.swift` | テスト |
| 新規 | `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryRepositoryTests.swift` | テスト |

---

## Task 1: ReadinessScore.band(for:) DRY ヘルパー

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/ReadinessScore.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/ReadinessScoreTests.swift`（既存に追記）

`compute(...)` 内の閾値 `value < 40 ? .low : (value < 70 ? .normal : .high)` を再利用可能な static にする（MonthlyDigest が使う）。

- [ ] **Step 1: 失敗するテストを追記**

`ReadinessScoreTests.swift` の `struct` 本体に追記（テスト suite 名は既存ファイルに合わせる）:

```swift
    @Test("band(for:) の閾値: <40 low / 40..<70 normal / >=70 high")
    func bandForValue() {
        #expect(ReadinessScore.band(for: 0) == .low)
        #expect(ReadinessScore.band(for: 39) == .low)
        #expect(ReadinessScore.band(for: 40) == .normal)
        #expect(ReadinessScore.band(for: 69) == .normal)
        #expect(ReadinessScore.band(for: 70) == .high)
        #expect(ReadinessScore.band(for: 100) == .high)
    }
```

- [ ] **Step 2: 失敗確認**

Run: `swift test --package-path Packages/OikomiKit --filter bandForValue`
Expected: コンパイルエラー（`band(for:)` 未定義）

- [ ] **Step 3: ヘルパーを追加し compute() で再利用**

`ReadinessScore.swift` に static メソッドを追加（`struct ReadinessScore` 本体内）:

```swift
    /// スコア値からバンドを決める。compute() と月次集計で共有する。
    public static func band(for value: Int) -> Band {
        value < 40 ? .low : (value < 70 ? .normal : .high)
    }
```

`compute(...)` 内の `let band: Band = value < 40 ? .low : (value < 70 ? .normal : .high)` を次へ置換:

```swift
        let band = Self.band(for: value)
```

- [ ] **Step 4: テスト通過**

Run: `swift test --package-path Packages/OikomiKit --filter ReadinessScore`
Expected: PASS（既存 + 新規）

- [ ] **Step 5: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/ReadinessScore.swift Packages/OikomiKit/Tests/OikomiKitTests/ReadinessScoreTests.swift
git commit -m "refactor(coaching): ReadinessScore.band(for:) を抽出（月次集計と共有）"
```

---

## Task 2: 月次ダイジェスト（MonthlyDigest）

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlyDigest.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/MonthlyDigestTests.swift`

依存（確認済み）: `Analytics.setCountByMuscleGroup(sets:in:) -> [MuscleGroup:Int]`、`MuscleGroup.weeklySetTarget(for:profile) -> WeeklySetTarget{mev,mav,isTracked}`、`ReadinessScore.band(for:)`、`SetRecord{weight:Double?, reps:Int?, isWarmup, isCompleted, completedAt, exercise}`、`WorkoutSession{startedAt, endedAt:Date?}`、`PersonalRecord{achievedAt, exercise, weight, reps, estimated1RM}`、`HealthSnapshot{date, readinessScore:Int?}`、`BodyPhaseResult`。

- [ ] **Step 1: 失敗するテストを書く**

Create `Packages/OikomiKit/Tests/OikomiKitTests/MonthlyDigestTests.swift`:

```swift
import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("MonthlyDigest")
@MainActor
struct MonthlyDigestTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2
        return cal
    }()

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    @Test("対象月に完了セッションが無ければ nil")
    func nilWhenEmpty() throws {
        let digest = MonthlyDigest.build(
            sessions: [], sets: [], records: [], snapshots: [],
            yearMonth: "2026-05", calendar: Self.calendar)
        #expect(digest == nil)
    }

    @Test("当月のセッション数・トレ日数・総ボリュームを集計")
    func aggregatesBasics() throws {
        let context = try Self.makeContext()
        let bench = Exercise(name: "ベンチプレス", muscleGroups: [.chest])
        context.insert(bench)
        // 当月 2 セッション（別日）、各 working set 1 つ。前月のセッションは除外される。
        let s1 = WorkoutSession(startedAt: date(2026, 5, 10)); s1.endedAt = date(2026, 5, 10)
        let s2 = WorkoutSession(startedAt: date(2026, 5, 20)); s2.endedAt = date(2026, 5, 20)
        let prev = WorkoutSession(startedAt: date(2026, 4, 25)); prev.endedAt = date(2026, 4, 25)
        let set1 = SetRecord(exercise: bench, weight: 60, reps: 10); set1.session = s1; set1.completedAt = date(2026, 5, 10)
        let set2 = SetRecord(exercise: bench, weight: 60, reps: 10); set2.session = s2; set2.completedAt = date(2026, 5, 20)
        let setPrev = SetRecord(exercise: bench, weight: 100, reps: 10); setPrev.session = prev; setPrev.completedAt = date(2026, 4, 25)
        for o in [s1, s2, prev, set1, set2, setPrev] as [any PersistentModel] { context.insert(o) }

        let digest = MonthlyDigest.build(
            sessions: [s1, s2, prev], sets: [set1, set2, setPrev], records: [], snapshots: [],
            yearMonth: "2026-05", calendar: Self.calendar)

        #expect(digest?.sessionCount == 2)
        #expect(digest?.trainingDays == 2)
        #expect(digest?.totalVolumeKg == 1200)  // 60*10 * 2、前月分は除外
        #expect(digest?.muscleSetCounts.first?.muscle == .chest)
        #expect(digest?.isSubstantial == false)  // セッション 2 < 4
    }

    @Test("当月達成 PR のみ抽出")
    func extractsMonthPRs() throws {
        let context = try Self.makeContext()
        let bench = Exercise(name: "ベンチプレス", muscleGroups: [.chest])
        context.insert(bench)
        let s = WorkoutSession(startedAt: date(2026, 5, 5)); s.endedAt = date(2026, 5, 5)
        let set = SetRecord(exercise: bench, weight: 80, reps: 5); set.session = s; set.completedAt = date(2026, 5, 5)
        let prThis = PersonalRecord(exercise: bench, weight: 80, reps: 5, estimated1RM: 93, achievedAt: date(2026, 5, 5))
        let prPrev = PersonalRecord(exercise: bench, weight: 70, reps: 5, estimated1RM: 81, achievedAt: date(2026, 4, 5))
        for o in [s, set, prThis, prPrev] as [any PersistentModel] { context.insert(o) }

        let digest = MonthlyDigest.build(
            sessions: [s], sets: [set], records: [prThis, prPrev], snapshots: [],
            yearMonth: "2026-05", calendar: Self.calendar)
        #expect(digest?.personalRecords.count == 1)
        #expect(digest?.personalRecords.first?.exerciseName == "ベンチプレス")
    }

    @Test("readiness 平均とバンド別日数を集計")
    func aggregatesReadiness() throws {
        let context = try Self.makeContext()
        let s = WorkoutSession(startedAt: date(2026, 5, 5)); s.endedAt = date(2026, 5, 5)
        let set = SetRecord(exercise: Exercise(name: "X"), weight: 50, reps: 5); set.session = s; set.completedAt = date(2026, 5, 5)
        let snapLow = HealthSnapshot(date: date(2026, 5, 5), readinessScore: 30)
        let snapHigh = HealthSnapshot(date: date(2026, 5, 6), readinessScore: 80)
        for o in [s, set.exercise!, set, snapLow, snapHigh] as [any PersistentModel] { context.insert(o) }

        let digest = MonthlyDigest.build(
            sessions: [s], sets: [set], records: [], snapshots: [snapLow, snapHigh],
            yearMonth: "2026-05", calendar: Self.calendar)
        #expect(digest?.readiness?.average == 55)
        #expect(digest?.readiness?.lowDays == 1)
        #expect(digest?.readiness?.highDays == 1)
    }
}
```

- [ ] **Step 2: 失敗確認**

Run: `swift test --package-path Packages/OikomiKit --filter MonthlyDigest`
Expected: コンパイルエラー（`MonthlyDigest` 未定義）

- [ ] **Step 3: 実装を書く**

Create `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlyDigest.swift`:

```swift
import Foundation

/// 月次振り返りの素材となる構造化ダイジェスト。
public struct MonthlyTrainingDigest: Sendable, Hashable {
    public let yearMonth: String
    public let sessionCount: Int
    public let trainingDays: Int
    public let totalVolumeKg: Double
    public let muscleSetCounts: [MonthlyMuscleVolume]
    public let underTrainedMuscles: [MuscleGroup]
    public let personalRecords: [MonthlyPR]
    public let readiness: MonthlyReadiness?
    public let bodyPhase: BodyPhaseResult?

    public var isSubstantial: Bool { sessionCount >= 4 }

    public init(
        yearMonth: String, sessionCount: Int, trainingDays: Int, totalVolumeKg: Double,
        muscleSetCounts: [MonthlyMuscleVolume], underTrainedMuscles: [MuscleGroup],
        personalRecords: [MonthlyPR], readiness: MonthlyReadiness?, bodyPhase: BodyPhaseResult?
    ) {
        self.yearMonth = yearMonth
        self.sessionCount = sessionCount
        self.trainingDays = trainingDays
        self.totalVolumeKg = totalVolumeKg
        self.muscleSetCounts = muscleSetCounts
        self.underTrainedMuscles = underTrainedMuscles
        self.personalRecords = personalRecords
        self.readiness = readiness
        self.bodyPhase = bodyPhase
    }
}

public struct MonthlyMuscleVolume: Sendable, Hashable {
    public let muscle: MuscleGroup
    public let sets: Int
    public init(muscle: MuscleGroup, sets: Int) { self.muscle = muscle; self.sets = sets }
}

public struct MonthlyPR: Sendable, Hashable {
    public let exerciseName: String
    public let weight: Double
    public let reps: Int
    public let estimated1RM: Double
    public init(exerciseName: String, weight: Double, reps: Int, estimated1RM: Double) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.estimated1RM = estimated1RM
    }
}

public struct MonthlyReadiness: Sendable, Hashable {
    public let average: Int
    public let lowDays: Int
    public let normalDays: Int
    public let highDays: Int
    public init(average: Int, lowDays: Int, normalDays: Int, highDays: Int) {
        self.average = average
        self.lowDays = lowDays
        self.normalDays = normalDays
        self.highDays = highDays
    }
}

public enum MonthlyDigest {
    /// 指定年月（"yyyy-MM"）のデータからダイジェストを構築。完了セッションが無ければ nil。
    /// bodyPhase は端末依存（HealthKit）のため呼び出し側で取得して渡す。
    public static func build(
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        snapshots: [HealthSnapshot],
        yearMonth: String,
        profile: TrainingProfile = .default,
        bodyPhase: BodyPhaseResult? = nil,
        calendar: Calendar = .current
    ) -> MonthlyTrainingDigest? {
        guard let range = monthRange(yearMonth: yearMonth, calendar: calendar) else { return nil }

        let monthSessions = sessions.filter { $0.endedAt != nil && range.contains($0.startedAt) }
        guard !monthSessions.isEmpty else { return nil }

        let trainingDays = Set(monthSessions.map { calendar.startOfDay(for: $0.startedAt) }).count

        let workingSets = sets.filter {
            range.contains($0.completedAt) && !$0.isWarmup && $0.isCompleted
        }
        let totalVolume = workingSets.reduce(0.0) { acc, set in
            guard let w = set.weight, let r = set.reps else { return acc }
            return acc + w * Double(r)
        }

        let counts = Analytics.setCountByMuscleGroup(sets: sets, in: range)
        let muscleSetCounts = counts
            .map { MonthlyMuscleVolume(muscle: $0.key, sets: $0.value) }
            .sorted { $0.sets > $1.sets }

        let weeks = max(1.0, weeksInMonth(range: range, calendar: calendar))
        let underTrained = muscleSetCounts.compactMap { row -> MuscleGroup? in
            let target = row.muscle.weeklySetTarget(for: profile)
            guard target.isTracked, target.mev > 0 else { return nil }
            let weeklyAverage = Double(row.sets) / weeks
            return weeklyAverage < Double(target.mev) ? row.muscle : nil
        }

        let monthPRs = records
            .filter { range.contains($0.achievedAt) }
            .sorted { $0.estimated1RM > $1.estimated1RM }
            .compactMap { pr -> MonthlyPR? in
                guard let exercise = pr.exercise else { return nil }
                return MonthlyPR(
                    exerciseName: exercise.name, weight: pr.weight,
                    reps: pr.reps, estimated1RM: pr.estimated1RM)
            }

        let scores = snapshots
            .filter { range.contains($0.date) }
            .compactMap { $0.readinessScore }
        let readiness: MonthlyReadiness?
        if scores.isEmpty {
            readiness = nil
        } else {
            let average = scores.reduce(0, +) / scores.count
            let low = scores.filter { ReadinessScore.band(for: $0) == .low }.count
            let normal = scores.filter { ReadinessScore.band(for: $0) == .normal }.count
            let high = scores.filter { ReadinessScore.band(for: $0) == .high }.count
            readiness = MonthlyReadiness(average: average, lowDays: low, normalDays: normal, highDays: high)
        }

        return MonthlyTrainingDigest(
            yearMonth: yearMonth,
            sessionCount: monthSessions.count,
            trainingDays: trainingDays,
            totalVolumeKg: totalVolume,
            muscleSetCounts: muscleSetCounts,
            underTrainedMuscles: underTrained,
            personalRecords: monthPRs,
            readiness: readiness,
            bodyPhase: bodyPhase
        )
    }

    /// "yyyy-MM" → その月全体を含む ClosedRange<Date>。不正な文字列は nil。
    static func monthRange(yearMonth: String, calendar: Calendar) -> ClosedRange<Date>? {
        let parts = yearMonth.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return nil }
        var startComps = DateComponents()
        startComps.year = year
        startComps.month = month
        startComps.day = 1
        guard let start = calendar.date(from: startComps),
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start),
            let end = calendar.date(byAdding: .second, value: -1, to: nextMonth)
        else { return nil }
        return start...end
    }

    private static func weeksInMonth(range: ClosedRange<Date>, calendar: Calendar) -> Double {
        let days = (calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day ?? 29) + 1
        return Double(days) / 7.0
    }
}
```

- [ ] **Step 4: テスト通過**

Run: `swift test --package-path Packages/OikomiKit --filter MonthlyDigest`
Expected: PASS（4 テスト）

- [ ] **Step 5: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlyDigest.swift Packages/OikomiKit/Tests/OikomiKitTests/MonthlyDigestTests.swift
git commit -m "feat(coaching): 月次ダイジェスト（MonthlyDigest）を追加"
```

---

## Task 3: プロンプト生成（MonthlySummaryPrompt）

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlySummaryPrompt.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryPromptTests.swift`

- [ ] **Step 1: 失敗するテストを書く**

Create `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryPromptTests.swift`:

```swift
import Foundation
import Testing

@testable import OikomiKit

@Suite("MonthlySummaryPrompt")
struct MonthlySummaryPromptTests {

    private func digest() -> MonthlyTrainingDigest {
        MonthlyTrainingDigest(
            yearMonth: "2026-05",
            sessionCount: 12,
            trainingDays: 12,
            totalVolumeKg: 48000,
            muscleSetCounts: [MonthlyMuscleVolume(muscle: .chest, sets: 40)],
            underTrainedMuscles: [.hamstrings],
            personalRecords: [MonthlyPR(exerciseName: "ベンチプレス", weight: 100, reps: 3, estimated1RM: 110)],
            readiness: MonthlyReadiness(average: 62, lowDays: 2, normalDays: 8, highDays: 5),
            bodyPhase: BodyPhaseResult(phase: .cut, kgPerMonth: -1.5)
        )
    }

    @Test("prompt に主要事実が含まれる")
    func promptContainsFacts() {
        let payload = MonthlySummaryPrompt.make(from: digest())
        #expect(payload.prompt.contains("2026-05"))
        #expect(payload.prompt.contains("ベンチプレス"))
        #expect(payload.prompt.contains("12"))            // セッション/トレ日数
        #expect(payload.prompt.contains("ハムストリング"))  // underTrained 部位の displayName
        #expect(payload.prompt.contains("減量期"))          // bodyPhase displayName
    }

    @Test("instructions に制約文言が含まれる")
    func instructionsHaveGuardrails() {
        let payload = MonthlySummaryPrompt.make(from: digest())
        #expect(payload.instructions.contains("日本語"))
        #expect(!payload.instructions.isEmpty)
    }
}
```

- [ ] **Step 2: 失敗確認**

Run: `swift test --package-path Packages/OikomiKit --filter MonthlySummaryPrompt`
Expected: コンパイルエラー

- [ ] **Step 3: 実装を書く**

Create `Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlySummaryPrompt.swift`:

```swift
import Foundation

/// 月次ダイジェストを Foundation Models 用の (instructions, prompt) に変換する純粋関数。
public enum MonthlySummaryPrompt {

    public struct Payload: Sendable, Hashable {
        public let instructions: String
        public let prompt: String
        public init(instructions: String, prompt: String) {
            self.instructions = instructions
            self.prompt = prompt
        }
    }

    public static func make(from digest: MonthlyTrainingDigest, weightUnit: WeightUnit = .kg) -> Payload {
        let instructions = """
            あなたは筋力トレーニングのコーチです。以下の月次データだけを根拠に、日本語で簡潔な振り返りを書いてください。
            - データに無い事実を作らない。数値を誇張しない。
            - 医療・診断的な助言はしない。
            - headline は1文。highlights は良かった点を2〜3個。watchPoints は気になる点を1〜3個。nextFocus は来月の具体的フォーカスを1〜2個。
            - 前向きで具体的に。各項目は短く。
            """

        var lines: [String] = []
        lines.append("対象月: \(digest.yearMonth)")
        lines.append("トレーニング回数: \(digest.sessionCount) 回 / トレーニング日数: \(digest.trainingDays) 日")
        let volume = Int(weightUnit.fromKilograms(digest.totalVolumeKg).rounded())
        lines.append("総ボリューム: 約 \(volume) \(weightUnit.symbol)")

        if !digest.muscleSetCounts.isEmpty {
            let top = digest.muscleSetCounts.prefix(5)
                .map { "\($0.muscle.displayName) \($0.sets)セット" }
                .joined(separator: "、")
            lines.append("部位別セット数（多い順）: \(top)")
        }
        if !digest.underTrainedMuscles.isEmpty {
            let under = digest.underTrainedMuscles.map(\.displayName).joined(separator: "、")
            lines.append("ボリュームが少なめの部位（週平均が MEV 未満）: \(under)")
        }
        if digest.personalRecords.isEmpty {
            lines.append("今月の自己ベスト更新: なし")
        } else {
            let prs = digest.personalRecords.prefix(5).map { pr -> String in
                let oneRM = Int(weightUnit.fromKilograms(pr.estimated1RM).rounded())
                return "\(pr.exerciseName)（推定1RM \(oneRM)\(weightUnit.symbol)）"
            }.joined(separator: "、")
            lines.append("今月の自己ベスト更新: \(prs)")
        }
        if let readiness = digest.readiness {
            lines.append(
                "コンディションスコア: 平均 \(readiness.average)（好調 \(readiness.highDays)日 / 普通 \(readiness.normalDays)日 / 低調 \(readiness.lowDays)日）")
        }
        if let phase = digest.bodyPhase {
            let perMonth = String(format: "%.1f", abs(phase.kgPerMonth))
            let sign = phase.kgPerMonth >= 0 ? "+" : "-"
            lines.append("体重トレンド: \(phase.phase.displayName)（\(sign)\(perMonth) kg/月）")
        }

        let prompt = "次の月次トレーニングデータを振り返ってください。\n\n" + lines.joined(separator: "\n")
        return Payload(instructions: instructions, prompt: prompt)
    }
}
```

- [ ] **Step 4: テスト通過**

Run: `swift test --package-path Packages/OikomiKit --filter MonthlySummaryPrompt`
Expected: PASS（2 テスト）

> 注: テストは `MuscleGroup.hamstrings.displayName == "ハムストリング"` を仮定。実 displayName が異なる場合、テストの期待値を実値に合わせる（`Enums.swift` を確認）。

- [ ] **Step 5: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/MonthlySummaryPrompt.swift Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryPromptTests.swift
git commit -m "feat(coaching): 月次サマリのプロンプト生成を追加"
```

---

## Task 4: MonthlySummary @Model（swift-data-modeler 必須）+ スキーマ登録

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Models/MonthlySummary.swift`
- Modify: `Packages/OikomiKit/Sources/OikomiKit/OikomiKit.swift`

> **このタスクは `swift-data-modeler` サブエージェントで実施すること**（CLAUDE.md 規律 4）。CloudKit 互換: 全プロパティ Optional/デフォルト、`@Attribute(.unique)` 不使用、relationship なし。プロジェクトはフラットスキーマ（VersionedSchema 未使用）で、本件は純粋な新規エンティティ追加 → 軽量マイグレーションが自動処理、`SchemaMigrationPlan` 不要。

- [ ] **Step 1: @Model を作成**

Create `Packages/OikomiKit/Sources/OikomiKit/Models/MonthlySummary.swift`:

```swift
import Foundation
import SwiftData

/// Foundation Models が生成した月次振り返りの保存表現。CloudKit 互換（全プロパティにデフォルト値）。
@Model
public final class MonthlySummary {
    public var yearMonth: String = ""        // "2026-05"
    public var headline: String = ""
    public var highlights: [String] = []
    public var watchPoints: [String] = []
    public var nextFocus: [String] = []
    public var generatedAt: Date = Date()

    public init(
        yearMonth: String = "",
        headline: String = "",
        highlights: [String] = [],
        watchPoints: [String] = [],
        nextFocus: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.yearMonth = yearMonth
        self.headline = headline
        self.highlights = highlights
        self.watchPoints = watchPoints
        self.nextFocus = nextFocus
        self.generatedAt = generatedAt
    }
}
```

- [ ] **Step 2: schemaModels に登録**

`OikomiKit.swift` の `schemaModels` 配列末尾に追加:

```swift
        PersonalRecord.self,
        MonthlySummary.self,
    ]
```

- [ ] **Step 3: ビルド確認**

Run: `swift build --package-path Packages/OikomiKit`
Expected: ビルド成功

- [ ] **Step 4: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Models/MonthlySummary.swift Packages/OikomiKit/Sources/OikomiKit/OikomiKit.swift
git commit -m "feat(model): MonthlySummary @Model を追加しスキーマ登録"
```

---

## Task 5: MonthlySummaryRepository

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Repositories/MonthlySummaryRepository.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryRepositoryTests.swift`

既存 Repository パターン（`@MainActor public final class ... { private let context: ModelContext; init(context:); FetchDescriptor/insert/save }`）に合わせる。

- [ ] **Step 1: 失敗するテストを書く**

Create `Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryRepositoryTests.swift`:

```swift
import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("MonthlySummaryRepository")
@MainActor
struct MonthlySummaryRepositoryTests {

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    @Test("保存して yearMonth で取得できる")
    func saveAndFetch() throws {
        let repo = MonthlySummaryRepository(context: try Self.makeContext())
        _ = try repo.save(yearMonth: "2026-05", headline: "良い月", highlights: ["PR更新"], watchPoints: [], nextFocus: ["脚を増やす"])
        let fetched = try repo.summary(forYearMonth: "2026-05")
        #expect(fetched?.headline == "良い月")
        #expect(try repo.summary(forYearMonth: "2026-04") == nil)
    }

    @Test("同じ yearMonth の再保存は上書き（重複生成しない）")
    func upsert() throws {
        let repo = MonthlySummaryRepository(context: try Self.makeContext())
        _ = try repo.save(yearMonth: "2026-05", headline: "v1", highlights: [], watchPoints: [], nextFocus: [])
        _ = try repo.save(yearMonth: "2026-05", headline: "v2", highlights: [], watchPoints: [], nextFocus: [])
        #expect(try repo.allSummaries().count == 1)
        #expect(try repo.summary(forYearMonth: "2026-05")?.headline == "v2")
    }

    @Test("履歴は generatedAt 降順")
    func historyOrder() throws {
        let repo = MonthlySummaryRepository(context: try Self.makeContext())
        _ = try repo.save(yearMonth: "2026-04", headline: "4月", highlights: [], watchPoints: [], nextFocus: [])
        _ = try repo.save(yearMonth: "2026-05", headline: "5月", highlights: [], watchPoints: [], nextFocus: [])
        let all = try repo.allSummaries()
        #expect(all.first?.yearMonth == "2026-05")
    }
}
```

- [ ] **Step 2: 失敗確認**

Run: `swift test --package-path Packages/OikomiKit --filter MonthlySummaryRepository`
Expected: コンパイルエラー

- [ ] **Step 3: 実装を書く**

Create `Packages/OikomiKit/Sources/OikomiKit/Repositories/MonthlySummaryRepository.swift`:

```swift
import Foundation
import SwiftData

@MainActor
public final class MonthlySummaryRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 指定年月のサマリを返す。無ければ nil。
    public func summary(forYearMonth yearMonth: String) throws -> MonthlySummary? {
        var descriptor = FetchDescriptor<MonthlySummary>(
            predicate: #Predicate { $0.yearMonth == yearMonth })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// 全サマリを generatedAt 降順で返す。
    public func allSummaries() throws -> [MonthlySummary] {
        let descriptor = FetchDescriptor<MonthlySummary>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    /// 同 yearMonth があれば上書き、無ければ新規作成して保存する。
    @discardableResult
    public func save(
        yearMonth: String,
        headline: String,
        highlights: [String],
        watchPoints: [String],
        nextFocus: [String]
    ) throws -> MonthlySummary {
        let summary = try self.summary(forYearMonth: yearMonth) ?? {
            let new = MonthlySummary(yearMonth: yearMonth)
            context.insert(new)
            return new
        }()
        summary.headline = headline
        summary.highlights = highlights
        summary.watchPoints = watchPoints
        summary.nextFocus = nextFocus
        summary.generatedAt = Date()
        try context.save()
        return summary
    }
}
```

- [ ] **Step 4: テスト通過**

Run: `swift test --package-path Packages/OikomiKit`
Expected: 全 PASS（既存 + Task1/2/5）

- [ ] **Step 5: コミット**

```bash
git add Packages/OikomiKit/Sources/OikomiKit/Repositories/MonthlySummaryRepository.swift Packages/OikomiKit/Tests/OikomiKitTests/MonthlySummaryRepositoryTests.swift
git commit -m "feat(repo): MonthlySummaryRepository（保存/取得/履歴/upsert）を追加"
```

---

## Task 6: @Generable 出力型 + FM 生成ラッパー（iOS）

**Files:**
- Create: `App/iOS/Intelligence/MonthlySummaryContent.swift`
- Create: `App/iOS/Intelligence/MonthlySummaryGenerator.swift`

iOS ターゲットは iOS 26+ で FoundationModels が常に利用可能のため `import FoundationModels` を直接書く（watchOS には本ファイルを含めない）。自動テスト対象外（端末依存）。ビルドで検証。

- [ ] **Step 1: @Generable 出力型**

Create `App/iOS/Intelligence/MonthlySummaryContent.swift`:

```swift
import FoundationModels

/// Foundation Models の guided generation 出力。各フィールドは日本語。
@Generable
struct MonthlySummaryContent {
    @Guide(description: "その月のトレーニングを1文で総括する見出し（日本語）")
    var headline: String

    @Guide(description: "良かった点・成果を表す短い文。2〜3個（日本語）")
    var highlights: [String]

    @Guide(description: "気になる点・改善余地を表す短い文。1〜3個（日本語）")
    var watchPoints: [String]

    @Guide(description: "来月のフォーカス・具体的な提案。1〜2個（日本語）")
    var nextFocus: [String]
}
```

> 件数は instructions（Task 3）でも要求済み。配列件数を厳密化したい場合は `@Guide(.count(2...3))` 等を併用できるか SDK で確認のうえ追加してよい（不可なら description のみで可）。

- [ ] **Step 2: FM ラッパー + 可用性**

Create `App/iOS/Intelligence/MonthlySummaryGenerator.swift`:

```swift
import Foundation
import FoundationModels
import OikomiKit

enum MonthlySummaryAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

enum MonthlySummaryError: Error {
    case unavailable
}

struct MonthlySummaryGenerator {

    /// 端末の Apple Intelligence 可用性。
    static func availability() -> MonthlySummaryAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason: "\(reason)")
        @unknown default:
            return .unavailable(reason: "unknown")
        }
    }

    /// プロンプトから月次サマリ本文を生成する。
    func generate(payload: MonthlySummaryPrompt.Payload) async throws -> MonthlySummaryContent {
        guard case .available = Self.availability() else { throw MonthlySummaryError.unavailable }
        let session = LanguageModelSession {
            payload.instructions
        }
        let response = try await session.respond(to: payload.prompt, generating: MonthlySummaryContent.self)
        return response.content
    }
}
```

- [ ] **Step 3: プロジェクト再生成 + ビルド**

Run: `xcodegen generate`
Run: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`
Expected: `** BUILD SUCCEEDED **`

> ビルドが `respond(to:generating:)` や `@Guide` でエラーになる場合、FoundationModels の正確なシグネチャを WebSearch で再確認して最小調整する（例: `respond(to: Prompt(payload.prompt), generating:)`、`LanguageModelSession(instructions:)` 形式）。

- [ ] **Step 4: コミット**

```bash
git add App/iOS/Intelligence/MonthlySummaryContent.swift App/iOS/Intelligence/MonthlySummaryGenerator.swift project.yml Oikomi.xcodeproj
git commit -m "feat(ai): @Generable 月次サマリ出力型と FM 生成ラッパーを追加"
```

---

## Task 7: 月次振り返り詳細画面 + 履歴一覧（iOS）

**Files:**
- Create: `App/iOS/Views/MonthlySummaryView.swift`
- Create: `App/iOS/Views/MonthlySummaryHistoryView.swift`

既存カード様式（`OikomiSpacing` / `OikomiColor` / `OikomiRadius`、`BodyAnalysisSection` のカード）に合わせる。

- [ ] **Step 1: 詳細画面**

Create `App/iOS/Views/MonthlySummaryView.swift`:

```swift
import OikomiKit
import SwiftUI

/// 1 か月分の振り返りを表示する詳細画面。
struct MonthlySummaryView: View {
    let summary: MonthlySummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OikomiSpacing.l) {
                Text(summary.headline)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(OikomiSpacing.l)
                    .background(
                        OikomiColor.cardBackground,
                        in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))

                section(title: "ハイライト", systemImage: "star.fill", tint: OikomiColor.statGreen, items: summary.highlights)
                section(title: "気になる点", systemImage: "exclamationmark.triangle.fill", tint: OikomiColor.statOrange, items: summary.watchPoints)
                section(title: "来月のフォーカス", systemImage: "target", tint: OikomiColor.statBlue, items: summary.nextFocus)
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.bottom, OikomiSpacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .background(OikomiColor.appBackground)
        .navigationTitle(summary.yearMonth)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(title: String, systemImage: String, tint: Color, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: OikomiSpacing.m) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: OikomiSpacing.s) {
                        Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(tint).padding(.top, 6)
                        Text(item).font(.callout).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(OikomiSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                OikomiColor.cardBackground,
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
        }
    }
}
```

- [ ] **Step 2: 履歴一覧**

Create `App/iOS/Views/MonthlySummaryHistoryView.swift`:

```swift
import OikomiKit
import SwiftData
import SwiftUI

/// 過去の月次振り返りを新しい順に並べる一覧。
struct MonthlySummaryHistoryView: View {
    @Query(sort: \MonthlySummary.generatedAt, order: .reverse)
    private var summaries: [MonthlySummary]

    var body: some View {
        ScrollView {
            VStack(spacing: OikomiSpacing.m) {
                if summaries.isEmpty {
                    Text("まだ振り返りがありません。月初に先月分が生成されます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OikomiSpacing.xxl)
                } else {
                    ForEach(summaries) { summary in
                        NavigationLink {
                            MonthlySummaryView(summary: summary)
                        } label: {
                            VStack(alignment: .leading, spacing: OikomiSpacing.xs) {
                                Text(summary.yearMonth).font(.caption).foregroundStyle(.secondary)
                                Text(summary.headline).font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary).lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(OikomiSpacing.l)
                            .background(
                                OikomiColor.cardBackground,
                                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.bottom, OikomiSpacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .background(OikomiColor.appBackground)
        .navigationTitle("振り返り履歴")
    }
}
```

- [ ] **Step 3: 再生成 + ビルド**

Run: `xcodegen generate`
Run: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`
Expected: `** BUILD SUCCEEDED **`

> `OikomiColor.xs` / `OikomiSpacing.xs` などのトークンが無ければ既存の近いトークン（`OikomiSpacing.s` 等）に置換。`navigationBarTitleDisplayMode` 等は既存 View の用法に合わせる。

- [ ] **Step 4: コミット**

```bash
git add App/iOS/Views/MonthlySummaryView.swift App/iOS/Views/MonthlySummaryHistoryView.swift project.yml Oikomi.xcodeproj
git commit -m "feat(ui): 月次振り返り詳細画面と履歴一覧を追加"
```

---

## Task 8: ホームカード + 履歴エントリ + 生成ワイヤリング（iOS）

**Files:**
- Modify: `App/iOS/Views/HomeView.swift`
- Modify: `App/iOS/Views/AnalysisTabView.swift`

「先月の振り返り」を遅延生成し表示する導線を追加する。

- [ ] **Step 1: 生成ロジックを ViewModel 化**

Create `App/iOS/Intelligence/MonthlySummaryCoordinator.swift`:

```swift
import Foundation
import OikomiKit
import SwiftData

/// 先月の振り返りの「未生成判定」「生成」「保存」をまとめる。
@MainActor
@Observable
final class MonthlySummaryCoordinator {

    enum State: Equatable {
        case idle
        case generating
        case failed(String)
    }

    private(set) var state: State = .idle

    /// 直近の「先月」を yyyy-MM で返す。
    static func lastMonth(now: Date = Date(), calendar: Calendar = .current) -> String {
        let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let comps = calendar.dateComponents([.year, .month], from: start)
        return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
    }

    /// 先月の振り返りカードを出すべきか（Pro + AI 可用 + 未生成 + 先月データが充実）。
    func shouldOfferLastMonth(
        context: ModelContext,
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        snapshots: [HealthSnapshot]
    ) -> Bool {
        guard ProGate.canUseAICoaching else { return false }
        guard case .available = MonthlySummaryGenerator.availability() else { return false }
        let yearMonth = Self.lastMonth()
        let repo = MonthlySummaryRepository(context: context)
        if (try? repo.summary(forYearMonth: yearMonth)) ?? nil != nil { return false }
        let digest = MonthlyDigest.build(
            sessions: sessions, sets: sets, records: records, snapshots: snapshots, yearMonth: yearMonth)
        return digest?.isSubstantial == true
    }

    /// 先月の振り返りを生成・保存して返す。失敗時は state を .failed に。
    @discardableResult
    func generateLastMonth(
        context: ModelContext,
        sessions: [WorkoutSession],
        sets: [SetRecord],
        records: [PersonalRecord],
        snapshots: [HealthSnapshot],
        bodyPhase: BodyPhaseResult?
    ) async -> MonthlySummary? {
        let yearMonth = Self.lastMonth()
        guard let digest = MonthlyDigest.build(
            sessions: sessions, sets: sets, records: records, snapshots: snapshots,
            yearMonth: yearMonth, bodyPhase: bodyPhase)
        else { return nil }

        state = .generating
        do {
            let payload = MonthlySummaryPrompt.make(from: digest)
            let content = try await MonthlySummaryGenerator().generate(payload: payload)
            let repo = MonthlySummaryRepository(context: context)
            let saved = try repo.save(
                yearMonth: yearMonth,
                headline: content.headline,
                highlights: content.highlights,
                watchPoints: content.watchPoints,
                nextFocus: content.nextFocus)
            state = .idle
            return saved
        } catch {
            state = .failed("生成に失敗しました。時間をおいて再試行してください。")
            return nil
        }
    }
}
```

- [ ] **Step 2: ホームに「先月の振り返り」カードを追加**

`HomeView.swift` に状態を追加（`@State private var readiness` 付近）:

```swift
    @Environment(\.modelContext) private var modelContext
    @State private var monthlyCoordinator = MonthlySummaryCoordinator()
    @State private var lastMonthSummary: MonthlySummary?
    @State private var showMonthlyCard = false
```

`body` の `TodayConditionCard(readiness: readiness)` の直後あたりに、カードを差し込む:

```swift
                    if showMonthlyCard {
                        monthlyRetrospectiveCard
                    }
```

カードビルダーと評価ロジックを追加（`refreshHealthSignals` の近くなど）:

```swift
    @ViewBuilder
    private var monthlyRetrospectiveCard: some View {
        NavigationLink {
            if let summary = lastMonthSummary {
                MonthlySummaryView(summary: summary)
            } else {
                monthlyGeneratingPlaceholder
            }
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(OikomiColor.statBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("先月の振り返り").font(.subheadline.weight(.semibold))
                    Text("Apple Intelligence が \(MonthlySummaryCoordinator.lastMonth()) をまとめます")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(OikomiSpacing.l)
            .background(
                OikomiColor.cardBackground,
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .task {
            // タップ前に生成しておく（カードを出す時点で条件は満たしている）。
            if lastMonthSummary == nil, monthlyCoordinator.state != .generating {
                lastMonthSummary = await monthlyCoordinator.generateLastMonth(
                    context: modelContext,
                    sessions: completedSessions,
                    sets: completedSessions.flatMap { $0.sets ?? [] },
                    records: personalRecords,
                    snapshots: completedSessions.compactMap { $0.healthSnapshot },
                    bodyPhase: bodyPhase)
            }
        }
    }

    @ViewBuilder
    private var monthlyGeneratingPlaceholder: some View {
        VStack(spacing: OikomiSpacing.l) {
            if case .failed(let message) = monthlyCoordinator.state {
                Text(message).font(.callout).foregroundStyle(.secondary)
            } else {
                ProgressView("生成中…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OikomiColor.appBackground)
    }
```

`refreshHealthSignals()` の末尾で、カード表示判定を行う:

```swift
        showMonthlyCard = monthlyCoordinator.shouldOfferLastMonth(
            context: modelContext,
            sessions: completedSessions,
            sets: completedSessions.flatMap { $0.sets ?? [] },
            records: personalRecords,
            snapshots: completedSessions.compactMap { $0.healthSnapshot })
```

> `completedSessions` / `personalRecords` / `bodyPhase` は HomeView の既存メンバ（A3 で追加済み）。型・名前が違う場合は既存定義に合わせる。`healthSnapshot` は `WorkoutSession.healthSnapshot`（確認済み）。

- [ ] **Step 3: 分析タブに履歴エントリを追加**

`AnalysisTabView.swift` のツールバーまたはセクションに、履歴へのリンクを追加（既存のナビゲーション様式に合わせる）。例（ナビゲーションツールバー）:

```swift
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MonthlySummaryHistoryView()
                    } label: {
                        Image(systemName: "sparkles.rectangle.stack")
                    }
                }
            }
```

> AnalysisTabView の既存 `NavigationStack`/`.toolbar` 構成に合わせて配置する。既存に toolbar が無ければ、画面下部に「振り返り履歴」NavigationLink カードを 1 つ追加でもよい。

- [ ] **Step 4: 再生成 + ビルド + lint**

Run: `xcodegen generate`
Run: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`
Expected: `** BUILD SUCCEEDED **`

Run: `swift-format lint --recursive App/iOS/Views/HomeView.swift App/iOS/Views/AnalysisTabView.swift App/iOS/Intelligence`
Expected: 新規違反なし

- [ ] **Step 5: コミット**

```bash
git add App/iOS/Views/HomeView.swift App/iOS/Views/AnalysisTabView.swift App/iOS/Intelligence/MonthlySummaryCoordinator.swift project.yml Oikomi.xcodeproj
git commit -m "feat(home): 先月の振り返りカードと履歴導線・生成ワイヤリングを追加"
```

---

## 完了後の最終検証

1. `swift test --package-path Packages/OikomiKit` → 全 PASS（既存 250 + band 1 + MonthlyDigest 4 + Prompt 2 + Repository 3）。
2. `xcodegen generate` → `/build` → `** BUILD SUCCEEDED **`。
3. `/lint` → 新規違反ゼロ。
4. 手動（任意・`/sim-run`、対応機種シミュレータ）:
   - Pro + AI 可用 + 先月セッション ≥ 4 + 未生成 → ホームに「先月の振り返り」カード → タップで生成 → 4 セクション表示。
   - 再表示でキャッシュ（再生成しない）。分析タブから履歴一覧 → 過去分閲覧。
   - Free / 非対応機種 / データ希薄 → カード非表示・クラッシュなし。

## スコープ外（このプランでやらない）
- 週次/オンデマンド生成、BGTask 事前生成、ストリーミング表示、音声読み上げ、英語化。
- 数式コーチングの置き換え（NLP は上乗せ）。

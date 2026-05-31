# MEV/MAV個人化 + 漸進性過負荷（Spec 2-C2）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 経験(初/中/上)×目標(筋肥大/筋力/維持)の UserDefaults プロファイルで部位別 MEV/MAV を個人化し（既定=中級+筋肥大=現状維持）、今週セット数と個人化目標から漸進性過負荷アドバイス（不足→warning/漸進→info）を `combinedCoachingAdvice` に流す。

**Architecture:** すべてオンデバイス。プロファイルは UserDefaults（`WeeklyTrainingTarget` と同パターン、新スキーマなし）。個人化は唯一の注入点 `weeklySetCountReport` が `MuscleSetCountRow.target` に個人化済み `WeeklySetTarget` を詰めることで部位別バー/チップが自動個人化（View 構造不変）。漸進性過負荷は新しい純粋関数を `combinedCoachingAdvice` に統合。既定プロファイルでスケーリング係数が全て 1.0 になり既存挙動・既存テストを完全維持する。

**Tech Stack:** Swift / SwiftUI / UserDefaults / Swift Testing（`import Testing`, `@Test`, `#expect`）。テスト: `swift test --package-path Packages/OikomiKit`。iOS ビルド: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO`。

注: SourceKit/IDE 診断は遅延・誤検知する。**唯一の正は `swift test` / `xcodebuild` の成否**。

---

## ファイル構成（責務）

| 区分 | パス | 責務 |
|---|---|---|
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Models/Enums.swift` | `ExperienceLevel` / `TrainingGoal` enum（+displayName） |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/TrainingProfile.swift` | `TrainingProfile` 値型 + `TrainingProfilePreference`（UserDefaults） |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleVolumeTargets.swift` | `volumeFactors` + `MuscleGroup.weeklySetTarget(for:)` |
| 改修 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift` | `weeklySetCountReport(profile:)` + `combinedCoachingAdvice(profile:)` 統合 |
| 新規 | `Packages/OikomiKit/Sources/OikomiKit/Coaching/ProgressiveOverload.swift` | `progressiveOverloadAdvice` |
| 改修 | `App/iOS/Views/SettingsTabView.swift` | 経験・目標 Picker |
| 改修 | `App/iOS/Views/Analysis/MuscleGroupAnalysisSection.swift` | プロファイルを読み report に渡す |
| 改修 | `App/iOS/Views/HomeView.swift` | プロファイルを読み combinedCoachingAdvice に渡す |
| 新規/改修 | テスト各種 | TrainingProfileTests / MuscleVolumeTargetsTests / AnalyticsTests / ProgressiveOverloadTests |

---

## Task 1: `ExperienceLevel` / `TrainingGoal` enum

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Models/Enums.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/TrainingProfileTests.swift` (new)

- [ ] **Step 1: Write the failing test**

Create `TrainingProfileTests.swift`:
```swift
import Foundation
import Testing

@testable import OikomiKit

@Suite("TrainingProfile")
struct TrainingProfileTests {

    @Test("ExperienceLevel/TrainingGoal: allCases と displayName")
    func enumBasics() {
        #expect(ExperienceLevel.allCases.count == 3)
        #expect(TrainingGoal.allCases.count == 3)
        #expect(ExperienceLevel.beginner.displayName == "初心者")
        #expect(ExperienceLevel.intermediate.displayName == "中級者")
        #expect(ExperienceLevel.advanced.displayName == "上級者")
        #expect(TrainingGoal.hypertrophy.displayName == "筋肥大")
        #expect(TrainingGoal.strength.displayName == "筋力")
        #expect(TrainingGoal.maintenance.displayName == "維持")
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `swift test --package-path Packages/OikomiKit --filter TrainingProfile`
Expected: compile error (`ExperienceLevel`/`TrainingGoal` undefined).

- [ ] **Step 3: Add the enums**

Append to the END of `Packages/OikomiKit/Sources/OikomiKit/Models/Enums.swift`:
```swift

public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced

    public var displayName: String {
        switch self {
        case .beginner: return "初心者"
        case .intermediate: return "中級者"
        case .advanced: return "上級者"
        }
    }
}

public enum TrainingGoal: String, Codable, CaseIterable, Sendable {
    case hypertrophy
    case strength
    case maintenance

    public var displayName: String {
        switch self {
        case .hypertrophy: return "筋肥大"
        case .strength: return "筋力"
        case .maintenance: return "維持"
        }
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `swift test --package-path Packages/OikomiKit --filter TrainingProfile`
Expected: PASS (1).

- [ ] **Step 5: Commit**
```bash
git add Packages/OikomiKit/Sources/OikomiKit/Models/Enums.swift Packages/OikomiKit/Tests/OikomiKitTests/TrainingProfileTests.swift
git commit -m "feat(model): ExperienceLevel / TrainingGoal enum を追加"
```

---

## Task 2: `TrainingProfile` + `TrainingProfilePreference`

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/TrainingProfile.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/TrainingProfileTests.swift`

- [ ] **Step 1: Write the failing tests**

In `TrainingProfileTests.swift`, add inside the struct (before its final `}`):
```swift
    @Test("TrainingProfile.default は中級者・筋肥大")
    func defaultProfile() {
        #expect(TrainingProfile.default.experience == .intermediate)
        #expect(TrainingProfile.default.goal == .hypertrophy)
    }

    @Test("TrainingProfilePreference: UserDefaults 往復と未設定フォールバック")
    func preferenceRoundTrip() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        // 未設定 → default
        #expect(TrainingProfilePreference.current(defaults: suite) == .default)
        // 書く → 読む
        suite.set(ExperienceLevel.advanced.rawValue, forKey: TrainingProfilePreference.experienceKey)
        suite.set(TrainingGoal.strength.rawValue, forKey: TrainingProfilePreference.goalKey)
        let profile = TrainingProfilePreference.current(defaults: suite)
        #expect(profile.experience == .advanced)
        #expect(profile.goal == .strength)
    }
```

- [ ] **Step 2: Run to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter TrainingProfile`
Expected: compile error (`TrainingProfile`/`TrainingProfilePreference` undefined).

- [ ] **Step 3: Implement**

Create `Packages/OikomiKit/Sources/OikomiKit/Coaching/TrainingProfile.swift`:
```swift
import Foundation

/// ユーザーの経験レベル × トレ目標。MEV/MAV 個人化と漸進性過負荷の入力。
public struct TrainingProfile: Sendable, Hashable {
    public let experience: ExperienceLevel
    public let goal: TrainingGoal

    public init(experience: ExperienceLevel, goal: TrainingGoal) {
        self.experience = experience
        self.goal = goal
    }

    /// 既定（中級者・筋肥大）。スケーリング係数がすべて 1.0 になり、既存の固定 MEV/MAV を完全維持する。
    public static let `default` = TrainingProfile(experience: .intermediate, goal: .hypertrophy)
}

/// 経験/目標プロファイルの UserDefaults アクセサ（`WeeklyTrainingTarget` と同パターン）。
public enum TrainingProfilePreference {
    public static let experienceKey = "OikomiExperienceLevel"
    public static let goalKey = "OikomiTrainingGoal"

    /// 現在のプロファイル。未設定キーは `.default` にフォールバック。
    public static func current(defaults: UserDefaults = .standard) -> TrainingProfile {
        let experience =
            defaults.string(forKey: experienceKey).flatMap(ExperienceLevel.init(rawValue:))
            ?? TrainingProfile.default.experience
        let goal =
            defaults.string(forKey: goalKey).flatMap(TrainingGoal.init(rawValue:))
            ?? TrainingProfile.default.goal
        return TrainingProfile(experience: experience, goal: goal)
    }
}
```

- [ ] **Step 4: Run to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter TrainingProfile`
Expected: PASS (3).

- [ ] **Step 5: Commit**
```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/TrainingProfile.swift Packages/OikomiKit/Tests/OikomiKitTests/TrainingProfileTests.swift
git commit -m "feat(coaching): TrainingProfile と UserDefaults アクセサを追加"
```

---

## Task 3: 個人化 `weeklySetTarget(for:)`

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleVolumeTargets.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/MuscleVolumeTargetsTests.swift`

- [ ] **Step 1: Write the failing tests**

In `MuscleVolumeTargetsTests.swift`, add inside the test struct (before its final `}`):
```swift
    @Test("weeklySetTarget(for:.default) はベースラインに一致")
    func defaultMatchesBaseline() {
        for muscle in MuscleGroup.allCases {
            #expect(muscle.weeklySetTarget(for: .default) == muscle.weeklySetTarget)
        }
    }

    @Test("経験レベルで MAV が単調増加（初心者<=中級<=上級）")
    func experienceMonotonic() {
        for muscle in MuscleGroup.allCases where muscle.weeklySetTarget.isTracked {
            let beg = muscle.weeklySetTarget(for: TrainingProfile(experience: .beginner, goal: .hypertrophy)).mav
            let mid = muscle.weeklySetTarget(for: TrainingProfile(experience: .intermediate, goal: .hypertrophy)).mav
            let adv = muscle.weeklySetTarget(for: TrainingProfile(experience: .advanced, goal: .hypertrophy)).mav
            #expect(beg <= mid)
            #expect(mid <= adv)
        }
    }

    @Test("目標: 筋力は筋肥大より MAV が小さい")
    func goalReducesVolume() {
        for muscle in MuscleGroup.allCases where muscle.weeklySetTarget.isTracked {
            let hyp = muscle.weeklySetTarget(for: TrainingProfile(experience: .intermediate, goal: .hypertrophy)).mav
            let str = muscle.weeklySetTarget(for: TrainingProfile(experience: .intermediate, goal: .strength)).mav
            #expect(str <= hyp)
        }
    }

    @Test("個人化しても mev<=mav・fullBody は (0,0)")
    func personalizedInvariants() {
        let profiles = [
            TrainingProfile(experience: .beginner, goal: .strength),
            TrainingProfile(experience: .advanced, goal: .maintenance),
            TrainingProfile(experience: .beginner, goal: .maintenance),
        ]
        for profile in profiles {
            for muscle in MuscleGroup.allCases {
                let t = muscle.weeklySetTarget(for: profile)
                #expect(t.mev <= t.mav)
            }
            let fb = MuscleGroup.fullBody.weeklySetTarget(for: profile)
            #expect(fb.mev == 0 && fb.mav == 0)
        }
    }
```

- [ ] **Step 2: Run to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter MuscleVolumeTargets`
Expected: compile error (`weeklySetTarget(for:)` undefined).

- [ ] **Step 3: Implement**

Append to the END of `Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleVolumeTargets.swift`:
```swift

extension ExperienceLevel {
    /// (mev係数, mav係数)。中級者を基準(1.0)に、上級ほど MAV を上げる。
    var volumeFactors: (mev: Double, mav: Double) {
        switch self {
        case .beginner: return (0.85, 0.70)
        case .intermediate: return (1.0, 1.0)
        case .advanced: return (1.0, 1.20)
        }
    }
}

extension TrainingGoal {
    /// (mev係数, mav係数)。筋肥大を基準(1.0)に、筋力/維持は総量を下げる。
    var volumeFactors: (mev: Double, mav: Double) {
        switch self {
        case .hypertrophy: return (1.0, 1.0)
        case .strength: return (0.85, 0.80)
        case .maintenance: return (0.85, 0.70)
        }
    }
}

extension MuscleGroup {
    /// プロファイルで個人化した週セット数ターゲット。
    /// 既定プロファイル（中級+筋肥大）では係数がすべて 1.0 となりベースライン定数に一致する。
    public func weeklySetTarget(for profile: TrainingProfile) -> WeeklySetTarget {
        let base = weeklySetTarget  // 既存の固定値（中級+筋肥大相当）
        let e = profile.experience.volumeFactors
        let g = profile.goal.volumeFactors
        let mev = Int((Double(base.mev) * e.mev * g.mev).rounded())
        let mav = max(mev, Int((Double(base.mav) * e.mav * g.mav).rounded()))
        return WeeklySetTarget(mev: mev, mav: mav)
    }
}
```

- [ ] **Step 4: Run to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter MuscleVolumeTargets`
Expected: PASS（既存 + 新規4件）。

- [ ] **Step 5: Commit**
```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/MuscleVolumeTargets.swift Packages/OikomiKit/Tests/OikomiKitTests/MuscleVolumeTargetsTests.swift
git commit -m "feat(coaching): プロファイルで MEV/MAV を個人化する weeklySetTarget(for:) を追加"
```

---

## Task 4: `weeklySetCountReport` に profile を追加

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift:120-137`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: Write the failing test**

In `AnalyticsTests.swift`, in the `// MARK: - weeklySetCountReport` section (after the existing weeklySetCount tests), add:
```swift
    @Test("weeklySetCountReport: profile で MEV/MAV が個人化される")
    func reportPersonalizesTarget() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!
        let repo = WorkoutSessionRepository(context: context)
        let session = try repo.startSession()
        // chest を 24 セット（中級 MAV22 → 過多、上級 MAV26 → 適正）
        for _ in 0..<24 { try repo.addSet(to: session, exercise: bench, weight: 60, reps: 8) }
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())

        let mid = Analytics.weeklySetCountReport(sets: allSets, calendar: Self.calendar)
            .first { $0.muscle == .chest }
        let adv = Analytics.weeklySetCountReport(
            sets: allSets,
            profile: TrainingProfile(experience: .advanced, goal: .hypertrophy),
            calendar: Self.calendar
        ).first { $0.muscle == .chest }

        #expect(mid?.status == .excessive)  // 24 > 22
        #expect(adv?.status != .excessive)  // 24 <= 26
    }
```

- [ ] **Step 2: Run to verify it fails**

Run: `swift test --package-path Packages/OikomiKit --filter reportPersonalizesTarget`
Expected: compile error (no `profile:` parameter).

- [ ] **Step 3: Add the `profile` parameter**

In `Analytics.swift`, replace the `weeklySetCountReport` method (lines 120-137) with:
```swift
    public static func weeklySetCountReport(
        sets: [SetRecord],
        profile: TrainingProfile = .default,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [MuscleSetCountRow] {
        let range = currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let counts = setCountByMuscleGroup(sets: sets, in: range)
        let rows: [MuscleSetCountRow] = MuscleGroup.allCases.compactMap { muscle in
            let target = muscle.weeklySetTarget(for: profile)
            guard target.isTracked else { return nil }
            let count = counts[muscle] ?? 0
            return MuscleSetCountRow(muscle: muscle, count: count, target: target)
        }
        return rows.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.muscle.rawValue < rhs.muscle.rawValue
        }
    }
```

- [ ] **Step 4: Run to verify it passes + full suite**

Run: `swift test --package-path Packages/OikomiKit --filter "weeklySetCount|reportPersonalizes"`
Expected: PASS（既存 weeklySetCountReport テスト群は profile 省略=default=ベースラインで不変、新規 1件 PASS）。
Run: `swift test --package-path Packages/OikomiKit 2>&1 | tail -3`
Expected: 全成功。

- [ ] **Step 5: Commit**
```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): weeklySetCountReport に profile を追加し個人化目標を反映"
```

---

## Task 5: `progressiveOverloadAdvice`

**Files:**
- Create: `Packages/OikomiKit/Sources/OikomiKit/Coaching/ProgressiveOverload.swift`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/ProgressiveOverloadTests.swift` (new)

- [ ] **Step 1: Write the failing tests**

Create `ProgressiveOverloadTests.swift`:
```swift
import Foundation
import SwiftData
import Testing

@testable import OikomiKit

@Suite("ProgressiveOverload")
@MainActor
struct ProgressiveOverloadTests {

    private static func makeContext() throws -> ModelContext {
        let schema = Schema(OikomiKit.schemaModels)
        let config = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2
        return cal
    }()

    @Test("不足部位は warning、MEV〜MAV の鍛えている部位は info（漸進）")
    func insufficientAndProgressable() throws {
        let context = try Self.makeContext()
        try ExerciseRepository(context: context).seedIfNeeded()
        let bench = try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "ベンチプレス" }!  // chest mev10 mav22
        let repo = WorkoutSessionRepository(context: context)
        let s = try repo.startSession()
        // chest を 15 セット（10<=15<22 → 漸進候補）。他部位は 0（< mev → 不足）。
        for _ in 0..<15 { try repo.addSet(to: s, exercise: bench, weight: 60, reps: 8) }
        let allSets = try context.fetch(FetchDescriptor<SetRecord>())

        let advices = ProgressiveOverload.progressiveOverloadAdvice(
            sets: allSets, referenceDate: Date(), calendar: Self.calendar)
        #expect(advices.contains { $0.severity == .warning && $0.title == "ボリューム不足" })
        let progress = advices.first { $0.title == "漸進的に増やす" }
        #expect(progress?.severity == .info)
        #expect(progress?.message.contains("胸") == true)
    }

    @Test("セット記録なし → 不足 warning のみ（漸進候補なし）")
    func emptyProducesInsufficientOnly() {
        let advices = ProgressiveOverload.progressiveOverloadAdvice(
            sets: [], referenceDate: Date(), calendar: Self.calendar)
        #expect(advices.contains { $0.title == "ボリューム不足" })
        #expect(!advices.contains { $0.title == "漸進的に増やす" })
    }
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `swift test --package-path Packages/OikomiKit --filter ProgressiveOverload`
Expected: compile error (`ProgressiveOverload` undefined).

- [ ] **Step 3: Implement**

Create `Packages/OikomiKit/Sources/OikomiKit/Coaching/ProgressiveOverload.swift`:
```swift
import Foundation

/// 個人化 MEV/MAV に対する漸進性過負荷の提案（純粋関数）。
public enum ProgressiveOverload {

    private static let maxListed = 4

    /// 今週の部位別セット数を個人化目標と比較し、最大2件の提案を返す。
    /// - MEV 未満の部位（不足）→ warning 1件
    /// - 今週鍛えていて MEV〜MAV 未到達の部位（漸進候補）→ info 1件
    /// MAV 以上は出さない（部位別チップ + deloadAdvice が担当）。
    public static func progressiveOverloadAdvice(
        sets: [SetRecord],
        profile: TrainingProfile = .default,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CoachingAdvice] {
        let range = Analytics.currentWeekRange(referenceDate: referenceDate, calendar: calendar)
        let counts = Analytics.setCountByMuscleGroup(sets: sets, in: range)

        var insufficient: [(muscle: MuscleGroup, gap: Int)] = []
        var progressable: [(muscle: MuscleGroup, room: Int)] = []
        for muscle in MuscleGroup.allCases {
            let target = muscle.weeklySetTarget(for: profile)
            guard target.isTracked else { continue }
            let count = counts[muscle] ?? 0
            if count < target.mev {
                insufficient.append((muscle, target.mev - count))
            } else if count >= 1 && count < target.mav {
                // 今週鍛えている（>=1）かつ MAV 未到達のみ漸進候補（未トレ筋群は対象外）
                progressable.append((muscle, target.mav - count))
            }
        }

        var advices: [CoachingAdvice] = []

        if !insufficient.isEmpty {
            let ordered = insufficient.sorted {
                $0.gap != $1.gap ? $0.gap > $1.gap : $0.muscle.rawValue < $1.muscle.rawValue
            }
            advices.append(
                CoachingAdvice(
                    title: "ボリューム不足",
                    message:
                        "\(names(ordered.map(\.muscle))) が今週 MEV 未満です。来週は各 +1〜2 セット増やしましょう。",
                    severity: .warning,
                    impact: 1000 + Double(insufficient.count) * 100
                )
            )
        }

        if !progressable.isEmpty {
            let ordered = progressable.sorted {
                $0.room != $1.room ? $0.room > $1.room : $0.muscle.rawValue < $1.muscle.rawValue
            }
            advices.append(
                CoachingAdvice(
                    title: "漸進的に増やす",
                    message:
                        "\(names(ordered.map(\.muscle))) は来週 +1〜2 セットで MAV に向けて漸進できます。",
                    severity: .info,
                    impact: 120 + Double(progressable.count) * 10
                )
            )
        }

        return advices
    }

    /// 最大 `maxListed` 部位を「・」連結。超過分は「など」。
    private static func names(_ muscles: [MuscleGroup]) -> String {
        var s = muscles.prefix(maxListed).map(\.displayName).joined(separator: "・")
        if muscles.count > maxListed { s += " など" }
        return s
    }
}
```

- [ ] **Step 4: Run to verify they pass**

Run: `swift test --package-path Packages/OikomiKit --filter ProgressiveOverload`
Expected: PASS (2).

- [ ] **Step 5: Commit**
```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/ProgressiveOverload.swift Packages/OikomiKit/Tests/OikomiKitTests/ProgressiveOverloadTests.swift
git commit -m "feat(coaching): 漸進性過負荷アドバイス progressiveOverloadAdvice を追加"
```

---

## Task 6: `combinedCoachingAdvice` に profile + 漸進性過負荷を統合

**Files:**
- Modify: `Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift:648-679`
- Test: `Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift`

- [ ] **Step 1: Write the failing test**

In `AnalyticsTests.swift`, in the `// MARK: - combinedCoachingAdvice（統合パイプライン）` section, add:
```swift
    @Test("combinedCoachingAdvice: 漸進性過負荷（不足）が統合される")
    func combinedIncludesProgressiveOverload() {
        let cal = Self.calendar
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 31, hour: 12))!
        // 空セット → 全 mev>0 部位が MEV 未満 → ボリューム不足 warning
        let advices = Analytics.combinedCoachingAdvice(
            sessions: [], sets: [], records: [], readiness: nil,
            limit: 20, referenceDate: now, calendar: cal)
        #expect(advices.contains { $0.title == "ボリューム不足" })
    }
```

- [ ] **Step 2: Run to verify it fails**

Run: `swift test --package-path Packages/OikomiKit --filter combinedIncludesProgressiveOverload`
Expected: FAIL（漸進性過負荷がまだ統合されていない）。

- [ ] **Step 3: Add `profile` param + the progressive-overload term**

In `Analytics.swift`, change `combinedCoachingAdvice`'s signature to add a `profile` parameter at the end:
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
        profile: TrainingProfile = .default
    ) -> [CoachingAdvice] {
```
and append one term to the `let all =` concatenation (after the `MuscleRecovery.recoveryAdvice(...)` term):
```swift
            + MuscleRecovery.recoveryAdvice(
                sets: sets, referenceDate: referenceDate, calendar: calendar)
            + ProgressiveOverload.progressiveOverloadAdvice(
                sets: sets, profile: profile, referenceDate: referenceDate, calendar: calendar)
```
Also append "・漸進" to the doc-comment generator list (line ~644) for accuracy (optional but preferred).

- [ ] **Step 4: Run to verify it passes + full suite**

Run: `swift test --package-path Packages/OikomiKit --filter combined`
Expected: PASS（既存 combined テスト + `combinedIncludesProgressiveOverload`）。
Run: `swift test --package-path Packages/OikomiKit 2>&1 | tail -3`
Expected: 全成功。

- [ ] **Step 5: Commit**
```bash
git add Packages/OikomiKit/Sources/OikomiKit/Coaching/Analytics.swift Packages/OikomiKit/Tests/OikomiKitTests/AnalyticsTests.swift
git commit -m "feat(coaching): combinedCoachingAdvice に profile と漸進性過負荷を統合"
```

---

## Task 7: 設定タブに経験・目標 Picker を追加

**Files:**
- Modify: `App/iOS/Views/SettingsTabView.swift`

- [ ] **Step 1: Add @AppStorage props**

In `SettingsTabView.swift`, after the `weeklyTargetDays` @AppStorage (around line 16), add:
```swift
    @AppStorage(TrainingProfilePreference.experienceKey) private var experienceLevelRaw: String =
        TrainingProfile.default.experience.rawValue
    @AppStorage(TrainingProfilePreference.goalKey) private var trainingGoalRaw: String =
        TrainingProfile.default.goal.rawValue
```

- [ ] **Step 2: Add the two Pickers**

In `preferenceSection`, insert these two Pickers right AFTER the WeeklyTarget Picker (the `Label("週次トレーニング目標", ...)` Picker block) and BEFORE the `NavigationLink { AppIconPickerView() }`:
```swift
            Picker(selection: $experienceLevelRaw) {
                ForEach(ExperienceLevel.allCases, id: \.rawValue) { level in
                    Text(level.displayName).tag(level.rawValue)
                }
            } label: {
                Label("経験レベル", systemImage: "figure.strengthtraining.traditional")
            }

            Picker(selection: $trainingGoalRaw) {
                ForEach(TrainingGoal.allCases, id: \.rawValue) { goal in
                    Text(goal.displayName).tag(goal.rawValue)
                }
            } label: {
                Label("トレーニング目標", systemImage: "target")
            }
```

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | head -20
```
Expected: `** BUILD SUCCEEDED **`. (No new files; existing files edited → no `xcodegen generate`.)

- [ ] **Step 4: Commit**
```bash
git add App/iOS/Views/SettingsTabView.swift
git commit -m "feat(settings): 環境設定に経験レベル・トレーニング目標 Picker を追加"
```

---

## Task 8: 分析タブ「部位別」と Home をプロファイルに配線

**Files:**
- Modify: `App/iOS/Views/Analysis/MuscleGroupAnalysisSection.swift`
- Modify: `App/iOS/Views/HomeView.swift`

- [ ] **Step 1: MuscleGroupAnalysisSection — read profile, pass to report**

In `MuscleGroupAnalysisSection.swift`, add @AppStorage + a `profile` computed property near the existing `weightUnitRaw` @AppStorage (top of the struct):
```swift
    @AppStorage(TrainingProfilePreference.experienceKey) private var experienceLevelRaw: String =
        TrainingProfile.default.experience.rawValue
    @AppStorage(TrainingProfilePreference.goalKey) private var trainingGoalRaw: String =
        TrainingProfile.default.goal.rawValue
    private var profile: TrainingProfile {
        TrainingProfile(
            experience: ExperienceLevel(rawValue: experienceLevelRaw) ?? .intermediate,
            goal: TrainingGoal(rawValue: trainingGoalRaw) ?? .hypertrophy)
    }
```
Then change the existing `report` computed property:
```swift
    private var report: [MuscleSetCountRow] {
        Analytics.weeklySetCountReport(sets: sets, profile: profile)
    }
```

- [ ] **Step 2: HomeView — read profile, pass to combinedCoachingAdvice**

In `HomeView.swift`, add @AppStorage + a `trainingProfile` computed property near the existing `weightUnit` accessor (top of the struct):
```swift
    @AppStorage(TrainingProfilePreference.experienceKey) private var experienceLevelRaw: String =
        TrainingProfile.default.experience.rawValue
    @AppStorage(TrainingProfilePreference.goalKey) private var trainingGoalRaw: String =
        TrainingProfile.default.goal.rawValue
    private var trainingProfile: TrainingProfile {
        TrainingProfile(
            experience: ExperienceLevel(rawValue: experienceLevelRaw) ?? .intermediate,
            goal: TrainingGoal(rawValue: trainingGoalRaw) ?? .hypertrophy)
    }
```
Then in the `allCoaching` computed property, change the `combinedCoachingAdvice` call to pass `profile: trainingProfile` (add it as the last argument):
```swift
        return Analytics.combinedCoachingAdvice(
            sessions: completedSessions,
            sets: allSets,
            records: personalRecords,
            readiness: readiness,
            limit: .max,
            weightUnit: weightUnit,
            profile: trainingProfile
        )
```

- [ ] **Step 3: Build**

Run:
```bash
xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | head -20
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**
```bash
git add App/iOS/Views/Analysis/MuscleGroupAnalysisSection.swift App/iOS/Views/HomeView.swift
git commit -m "feat(home): 部位別バーと統合コーチングをプロファイルに配線"
```

---

## Task 9: 全体検証

**Files:** なし（検証のみ）

- [ ] **Step 1: OikomiKit 全テスト**

Run: `swift test --package-path Packages/OikomiKit`
Expected: 既存（224）+ 新規（TrainingProfile 3 / MuscleVolumeTargets +4 / weeklySetCountReport +1 / ProgressiveOverload 2 / combined +1）すべて PASS。失敗時は `superpowers:systematic-debugging`。

- [ ] **Step 2: iOS ビルド**

Run: `xcodebuild build -project Oikomi.xcodeproj -scheme Oikomi -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | head`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: 整形と lint**

Run: `xcrun swift-format lint --recursive --configuration .swift-format App Packages/OikomiKit/Sources Packages/OikomiKit/Tests 2>&1 | grep -v "SilentSetAlternateIcon" | head`
Expected: 出力なし。差分が出る場合は `xcrun swift-format format --in-place --recursive --configuration .swift-format App Packages/OikomiKit/Sources Packages/OikomiKit/Tests` のうえ `git add -A && git commit -m "style: swift-format 整形"`.

- [ ] **Step 4: シナリオ確認（手動・任意）**

設定「環境」で経験=上級・目標=筋力に変える → 分析タブ「部位別」の MEV/MAV バーと過不足チップが変化する／Home コーチングに「ボリューム不足」「漸進的に増やす」が出る。既定（中級+筋肥大）では従来表示と一致。

---

## Self-Review（この計画の自己点検）

**1. Spec coverage（設計書 §4 の各項目 → タスク）**
- §4.1 プロファイル（enum + TrainingProfile + Preference）→ Task 1 + Task 2 ✅
- §4.2 個人化 MEV/MAV（volumeFactors + weeklySetTarget(for:)、既定==ベースライン、単調性、mev<=mav、fullBody）→ Task 3 ✅
- §4.3 weeklySetCountReport 個人化 → Task 4 ✅
- §4.4 progressiveOverloadAdvice（不足 warning / 漸進 info、最大2件、決定的列挙順）→ Task 5 ✅
- §4.4 combinedCoachingAdvice 統合 → Task 6 ✅
- §4.5 露出（設定 Picker / 部位別 / Home）→ Task 7 + Task 8 ✅
- §6 テスト → Task 1-6、§7 エッジ（既定後方互換・丸め/不変条件・スパム集約・未トレ筋群除外）→ 各テストで網羅 ✅
- §9 完了の定義 → Task 9 ✅

**2. Placeholder scan:** 「TBD/後で」なし。各コードステップは実コード掲載。係数は §4.2 で確定値、丸め・clamp も明示。

**3. Type consistency:**
- `ExperienceLevel`/`TrainingGoal`（displayName）は Task 1 定義、Task 2/3/7/8 で参照。✅
- `TrainingProfile`（experience/goal/.default）/ `TrainingProfilePreference`（experienceKey/goalKey/current）は Task 2 定義、Task 3-8 で一致参照。✅
- `MuscleGroup.weeklySetTarget(for:)` は Task 3 定義、Task 4（report）・Task 5（progressive）で利用。✅
- `weeklySetCountReport(sets:profile:...)` は Task 4 定義、Task 8（部位別）で一致。✅
- `ProgressiveOverload.progressiveOverloadAdvice(sets:profile:...)` は Task 5 定義、Task 6（combined）で一致。✅
- `combinedCoachingAdvice(... profile:)` は Task 6 定義、Task 8（Home）で一致。✅
- `WeeklySetTarget`（mev/mav/isTracked）・`MuscleSetCountRow.status`・既存トークンは不変。✅

---

## Execution Handoff

実装計画は `docs/superpowers/plans/2026-05-31-mev-mav-personalization.md` に保存。2 つの実行方法:

1. **Subagent-Driven（推奨）** — タスクごとに新サブエージェント＋2段階レビュー（仕様適合→コード品質）。
2. **Inline Execution** — `superpowers:executing-plans` でバッチ実行＋チェックポイント。

どちらで進めますか？

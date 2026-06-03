# "Oikomi" Strength-Training Tracker — Specification

> This document is the official specification for the app. It serves as the source of truth when implementation decisions waver, and as context for the AI coding harness.
> Whenever the spec needs to change, update this file **before** changing code.
>
> Note: The Japanese-language [`SPEC.md`](SPEC.md) is the primary source. This English version is a faithful translation kept for reference; if the two ever diverge, defer to `SPEC.md`.

## Table of Contents

1. [Overview](#1-overview)
2. [Target Users](#2-target-users)
3. [Differentiation](#3-differentiation)
4. [Core Features](#4-core-features)
5. [Tech Stack](#5-tech-stack)
6. [Data Model](#6-data-model)
7. [Screen Composition](#7-screen-composition)
8. [MVP Scope (v1.0)](#8-mvp-scope-v10)
9. [Post-Launch Roadmap](#9-post-launch-roadmap)
10. [Revenue Model](#10-revenue-model)
11. [Anticipated Risks](#11-anticipated-risks)

---

## 1. Overview

A strength-training tracker fully specialized for the Apple ecosystem. It integrates HealthKit / Live Activity / Apple Intelligence to deliver **"a health-data-driven strength log: plan on iPhone, push to the limit on Apple Watch."** Division of roles: plan routines and exercises on iPhone, and use the Apple Watch as a standalone recording device at the gym.

- Product name: **Oikomi** (追い込み — "the final push")
  - App Store title: **Oikomi - Strength Log & Apple Watch**
- Supported OS: iOS 26+ / watchOS 26+ (iPhone-only)
- Distribution: Freemium (ad-free) + subscription
  - Pro monthly: ¥780
  - Pro annual: ¥5,800 (effectively ¥483/month)
  - 14-day free trial
  - No one-time purchase plan

---

## 2. Target Users

### Regional Strategy
Launch focused on the Japanese market. Consider global expansion with an English UI from v2.0 onward.

### Primary Persona: "The Apple-Devoted Serious Trainee"

- Ages 25–40, 60% male / 40% female
- Company employees / self-employed (skewed toward IT and professional roles), annual income ¥5M–¥10M
- Trains 3–5 times per week (gym-centric, also trains at home)
- 1+ years of training experience; goals are physique building and PR progression
- Owns an iPhone + Apple Watch Series 9 or newer
- A segment dissatisfied with existing apps (Hevy / Strong / Kintore Memo)
- Acceptable monthly price: ¥500–¥1,500

### Secondary Persona: "The Health-Data Aggregator"

- Ages 30–50, any gender
- Apple devotee; also uses Whoop / Oura, etc.
- Finds value in aggregating data into HealthKit itself

### Training Scope

- **Primary**: weight and machine training at the gym
- **Secondary**: home bodyweight / dumbbell / resistance-band training
- Exercise library: 100 exercises at v1.0 (gym-focused) → 200 at v1.2 (home training added)

### Excluded Users

- Complete beginners (those needing form-instruction videos → Nike Training Club, etc.)
- Android users
- Extremely price-sensitive segments

### Market Size (rough estimate)

- **SOM**: ~500,000 people (Japan's Apple Watch strength-training segment, including home trainers)
- **3-year goal**: 18,000 paying users / ¥81M annual revenue (the independence-viable line)

---

## 3. Differentiation

### Core Pitch

> **"A health-data-driven strength log: plan on iPhone, push to the limit on Apple Watch."**

Three experiential values:

1. **Wrist-only execution** — Run and record routines (created on iPhone) standalone on Apple Watch (no need to take out your iPhone at the gym). Live Activity / Dynamic Island shows progress at a glance.
2. **Smart** — Automatic load adjustment linked to HRV, sleep, and menstrual cycle.
3. **Natively Japanese** — UI, exercise names, and coaching copy all in natural Japanese.

### Competitive Comparison

| Dimension | Oikomi | Hevy | Strong | Burnfit | Kintore Memo |
|---|---|---|---|---|---|
| Apple Watch standalone | ◎ | ○ | ○ | △ | × |
| Live Activity / Dynamic Island | ◎ | × | × | × | × |
| Bidirectional HealthKit | ◎ | △ | △ | △ | × |
| HRV/sleep-linked AI coaching | ◎ | × | × | × | × |
| Menstrual-cycle integration | ○ (v1.1) | × | × | × | × |
| Japanese UI quality | ◎ | △ (machine-translated) | △ | ◎ | ◎ |
| Exercise library size | ○ 200 | ◎ 400 | ◎ | ○ | ○ |
| Social features | × | ◎ | △ | △ | △ |
| Price (annual) | ¥5,800 | ¥3,600 | ¥4,500 | ¥5,790 | paid |

### Areas We Deliberately Won't Win (a self-imposed discipline)

For focus, the following are deliberately designed *not* to beat competitors. We state this in the spec as a discipline so the direction doesn't waver mid-implementation.

- **Exercise-library breadth** — No need to catch Hevy's 400 exercises. The top 200 are enough.
- **Social features** — We don't fight Hevy's community. We take the "solitary grind" segment.
- **Video form instruction** — We don't encroach on Apple Fitness+ / Nike Training Club territory.

### Relationship to Apple's Workout Buddy

We take a **coexistence** stance with Workout Buddy (Apple Intelligence voice motivation), introduced in watchOS 26.

| Role | Workout Buddy | Oikomi |
|---|---|---|
| Positioning | Cheerleader | Coach |
| Target activity | Cardio-centric / general workouts | Weight-training-specialized |
| Primary data | Heart rate / distance / rings | Weight / reps / volume / 1RM |
| Pricing | Free (watchOS 26 standard) | Subscription |

The design lets Oikomi's recording run in parallel even while Workout Buddy is active. Users can receive Apple's native voice motivation while keeping detailed records and long-term analysis in Oikomi.

---

## 4. Core Features

Features are organized into five tiers by importance. Tier 5 explicitly lists features we deliberately won't build, as a discipline.

### Tier 1: Core Experience (no reason to exist without these)

#### 4.1.1 Fast-Input UX

Designed to complete each set in **1–3 taps** — twice the speed of Hevy (5–8 taps).

```
Step 1: Start a routine
  → Auto-displays "Bench Press 80kg × 8 reps × 3 sets" from last session's history

Step 2: Complete one set
  → Double Tap on Apple Watch or tap the screen
  → Rest timer starts automatically

Step 3: Adjust only when a value differs
  → Use the Digital Crown for weight ±2.5kg / reps, like a physical dial
```

Implementation notes:
- `WKInterfaceCrownSequencer` for Digital Crown input
- watchOS 26 Double Tap gesture to confirm set completion
- Last-session history prefilled instantly from CloudKit / SwiftData

#### 4.1.2 History (unlimited)

- Browse all past sessions in a calendar UI
- Per-exercise history (weight / rep progression)
- Copy a previous session

#### 4.1.3 Apple Watch Standalone Recording

All recording works on the Watch alone, even without the iPhone nearby. Contributes automatically to the Activity Rings via `HKWorkoutSession`.

#### 4.1.4 Live Activity / Dynamic Island

- Always shows current-set info and rest-seconds-remaining on the Lock Screen / Dynamic Island
- StandBy mode support (lay the phone sideways to make a gym-side display)

---

### Tier 2: Apple-Specific Differentiation (Pro mainstay)

#### 4.2.1 Bidirectional HealthKit Integration

- Write: `HKWorkout`, `bodyMass`, `bodyFatPercentage`, `leanBodyMass`
- Read (Pro): heart-rate zones, HRV, resting heart rate, sleep score, menstrual cycle (v1.1)

#### 4.2.2 AI Coaching (on-device formulas, Pro-only)

All computed by on-device pure functions in `OikomiKit/Coaching` (no external LLM). The original three at v1.0 (deload / PR prediction / volume warning) were **deliberately expanded** to strengthen the core of Pro revenue. The primary design source is [`docs/superpowers/specs/2026-05-30-coaching-readiness-autoregulation-design.md`](superpowers/specs/2026-05-30-coaching-readiness-autoregulation-design.md).

| Suggestion type | Trigger | Example |
|---|---|---|
| Deload / recovery priority | A low **overall condition score** (a 0–100 score centered on HRV and integrating sleep and resting heart rate; HRV is judged via a **rolling baseline + z-score**, not a simple average), or excessive consecutive training days / weekly-volume ratio | "Prioritize recovery today. Keep it light, around 80% of last time." |
| RPE autoregulation | The average RPE of the last two sessions is outside the target band (too heavy / too light) | "Your bench was high-intensity both of the last two times. Aim for 100→95kg next time." |
| PR prediction | Linear regression on the upward trend of the recent peak estimated 1RM (with **RIR correction**) | "There's a chance of a bench PR next time (estimated 87.5kg ±2kg)." |
| Plateau detection | The estimated 1RM for an exercise is roughly flat (slope ≈ 0) | "Your bench is plateauing. Consider changing rep range, frequency, or exercise." |
| Volume warning | Per-muscle weekly volume is excessive / insufficient | "This week's chest volume is 150% of last week. Watch for overtraining." |

The **overall condition score** is computed even when signals are missing, by reallocating weights across the available signals (preserving `confidence` and a data-source note), and is shown on the home "Today's Condition" card as a 0–100 value.

**Supported devices & assumptions (important)**: All the coaching above is **entirely on-device formulas** and **works at full capability even on devices that don't support Apple Intelligence**. Apple Intelligence (Foundation Models) is needed only for the v1.2 natural-language summary — that's a "bonus that lights up on supported devices." The Pro pitch is not "Apple Intelligence" but "**HealthKit-linked coaching**." Even **iPhone-only users who don't use an Apple Watch** get full RPE autoregulation, PR prediction, plateau detection, and volume warnings; without HRV / resting heart rate, the condition score gracefully degrades to a sleep-centric basis (with the reason shown on the card).

#### 4.2.3 Automatic 1RM & Estimated Intensity (%1RM)

Auto-computes estimated 1RM from set history and visualizes each set's relative intensity.

#### 4.2.4 Parallel Operation with Workout Buddy

Oikomi's recording session runs in parallel even while watchOS 26's native Workout Buddy is active. The two coexist by holding a separate `HKWorkoutSession`.

---

### Tier 3: Retention Features

- **Routine management**: Save exercise lists and target set counts; start with one tap
- **Exercise library**: 100 exercises at v1.0 (gym-focused); search by muscle group / equipment / location tags
- **Interval timer**: Auto-start rest; default seconds per exercise
- **History copy**: Start by copying an entire previous session
- **App Intents / Siri**: Voice input like "Log bench press 80kg 8 reps"
- **Widgets**: small / medium / large / Lock Screen / StandBy support

---

### Tier 4: Extensions (v1.1 onward)

- **Menstrual-cycle integration** (v1.1): Read HealthKit's `menstrualFlow` for automatic load adjustment
- **Home-training exercises** (v1.2): Expand the library to 200 exercises; bodyweight / band / dumbbell support
  - Tag exercise data with `locations: [.gym, .home]` and control display by mode switch
  - Record bodyweight exercises by seconds/reps rather than weight
- **Apple Intelligence summary** (v1.2): Auto-generate a monthly review in natural language
- **Core ML automatic rep counting** (v1.3): Estimate rep counts from the wrist IMU
- **Family Sharing** (v1.1): Share the subscription with up to 6 people

---

### Tier 5: Features We Deliberately Won't Build (a self-imposed discipline)

Stated in the spec to stay the course. The "won't build it even if requested" list.

- **Social / feed / community features** — Hevy's territory. We take the "solitary grind" segment.
- **Video form instruction** — Apple Fitness+ / Nike Training Club territory.
- **Chat with a personal coach** — Hevy Coach territory; consider B2B expansion from v2.0 onward.
- **Tutorial videos for complete beginners** — We focus on intermediate-to-advanced users.
- **Manual meal logging** — Via HealthKit only (no custom meal-input UI).
- **Android version** — Won't support it; it breaks the Apple focus.

---

## 5. Tech Stack

Policy: keep everything within Apple's first-party stack. Minimize third-party dependencies to hold down fixed monthly costs and privacy risk.

### 5.1 Adopted Technologies

| Layer | Technology | Rationale |
|---|---|---|
| UI | **SwiftUI** | Declarative; shared across watchOS / iOS |
| Local DB | **SwiftData** | Auto-syncs with CloudKit; successor to Core Data |
| Sync | **CloudKit** | Free; needs only an iCloud account; no server ops |
| Health data | **HealthKit / WorkoutKit** | The standard for bidirectional integration |
| Live display | **ActivityKit** | Live Activity / Dynamic Island |
| Voice & automation | **App Intents** | Siri / Shortcuts / Spotlight integration |
| AI coaching | **On-device computation + Foundation Models** | Formulas for HRV / volume; Apple Intelligence for natural language |
| ML (v1.3) | **Core ML + Create ML** | IMU automatic rep counting |
| Billing | **StoreKit 2** | Apple standard; avoids fixed monthly costs |

### 5.2 Development & Operations Tools

| Purpose | Technology |
|---|---|
| Version control | Git + GitHub |
| CI/CD | Xcode Cloud (free up to 25 hrs/month) |
| Beta distribution | TestFlight |
| Analytics | App Store Connect Analytics + TelemetryDeck (privacy-focused) |
| Crash reports | Xcode Organizer (free, Apple first-party) |
| Customer support | TestFlight Feedback + email |

### 5.3 AI Coaching Implementation Policy

- **All computation completes on-device.** Make privacy the top selling point.
- HRV / volume warning / PR prediction are formula-based (lightweight, instant)
- The natural-language summary from v1.2 uses the **Foundation Models framework**
- Never transmit user data externally; never use it for model training

### 5.4 Technologies We Deliberately Won't Adopt (a self-imposed discipline)

To avoid third-party dependencies and operational burden, we won't adopt the following.

| Technology | Reason for non-adoption |
|---|---|
| Firebase | CloudKit is sufficient; avoid Google-ecosystem lock-in |
| RevenueCat | StoreKit 2 is sufficient; avoid fixed monthly costs |
| Supabase / Fly.io | Stay serverless (CloudKit only) for zero ops burden |
| React Native / Flutter | Breaks the Apple focus; prioritize native performance |
| Sentry / Bugsnag | Xcode Organizer is sufficient |
| Third-party ad SDKs | Ad-free policy |
| External LLM APIs (OpenAI / Anthropic) | Use only on-device Apple Intelligence |

---

## 6. Data Model

### 6.1 Conceptual Model

```
User ───< WorkoutSession ───< SetRecord >─── Exercise
                  │                              │
                  │                      (locations, muscleGroups)
                  └─── HealthSnapshot

User ───< Routine ───< RoutineExercise >─── Exercise

User ───< PersonalRecord >─── Exercise
User ───< BodyMetric (HealthKit mirror)
```

### 6.2 SwiftData Skeleton

```swift
@Model
final class Exercise {
    var id: UUID
    var name: String                       // "ベンチプレス" (Bench Press)
    var nameEn: String                     // "Bench Press"
    var muscleGroups: [MuscleGroup]        // [.chest, .triceps]
    var equipment: Equipment               // .barbell, .dumbbell, .bodyweight
    var locations: [Location]              // [.gym, .home]
    var measurementType: MeasurementType   // .weightReps, .bodyweightReps, .time
    var defaultRestSeconds: Int
    var isCustom: Bool
}

@Model
final class WorkoutSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var healthKitWorkoutUUID: UUID?        // Link to HKWorkout
    @Relationship(deleteRule: .cascade) var sets: [SetRecord]
    var notes: String?
    var healthSnapshot: HealthSnapshot?    // State at session start
}

@Model
final class SetRecord {
    var id: UUID
    var exercise: Exercise
    var session: WorkoutSession
    var order: Int                         // Order within the session
    var weight: Double?                    // nil for bodyweight exercises
    var reps: Int?                         // nil for time-based exercises
    var durationSeconds: Int?              // Planks, etc.
    var rpe: Double?                       // Rate of perceived exertion (1–10)
    var isWarmup: Bool
    var estimated1RM: Double?              // Snapshot at recording time
    var restSeconds: Int?
    var completedAt: Date
}

@Model
final class Routine {
    var id: UUID
    var name: String
    var exercises: [RoutineExercise]       // Ordered exercise list
    var createdAt: Date
    var lastUsedAt: Date?
}

@Model
final class HealthSnapshot {
    var date: Date
    var hrvSDNN: Double?                   // ms
    var sleepScore: Int?                   // 0–100
    var restingHeartRate: Int?
    var menstrualPhase: MenstrualPhase?    // v1.1
}

@Model
final class PersonalRecord {
    var id: UUID
    var exercise: Exercise
    var weight: Double
    var reps: Int
    var estimated1RM: Double
    var achievedAt: Date
}
```

### 6.3 CloudKit Compatibility Notes

- Every property must have a default value or be Optional (a CloudKit requirement)
- Store enums by their String / Int `rawValue`
- Don't use `@Attribute(.unique)` — it conflicts with CloudKit sync
- Explicitly declare the `inverse` of every `@Relationship`
- Separate images / large data into a `CKAsset` field (unused in v1.0)

### 6.4 Migration Policy

- Adopt SwiftData's `VersionedSchema` from v1.0
- Cut a schema per major version; migrate in stages via `SchemaMigrationPlan`
- Limit breaking changes to milestones like v2.0
- On migration failure, restore from the iCloud snapshot by design

### 6.5 HealthSnapshot Operation

- At session start, fetch and cache HRV / sleep score / resting heart rate from HealthKit
- AI coaching references this snapshot (doesn't hit HealthKit every time)
- Accumulating past snapshots enables long-term trend analysis

---

## 7. Screen Composition

### 7.1 iPhone (5-tab layout)

| Tab | Screen | Main elements |
|---|---|---|
| 🏠 Home | Today's overview | Today's routine / recent PRs / Activity Rings / AI coaching suggestions |
| 💪 Training | Workout execution | Exercise list / set recording / Live Activity link |
| 📅 History | Past sessions | Calendar / session detail / history copy |
| 📊 Analytics | Charts & stats | Per-exercise trends / per-muscle volume / PR list / estimated 1RM |
| ⚙️ Settings | Various settings | HealthKit / notifications / billing / gym-home mode switch / account |

### 7.2 Apple Watch

| Level | Screen | Main elements |
|---|---|---|
| Root | Home | Start today's routine / recent session |
| → | During workout | Current set / next set / rest timer / heart rate |
| → | Exercise selection | Quick select (history-based) |
| → | Set input | Adjust weight/reps with Digital Crown, confirm with Double Tap |
| Complication | Various watch faces | Next set / rest remaining / today's progress |
| Smart Stack | Auto-surfacing widget | Surfaces automatically as training time approaches |

### 7.3 Onboarding (4 steps, each skippable)

Assumes local use with no account creation (CloudKit automatically uses the device's Apple ID and iCloud).

1. **Welcome** — Briefly introduce the three experiential values (wrist-only / smart / natively Japanese)
2. **HealthKit permissions** — Explain read/write scope and request authorization
3. **Apple Watch pairing check** — Skip if not owned
4. **Routine creation** — Pick from presets, or do it later

### 7.4 Where AI Coaching Suggestions Appear

| Location | Timing | Content |
|---|---|---|
| Top of Home | App launch | Today's recommended volume / deload recommendation |
| Before workout | On tapping "start routine" | "HRV is low today, so go light." |
| Push notification | On PR prediction / rest recommendation | "PR predicted on tomorrow's bench!" |
| Monthly summary | Start of month | Apple Intelligence review (v1.2) |

### 7.5 Billing Funnel (subtle, experience-based)

No aggressive full-screen popups. Soft walls keep users from churning.

- An "Upgrade to Pro" section in the Settings tab
- A soft wall when tapping AI coaching features ("This is a Pro feature")
- Blurred Pro-only charts on the Analytics screen (preview-style)
- A subtle, dismissible home banner once a month
- A subtle "X days left" header during the 14-day trial

### 7.6 Navigation Structure

- **iPhone**: tab bar (5 tabs)
- **Apple Watch**: flat navigation stack

> No iPad / Mac support in v1.0. If considered later, the assumption is a separate product redesigned from scratch.

---

## 8. MVP Scope (v1.0)

### 8.1 Features Included in v1.0

**Tier 1: Core Experience (all Free)**

- Fast-input UX (B+C hybrid, 1–3 taps)
- History (unlimited)
- Apple Watch standalone recording
- Live Activity / Dynamic Island
- 100-exercise library (gym-focused)
- Routine management (Free up to 5, Pro unlimited)
- Interval timer

**Tier 2: Apple-Specific (Pro-only)**

- Bidirectional HealthKit (HRV / sleep reading is Pro)
- 3 AI coaching types (deload / PR prediction / volume warning)
- Automatic 1RM & estimated intensity (%1RM)
- Advanced analytics charts

**Tier 3: Retention (Free / Pro common)**

- App Intents / Siri input
- Widgets (small / medium / large / Lock Screen / StandBy)
- Parallel operation with Workout Buddy

### 8.2 Features Excluded from v1.0

| Feature | Planned release |
|---|---|
| Menstrual-cycle integration | v1.1 |
| Family Sharing | v1.1 |
| Home-training exercises (expand to 200 total) | v1.2 |
| Apple Intelligence natural-language summary | v1.2 |
| Core ML automatic rep counting | v1.3 |
| SharePlay co-sessions | v2.0+ |
| App Clips (for gym partnerships) | v2.0+ |

### 8.3 Apple Watch MVP Scope Definition

**What the Watch can do alone**

- Start a routine
- Record sets (weight / reps / timer)
- Browse history (last 5 sessions)
- Display Complication / Smart Stack

**What the Watch can't do (iPhone required)**

- Add / edit exercise library
- Browse detailed analytics charts
- Manage billing
- Change settings

### 8.4 Development Schedule (solo development, 1 person, 8 months total)

| Phase | Duration | Content |
|---|---|---|
| Design & prep | 1 month | Learn Swift / design data model / UI mocks |
| iPhone build | 2 months | Recording / history / analytics / settings |
| Watch build | 1.5 months | Standalone recording / Live Activity |
| HealthKit / AI | 1.5 months | Bidirectional integration / 3 AI coaching types |
| Billing & QA | 1 month | StoreKit 2 integration / TestFlight |
| Launch prep | 1 month | App Store submission / landing page / marketing assets |

Release target: **late 2026 to early 2027**

### 8.5 Success KPIs for the First 3 Months Post-Launch

| Metric | Target | Failure line |
|---|---|---|
| Cumulative downloads | 5,000 | < 1,000 |
| Monthly active users (MAU) | 1,500 | < 300 |
| Pro trial start rate (of DLs) | 15% | < 5% |
| Trial → paid conversion | 30% | < 10% |
| Cumulative paying users | 200 | < 50 |
| App Store rating | ★4.5+ | < ★3.5 |

If a failure line is hit: conduct user interviews → adjust features or consider a pivot.

---

## 9. Post-Launch Roadmap

| Ver | Theme | Key additions |
|---|---|---|
| v1.0 | MVP launch | Recording + Watch + Live Activity |
| v1.1 | Women's support & coaching | Menstrual-cycle integration / HRV & sleep-linked load suggestions |
| v1.2 | AI & exercise expansion | Apple Intelligence summary / home-training exercises (200 total) |
| v1.3 | Sensors | Core ML automatic rep counting |
| v2.0 | Expansion | Vision Pro form check / English UI |

---

## 10. Revenue Model

### Plan Structure

| Plan | Price | Content |
|---|---|---|
| **Free** | Free, ad-free | Basic recording, unlimited history, Apple Watch recording, HealthKit writing, up to 5 routines, up to 5 custom exercises, Live Activity / Dynamic Island |
| **Pro monthly** | ¥780/month | All features unlocked |
| **Pro annual** | ¥5,800/year | All features unlocked (effectively ¥483/month, 38% off vs. monthly) |

### Pro-Only Features

- Bidirectional HealthKit (reading HRV / sleep / resting heart rate)
- 3 AI coaching types (HRV-linked deload suggestion / linear-regression PR prediction / per-muscle volume warning)
- Advanced analytics charts (volume trends / per-muscle / estimated 1RM / PR history)
- Unlimited routines & custom exercises
- iCloud sync (multi-device)
- Family Sharing (up to 6 people)
- Data export (CSV / JSON)

> Live Activity / Dynamic Island was changed to be Free from v0.x. Let all users experience the sharpest differentiator, and concentrate the Pro pitch on HRV × AI coaching.

### Trial & Discount Strategy

- A **14-day free trial** on all plans (credit-card registration required)
- Launch campaign: first 1,000 users or 30 days — 50% off the annual plan (¥2,900)
- Roughly twice a year, a 50%-off annual campaign for new users

### Estimated ARPU

- ¥4,000–5,000 per user per year (weighting annual / monthly / free ratios)

---

## 11. Anticipated Risks

### 11.1 Critical Risks (threaten business continuity)

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Major development-schedule slippage | High | High | Monthly milestone management; decide to cut feature scope if 3 months behind |
| Apple ships strength-specific features natively | Medium | High | Watch each watchOS WWDC closely; keep the coexistence strategy flexible |
| KPIs unmet 6 months post-launch | Medium | High | Follow the exit/pivot decision line (below) |
| Solo-developer burnout | Medium | High | Deliberately reserve rest weeks during development; visualize load via monthly self-reviews |

### 11.2 Important Risks (impede growth)

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Competitor (Hevy) adds Japanese localization | Medium | Medium | Maintain differentiation via "Apple focus + AI coaching" |
| OS major-version update during development (iOS 27) | High | Medium | Continuously track betas; catch API changes early |
| Trademark trouble (existing "OIKOMI" apps) | Low | Medium | Check filing status on J-PlatPat before release; register with a subtitle |
| Users who deny HealthKit permission | Medium | Low | Design basic recording to work even when denied |

### 11.3 Minor Risks (light impact)

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| iOS 26 → 27 API changes | High | Low | Adopt only Apple first-party APIs to minimize impact |
| CloudKit rate limits | Low | Low | Optimize sync frequency; thorough error handling |
| App Store review rejection | Medium | Low | Comply with guidelines; clearly state HealthKit usage purpose |

### 11.4 Exit / Pivot Criteria

At the **6-month mark** post-launch, make a decision if any of the following holds. Fixing the decision milestone prevents hesitation and procrastination.

| Situation | Decision |
|---|---|
| MAU < 500 / cumulative paid < 50 | **Consider exit** — decide to wind down or continue after user interviews |
| MAU 500–1,500 / paid 50–150 | **Consider pivot** — redesign features, pricing, or target |
| MAU > 1,500 / paid > 150 | **Continue & expand** — execute the v1.1+ roadmap |

### 11.5 Risk-Management Operation

- Self-review risk status monthly (track in GitHub Issues)
- Document each risk's "ignition condition" and act upon detection
- Fix the 6-month exit decision line as a decision milestone
- Keep the spec a living document, updated as the situation changes

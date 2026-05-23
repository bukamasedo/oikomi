import Foundation
import SwiftData

#if canImport(HealthKit)
    import HealthKit
#endif

/// 開発・QA 用の現実的なテストデータ生成器。
///
/// `WorkoutSession.notes` / `Routine.name` のプレフィックス、HK サンプルの metadata に
/// マーカーを埋め、後で `clearMockData` でモック分だけを除去できる設計。
///
/// 本番ユーザー向けの UI からは呼ばない（DEBUG ビルドの設定画面からのみ叩く想定）。
@MainActor
public enum MockDataGenerator {

    /// `WorkoutSession.notes` に入れるマーカー。
    public static let sessionNoteMarker = "oikomi.mock"

    /// モックルーティン名のプレフィックス。
    public static let routineNamePrefix = "[Mock] "

    /// HKObject の metadata に入れるキー。
    public static let healthKitMetadataKey = "oikomi.mock"

    public struct Summary: Sendable {
        public let sessionsCreated: Int
        public let setsCreated: Int
        public let routinesCreated: Int
        public let personalRecordsTouched: Int
        public let healthSamplesWritten: Int
        public let didWriteHealthKit: Bool
    }

    // MARK: - Public API

    /// 6 週間分（既定）の現実的なトレーニング履歴 + HealthKit データを生成する。
    ///
    /// - 月 / 水 / 金 を Push / Pull / Legs にローテーション
    /// - 各セッションは 5 種目・3〜4 セット・ウォームアップ込みで構成
    /// - 重量は週次で線形漸増（コンパウンドリフトを主軸）
    /// - 各セッションに HealthSnapshot を紐付け、HealthKit にも HRV / RHR / 睡眠 / 体重 / HKWorkout を書き込む
    /// - HealthKit 書き込み権限が無ければ HK 部分はスキップ（SwiftData 部分のみ生成）
    @discardableResult
    public static func generateRecentHistory(
        context: ModelContext,
        weeks: Int = 6,
        writeToHealthKit: Bool = true,
        referenceDate: Date = Date()
    ) async throws -> Summary {

        // 1) HealthKit 書き込み権限
        let canWriteHK: Bool = await {
            guard writeToHealthKit else { return false }
            do {
                try await HealthStore.shared.requestMockDataWriteAuthorization()
                return true
            } catch {
                return false
            }
        }()

        // 2) Exercise ライブラリが空ならシード投入
        let exerciseRepo = ExerciseRepository(context: context)
        try exerciseRepo.seedIfNeeded()

        // 3) ルーティン作成
        let plans: [RoutinePlan] = [.push, .pull, .legs]
        var routines: [(Routine, RoutinePlan)] = []
        for plan in plans {
            let routine = try makeOrFetchRoutine(
                named: routineNamePrefix + plan.displayName, plan: plan, context: context)
            routines.append((routine, plan))
        }

        // 4) セッション生成
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        guard let startDate = calendar.date(byAdding: .day, value: -(weeks * 7 - 1), to: today) else {
            return Summary(
                sessionsCreated: 0, setsCreated: 0, routinesCreated: routines.count,
                personalRecordsTouched: 0, healthSamplesWritten: 0, didWriteHealthKit: canWriteHK
            )
        }

        var sessionsCount = 0
        var setsCount = 0
        var prCount = 0
        var healthSamples = 0

        let prRepo = PersonalRecordRepository(context: context)

        var trainingDayIndex = 0
        for dayOffset in 0..<(weeks * 7) {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            guard dayStart <= today else { break }

            // 毎日: HealthKit (HRV / RHR / 睡眠 / 体重)
            if canWriteHK {
                let written = await writeDailyHealthSamples(for: dayStart, dayOffset: dayOffset, totalDays: weeks * 7)
                healthSamples += written
            }

            // トレーニング日は月(2) / 水(4) / 金(6)
            let weekday = calendar.component(.weekday, from: dayStart)
            guard weekday == 2 || weekday == 4 || weekday == 6 else { continue }

            let weekIndex = dayOffset / 7

            // ローテーション: Push → Pull → Legs
            let (routine, plan) = routines[trainingDayIndex % routines.count]
            trainingDayIndex += 1

            // 開始時刻 18:30 ± 30 分
            let baseHour = 18
            let baseMin = 30 + (dayOffset % 3 - 1) * 15
            let startedAt =
                calendar.date(
                    bySettingHour: baseHour, minute: max(0, baseMin), second: 0, of: dayStart
                ) ?? dayStart
            let durationSec = 50 * 60 + Int.random(in: -8...12) * 60
            let endedAt = startedAt.addingTimeInterval(TimeInterval(durationSec))

            let session = WorkoutSession(
                startedAt: startedAt,
                endedAt: endedAt,
                notes: sessionNoteMarker,
                routine: routine
            )
            context.insert(session)
            routine.lastUsedAt = startedAt

            // HealthSnapshot（HRV / 睡眠 / RHR の代表値を埋める）
            let (snapHRV, snapSleep, snapRHR) = mockSnapshotValues(weekIndex: weekIndex, dayOffset: dayOffset)
            let snapshot = HealthSnapshot(
                date: startedAt,
                hrvSDNN: snapHRV,
                sleepScore: snapSleep,
                restingHeartRate: snapRHR,
                session: session
            )
            context.insert(snapshot)
            session.healthSnapshot = snapshot

            // セット生成
            var order = 0
            var cursor = startedAt
            for item in plan.items {
                guard let exercise = resolveExercise(nameEn: item.nameEn, context: context) else { continue }

                let weight = item.weight(forWeek: weekIndex)
                let reps = item.reps(forWeek: weekIndex)

                // ウォームアップ（重量種目のみ）
                if item.includeWarmup, let w = weight, w > 0 {
                    let warmupWeight = (w * 0.5).rounded() / 1
                    let warmupReps = max(reps + 3, 8)
                    let warmup = SetRecord(
                        exercise: exercise,
                        session: session,
                        order: order,
                        weight: warmupWeight,
                        reps: warmupReps,
                        isWarmup: true,
                        estimated1RM: nil,
                        restSeconds: 60,
                        completedAt: cursor,
                        isCompleted: true
                    )
                    context.insert(warmup)
                    order += 1
                    setsCount += 1
                    cursor.addTimeInterval(60 + 45)
                }

                for setIdx in 0..<item.sets {
                    // 後半セットは 1〜2 レップ落ちる（疲労表現）
                    let actualReps: Int = {
                        if item.measurementType == .weightReps || item.measurementType == .bodyweightReps {
                            return max(1, reps - (setIdx >= item.sets - 1 ? Int.random(in: 0...2) : 0))
                        }
                        return reps
                    }()

                    let est1RM: Double? = {
                        guard let w = weight, w > 0, actualReps > 0,
                            item.measurementType == .weightReps
                        else { return nil }
                        return OneRepMax.epley(weight: w, reps: actualReps)
                    }()

                    let set = SetRecord(
                        exercise: exercise,
                        session: session,
                        order: order,
                        weight: weight,
                        reps: item.measurementType == .time ? nil : actualReps,
                        durationSeconds: item.measurementType == .time ? actualReps : nil,
                        rpe: 6.5 + Double.random(in: 0...2.5),
                        isWarmup: false,
                        estimated1RM: est1RM,
                        restSeconds: exercise.defaultRestSeconds,
                        completedAt: cursor,
                        isCompleted: true
                    )
                    context.insert(set)
                    order += 1
                    setsCount += 1
                    cursor.addTimeInterval(TimeInterval(exercise.defaultRestSeconds + 45))

                    if (try? prRepo.updateIfNewBest(from: set)) != nil {
                        prCount += 1
                    }
                }
            }

            try context.save()

            // HK Workout 書き込み
            if canWriteHK {
                let uuid = await writeMockWorkout(session: session)
                if let uuid {
                    session.healthKitWorkoutUUID = uuid
                    try? context.save()
                    healthSamples += 1
                }
            }

            sessionsCount += 1
        }

        return Summary(
            sessionsCreated: sessionsCount,
            setsCreated: setsCount,
            routinesCreated: routines.count,
            personalRecordsTouched: prCount,
            healthSamplesWritten: healthSamples,
            didWriteHealthKit: canWriteHK
        )
    }

    /// `MockDataGenerator` が作ったデータを削除する。
    ///
    /// - SwiftData: マーカー付き WorkoutSession・Routine を削除し、PR は全削除して残りセットから再構築
    /// - HealthKit: metadata に `oikomi.mock = true` が付いた sample を全削除
    public static func clearMockData(
        context: ModelContext,
        removeFromHealthKit: Bool = true
    ) async throws {
        let marker = sessionNoteMarker
        let prefix = routineNamePrefix

        // 1) モックセッション（sets / snapshot は cascade）
        let mockSessions = try context.fetch(
            FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { $0.notes == marker }
            )
        )
        for s in mockSessions {
            context.delete(s)
        }

        // 2) モックルーティン
        let mockRoutines = try context.fetch(
            FetchDescriptor<Routine>(
                predicate: #Predicate<Routine> { $0.name.starts(with: prefix) }
            )
        )
        for r in mockRoutines {
            context.delete(r)
        }

        // 3) PR を全消し → 残った非モックセットから再構築
        let allPRs = try context.fetch(FetchDescriptor<PersonalRecord>())
        for pr in allPRs { context.delete(pr) }
        try context.save()

        let remainingSets = try context.fetch(
            FetchDescriptor<SetRecord>(
                predicate: #Predicate<SetRecord> { $0.isCompleted == true && $0.isWarmup == false }
            )
        )
        let prRepo = PersonalRecordRepository(context: context)
        for set in remainingSets {
            _ = try? prRepo.updateIfNewBest(from: set)
        }
        try context.save()

        // 4) HealthKit
        if removeFromHealthKit {
            await deleteMockHealthSamples()
        }
    }

    // MARK: - Helpers

    private static func resolveExercise(nameEn: String, context: ModelContext) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { $0.nameEn == nameEn }
        )
        return try? context.fetch(descriptor).first
    }

    private static func makeOrFetchRoutine(
        named name: String,
        plan: RoutinePlan,
        context: ModelContext
    ) throws -> Routine {
        if let existing = try context.fetch(
            FetchDescriptor<Routine>(predicate: #Predicate<Routine> { $0.name == name })
        ).first {
            return existing
        }
        let routine = Routine(name: name, createdAt: Date())
        context.insert(routine)
        for (idx, item) in plan.items.enumerated() {
            guard let exercise = resolveExercise(nameEn: item.nameEn, context: context) else { continue }
            let entry = RoutineExercise(
                routine: routine,
                exercise: exercise,
                order: idx,
                plannedSets: item.sets,
                plannedReps: item.baseReps,
                plannedWeight: item.baseWeight
            )
            context.insert(entry)
        }
        try context.save()
        return routine
    }

    /// 週次の HRV / 睡眠スコア / RHR の代表値。コンディションの起伏を模擬する。
    private static func mockSnapshotValues(weekIndex: Int, dayOffset: Int) -> (Double, Int, Int) {
        // HRV: 45 ± 12（週初〜週末で揺れる）
        let hrvBase = 45.0 + Double(weekIndex) * 0.6
        let hrvDelta = Double((dayOffset % 7) - 3) * 2.5 + Double.random(in: -4...4)
        let hrv = max(20.0, min(85.0, hrvBase + hrvDelta))

        // sleep score: 60–95
        let sleep = max(45, min(95, 75 + (dayOffset % 5 - 2) * 6 + Int.random(in: -8...8)))

        // RHR: 56–66
        let rhr = max(50, min(70, 58 + (dayOffset % 4 - 1) + Int.random(in: -2...3)))
        return (hrv, sleep, rhr)
    }

    // MARK: - HealthKit Write

    @discardableResult
    private static func writeDailyHealthSamples(for day: Date, dayOffset: Int, totalDays: Int) async -> Int {
        #if canImport(HealthKit)
            let calendar = Calendar.current
            let store = HealthStore.shared.rawStore

            var samples: [HKObject] = []

            // 朝 7:00 に HRV / RHR / 体重を 1 件
            let morning = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: day) ?? day
            let (hrv, sleepScore, rhr) = mockSnapshotValues(weekIndex: dayOffset / 7, dayOffset: dayOffset)
            _ = sleepScore  // 睡眠スコアは派生値なので使わない

            if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
                let quantity = HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: hrv)
                samples.append(
                    HKQuantitySample(
                        type: hrvType,
                        quantity: quantity,
                        start: morning,
                        end: morning,
                        metadata: [healthKitMetadataKey: true]
                    )
                )
            }
            if let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
                let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: Double(rhr))
                samples.append(
                    HKQuantitySample(
                        type: rhrType,
                        quantity: quantity,
                        start: morning,
                        end: morning,
                        metadata: [healthKitMetadataKey: true]
                    )
                )
            }
            // 体重: 70.0kg から微減トレンド
            if let massType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                let progress = Double(dayOffset) / Double(max(1, totalDays - 1))
                let weight = 70.0 - 1.2 * progress + Double.random(in: -0.3...0.3)
                let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
                samples.append(
                    HKQuantitySample(
                        type: massType,
                        quantity: quantity,
                        start: morning,
                        end: morning,
                        metadata: [healthKitMetadataKey: true]
                    )
                )
            }

            // 睡眠: 前夜 23:00 〜 当朝 6:30 を asleepCore で 1 セグメント
            if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
                let sleepStart =
                    calendar.date(
                        byAdding: .hour, value: -1,
                        to: calendar.date(bySettingHour: 0, minute: 0, second: 0, of: day) ?? day) ?? day
                let baseHours = 6.5 + Double((dayOffset % 5)) * 0.3
                let jitter = Double.random(in: -0.6...0.6)
                let hours = max(4.5, min(9.0, baseHours + jitter))
                let sleepEnd = sleepStart.addingTimeInterval(hours * 3600)
                samples.append(
                    HKCategorySample(
                        type: sleepType,
                        value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        start: sleepStart,
                        end: sleepEnd,
                        metadata: [healthKitMetadataKey: true]
                    )
                )
            }

            return await save(samples: samples, store: store)
        #else
            _ = day
            _ = dayOffset
            _ = totalDays
            return 0
        #endif
    }

    private static func writeMockWorkout(session: WorkoutSession) async -> UUID? {
        #if canImport(HealthKit)
            guard let endedAt = session.endedAt else { return nil }
            guard HKHealthStore.isHealthDataAvailable() else { return nil }
            let store = HealthStore.shared.rawStore

            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .traditionalStrengthTraining

            let builder = HKWorkoutBuilder(
                healthStore: store,
                configuration: configuration,
                device: .local()
            )
            do {
                try await builder.beginCollection(at: session.startedAt)
                try await builder.addMetadata([healthKitMetadataKey: true])
                try await builder.endCollection(at: endedAt)
                let workout = try await builder.finishWorkout()
                return workout?.uuid
            } catch {
                return nil
            }
        #else
            _ = session
            return nil
        #endif
    }

    #if canImport(HealthKit)
        private static func save(samples: [HKObject], store: HKHealthStore) async -> Int {
            guard !samples.isEmpty else { return 0 }
            return await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
                store.save(samples) { success, _ in
                    continuation.resume(returning: success ? samples.count : 0)
                }
            }
        }
    #endif

    private static func deleteMockHealthSamples() async {
        #if canImport(HealthKit)
            guard HKHealthStore.isHealthDataAvailable() else { return }
            let store = HealthStore.shared.rawStore

            // metadata に "oikomi.mock" キーがある全レコードを対象
            let predicate = HKQuery.predicateForObjects(withMetadataKey: healthKitMetadataKey)

            var types: [HKSampleType] = [HKObjectType.workoutType()]
            let quantityIDs: [HKQuantityTypeIdentifier] = [
                .heartRateVariabilitySDNN, .restingHeartRate, .bodyMass,
            ]
            for id in quantityIDs {
                if let t = HKQuantityType.quantityType(forIdentifier: id) {
                    types.append(t)
                }
            }
            if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
                types.append(sleep)
            }
            for type in types {
                _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                    store.deleteObjects(of: type, predicate: predicate) { success, _, _ in
                        continuation.resume(returning: success)
                    }
                }
            }
        #endif
    }
}

// MARK: - Routine Plan

/// ルーティンと進行プランを表現する宣言的データ。
public struct RoutinePlan: Sendable {
    public let displayName: String
    public let items: [RoutineItem]

    public static let push = RoutinePlan(
        displayName: "プッシュ",
        items: [
            RoutineItem(
                nameEn: "Barbell Bench Press - Medium Grip",
                sets: 4, baseReps: 5, baseWeight: 60.0,
                weeklyWeightIncrement: 2.5, repsCurve: [5, 5, 5, 5, 5, 5],
                measurementType: .weightReps, includeWarmup: true
            ),
            RoutineItem(
                nameEn: "Standing Military Press",
                sets: 3, baseReps: 8, baseWeight: 35.0,
                weeklyWeightIncrement: 1.25, repsCurve: [8, 8, 8, 8, 8, 8],
                measurementType: .weightReps, includeWarmup: true
            ),
            RoutineItem(
                nameEn: "Dumbbell Bench Press",
                sets: 3, baseReps: 10, baseWeight: 22.0,
                weeklyWeightIncrement: 1.0, repsCurve: [10, 10, 10, 10, 10, 10],
                measurementType: .weightReps, includeWarmup: false
            ),
            RoutineItem(
                nameEn: "Triceps Pushdown",
                sets: 3, baseReps: 12, baseWeight: 25.0,
                weeklyWeightIncrement: 1.0, repsCurve: [12, 12, 12, 12, 12, 12],
                measurementType: .weightReps, includeWarmup: false
            ),
            RoutineItem(
                nameEn: "Side Lateral Raise",
                sets: 3, baseReps: 15, baseWeight: 8.0,
                weeklyWeightIncrement: 0.5, repsCurve: [15, 15, 15, 15, 15, 15],
                measurementType: .weightReps, includeWarmup: false
            ),
        ]
    )

    public static let pull = RoutinePlan(
        displayName: "プル",
        items: [
            RoutineItem(
                nameEn: "Barbell Deadlift",
                sets: 3, baseReps: 5, baseWeight: 100.0,
                weeklyWeightIncrement: 5.0, repsCurve: [5, 5, 5, 5, 5, 5],
                measurementType: .weightReps, includeWarmup: true
            ),
            RoutineItem(
                nameEn: "Pullups",
                sets: 3, baseReps: 6, baseWeight: nil,
                weeklyWeightIncrement: 0, repsCurve: [6, 7, 7, 8, 8, 9],
                measurementType: .bodyweightReps, includeWarmup: false
            ),
            RoutineItem(
                nameEn: "Bent Over Barbell Row",
                sets: 3, baseReps: 8, baseWeight: 60.0,
                weeklyWeightIncrement: 2.5, repsCurve: [8, 8, 8, 8, 8, 8],
                measurementType: .weightReps, includeWarmup: true
            ),
            RoutineItem(
                nameEn: "Wide-Grip Lat Pulldown",
                sets: 3, baseReps: 10, baseWeight: 50.0,
                weeklyWeightIncrement: 2.5, repsCurve: [10, 10, 10, 10, 10, 10],
                measurementType: .weightReps, includeWarmup: false
            ),
            RoutineItem(
                nameEn: "Hammer Curls",
                sets: 3, baseReps: 12, baseWeight: 12.0,
                weeklyWeightIncrement: 0.5, repsCurve: [12, 12, 12, 12, 12, 12],
                measurementType: .weightReps, includeWarmup: false
            ),
        ]
    )

    public static let legs = RoutinePlan(
        displayName: "レッグ",
        items: [
            RoutineItem(
                nameEn: "Barbell Squat",
                sets: 4, baseReps: 5, baseWeight: 80.0,
                weeklyWeightIncrement: 5.0, repsCurve: [5, 5, 5, 5, 5, 5],
                measurementType: .weightReps, includeWarmup: true
            ),
            RoutineItem(
                nameEn: "Romanian Deadlift",
                sets: 3, baseReps: 8, baseWeight: 70.0,
                weeklyWeightIncrement: 2.5, repsCurve: [8, 8, 8, 8, 8, 8],
                measurementType: .weightReps, includeWarmup: true
            ),
            RoutineItem(
                nameEn: "Leg Press",
                sets: 3, baseReps: 10, baseWeight: 120.0,
                weeklyWeightIncrement: 5.0, repsCurve: [10, 10, 10, 10, 10, 10],
                measurementType: .weightReps, includeWarmup: false
            ),
            RoutineItem(
                nameEn: "Lying Leg Curls",
                sets: 3, baseReps: 12, baseWeight: 35.0,
                weeklyWeightIncrement: 1.25, repsCurve: [12, 12, 12, 12, 12, 12],
                measurementType: .weightReps, includeWarmup: false
            ),
            RoutineItem(
                nameEn: "Standing Calf Raises",
                sets: 3, baseReps: 15, baseWeight: 60.0,
                weeklyWeightIncrement: 2.5, repsCurve: [15, 15, 15, 15, 15, 15],
                measurementType: .weightReps, includeWarmup: false
            ),
        ]
    )
}

/// ルーティンを構成する 1 種目分の進行プラン。
public struct RoutineItem: Sendable {
    public let nameEn: String
    public let sets: Int
    public let baseReps: Int
    public let baseWeight: Double?
    public let weeklyWeightIncrement: Double
    public let repsCurve: [Int]
    public let measurementType: MeasurementType
    public let includeWarmup: Bool

    public init(
        nameEn: String,
        sets: Int,
        baseReps: Int,
        baseWeight: Double?,
        weeklyWeightIncrement: Double,
        repsCurve: [Int],
        measurementType: MeasurementType,
        includeWarmup: Bool
    ) {
        self.nameEn = nameEn
        self.sets = sets
        self.baseReps = baseReps
        self.baseWeight = baseWeight
        self.weeklyWeightIncrement = weeklyWeightIncrement
        self.repsCurve = repsCurve
        self.measurementType = measurementType
        self.includeWarmup = includeWarmup
    }

    func weight(forWeek week: Int) -> Double? {
        guard let base = baseWeight else { return nil }
        return base + weeklyWeightIncrement * Double(week)
    }

    func reps(forWeek week: Int) -> Int {
        guard !repsCurve.isEmpty else { return baseReps }
        let idx = min(week, repsCurve.count - 1)
        return repsCurve[idx]
    }
}

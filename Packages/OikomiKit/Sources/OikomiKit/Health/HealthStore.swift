import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// HealthKit との連携を扱う薄いラッパー。
///
/// 仕様書 §4.2.1: 「書き込み: HKWorkout, bodyMass, bodyFatPercentage, leanBodyMass」
/// v0.1 では HKWorkout 書き込みのみ。読み取り（HRV / 睡眠など）は Pro 機能で後述。
///
/// HealthKit が利用できないプラットフォームでは no-op として動作するよう設計。
@MainActor
public final class HealthStore {

    public enum HealthStoreError: Error, Sendable {
        case notAvailable
        case authorizationDenied
        case workoutSaveFailed
    }

    public static let shared = HealthStore()

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    #endif

    private init() {}

    /// HealthKit がこのデバイスで利用可能か。
    public var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    /// HKWorkout への書き込み + HRV / 睡眠 / 安静時心拍数の読み取り権限をリクエストする。
    ///
    /// 初回呼び出し時にシステム UI が出る。ユーザーが拒否しても例外は投げず、
    /// 以降の save / fetch 呼び出しが失敗するだけの設計。
    public func requestWorkoutWriteAuthorization() async throws {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthStoreError.notAvailable
        }
        let toShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        var toRead: Set<HKObjectType> = []
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            toRead.insert(hrv)
        }
        if let resting = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            toRead.insert(resting)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            toRead.insert(sleep)
        }
        try await store.requestAuthorization(toShare: toShare, read: toRead)
        #else
        throw HealthStoreError.notAvailable
        #endif
    }

    /// 直近 24 時間の HRV / 睡眠 / 安静時心拍数を取得してスナップショットを返す。
    ///
    /// 仕様書 §6.5「セッション開始時に HealthKit から HRV / 睡眠スコア / 安静時心拍数を取得しキャッシュ」。
    /// 権限拒否 / データなしの場合は対応フィールドが nil の Snapshot を返す。
    /// **Pro 限定機能**: Free プランでは空の Snapshot を返す（仕様書 §10）。
    public func fetchSnapshot(referenceDate: Date = Date()) async -> HealthSnapshot {
        let snapshot = HealthSnapshot(date: referenceDate)
        // Pro 機能ゲート: Free プランは HRV / 睡眠 / 安静時心拍数の読み取り不可
        guard await MainActor.run(body: { ProGate.canReadHealthData }) else {
            return snapshot
        }
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return snapshot }

        if let hrv = await latestQuantity(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli)) {
            snapshot.hrvSDNN = hrv
        }
        if let resting = await latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            snapshot.restingHeartRate = Int(resting.rounded())
        }
        if let sleepScore = await latestSleepScore() {
            snapshot.sleepScore = sleepScore
        }
        #endif
        return snapshot
    }

    #if canImport(HealthKit)
    /// 指定 quantity の直近 1 件の値を取得。
    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-7 * 24 * 3600),
            end: Date(),
            options: .strictEndDate
        )
        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: sortDescriptors
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    /// 直近の睡眠スコア（0〜100）を計算。
    /// 仕様書では睡眠スコアと記載しているが、Apple純正には素のスコア値がないため、
    /// 直近の睡眠時間 (asleep) 合計 / 8 時間 × 100 で簡易算出。8時間以上は 100。
    private func latestSleepScore() async -> Int? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        // 直近 24 時間
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-24 * 3600),
            end: Date(),
            options: .strictEndDate
        )
        return await withCheckedContinuation { (continuation: CheckedContinuation<Int?, Never>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                ]
                let totalSeconds: TimeInterval = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0) { acc, sample in
                        acc + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                let hours = totalSeconds / 3600
                let score = min(100, Int((hours / 8.0 * 100).rounded()))
                continuation.resume(returning: score)
            }
            store.execute(query)
        }
    }
    #endif

    /// 終了済みワークアウトセッションを HKWorkout として保存する。
    ///
    /// セッションに endedAt が無い、または HealthKit 利用不可なら早期 return（例外なし）。
    /// 保存に成功したら HKWorkout の UUID を返す。
    @discardableResult
    public func saveWorkout(_ session: WorkoutSession) async throws -> UUID? {
        guard let endedAt = session.endedAt else { return nil }

        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )
        do {
            try await builder.beginCollection(at: session.startedAt)
            try await builder.endCollection(at: endedAt)
            let workout = try await builder.finishWorkout()
            return workout?.uuid
        } catch {
            throw HealthStoreError.workoutSaveFailed
        }
        #else
        return nil
        #endif
    }
}

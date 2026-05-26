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

    /// HKWorkout への書き込み + HRV / 睡眠 / 安静時心拍数 / 体組成 (体重・体脂肪率・LBM) の読み取り権限をリクエストする。
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
            let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
                .heartRateVariabilitySDNN,
                .restingHeartRate,
                .bodyMass,
                .bodyFatPercentage,
                .leanBodyMass,
            ]
            for identifier in quantityIdentifiers {
                if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                    toRead.insert(type)
                }
            }
            if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                toRead.insert(sleep)
            }
            try await store.requestAuthorization(toShare: toShare, read: toRead)
        #else
            throw HealthStoreError.notAvailable
        #endif
    }

    /// 開発・テストデータ生成用に、HRV / 安静時心拍数 / 睡眠 / 体重等の**書き込み**権限も併せて要求する。
    ///
    /// 本来の利用フロー（仕様書 §4.2.1）では Oikomi はこれらを「読み取り」のみ。
    /// `MockDataGenerator` がリアルな HealthKit データを書き込むためだけに用意した
    /// 開発用エンドポイント。ユーザー向けの UI からは呼ばない想定。
    public func requestMockDataWriteAuthorization() async throws {
        #if canImport(HealthKit)
            guard HKHealthStore.isHealthDataAvailable() else {
                throw HealthStoreError.notAvailable
            }
            var toShare: Set<HKSampleType> = [HKObjectType.workoutType()]
            let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
                .heartRateVariabilitySDNN,
                .restingHeartRate,
                .bodyMass,
            ]
            for identifier in quantityIdentifiers {
                if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                    toShare.insert(type)
                }
            }
            if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                toShare.insert(sleep)
            }
            try await store.requestAuthorization(toShare: toShare, read: toShare)
        #else
            throw HealthStoreError.notAvailable
        #endif
    }

    #if canImport(HealthKit)
        /// 内部 HealthStore へのアクセス。`MockDataGenerator` から HK サンプルを保存・削除するために公開。
        internal var rawStore: HKHealthStore { store }
    #endif

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
                    let totalSeconds: TimeInterval =
                        samples
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

    // MARK: - 今日の最新値 / 推移取得 (Pro 限定)

    /// HealthKit 読み取り対応の指標。HealthKit 型を UI 層に漏らさないための薄い enum。
    public enum HealthMetric: String, Sendable, CaseIterable {
        case bodyMass  // kg
        case bodyFatPercentage  // 0.0–1.0 (UI 表示時に *100)
        case leanBodyMass  // kg
        case hrv  // ms (SDNN)
        case restingHeartRate  // bpm
        case sleepHours  // hours
    }

    /// 指定指標の「直近値」を取得する。Pro 未契約・データなし・権限拒否はすべて nil。
    public func todayValue(for metric: HealthMetric) async -> Double? {
        guard ProGate.canReadHealthData else { return nil }
        #if canImport(HealthKit)
            guard HKHealthStore.isHealthDataAvailable() else { return nil }
            switch metric {
            case .sleepHours:
                return await latestSleepHours()
            case .bodyMass, .bodyFatPercentage, .leanBodyMass, .hrv, .restingHeartRate:
                guard let (identifier, unit) = quantitySpec(for: metric) else { return nil }
                return await latestQuantity(identifier, unit: unit)
            }
        #else
            return nil
        #endif
    }

    /// 直近 N 日（`endingAt` 含む）の HRV 平均を返す。Pro 未契約・データなし・権限拒否は nil。
    ///
    /// 7 日間のような短い期間で「今日のコンディションが普段比どうか」を簡易判定する用途。
    /// `dailySeries(.hrv, days:)` を再利用して移動平均を取る。
    public func hrvAverage(days: Int, endingAt: Date = Date()) async -> Double? {
        guard days > 0, ProGate.canReadHealthData else { return nil }
        let series = await dailySeries(for: .hrv, days: days)
        let values = series.map(\.value).filter { $0 > 0 }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// 指定指標の日次推移を取得する。古い順。Pro 未契約・データなし・権限拒否はすべて空配列。
    public func dailySeries(for metric: HealthMetric, days: Int) async -> [HealthTrendPoint] {
        guard days > 0, ProGate.canReadHealthData else { return [] }
        #if canImport(HealthKit)
            guard HKHealthStore.isHealthDataAvailable() else { return [] }
            switch metric {
            case .sleepHours:
                return await dailySleepHoursSeries(days: days)
            case .bodyMass, .bodyFatPercentage, .leanBodyMass, .hrv, .restingHeartRate:
                guard let (identifier, unit) = quantitySpec(for: metric) else { return [] }
                return await dailyQuantitySeries(
                    identifier,
                    unit: unit,
                    days: days,
                    options: .discreteAverage
                )
            }
        #else
            return []
        #endif
    }

    #if canImport(HealthKit)
        /// `HealthMetric` を HealthKit の (identifier, unit) ペアにマップ。
        private func quantitySpec(
            for metric: HealthMetric
        ) -> (HKQuantityTypeIdentifier, HKUnit)? {
            switch metric {
            case .bodyMass:
                return (.bodyMass, HKUnit.gramUnit(with: .kilo))
            case .bodyFatPercentage:
                return (.bodyFatPercentage, HKUnit.percent())
            case .leanBodyMass:
                return (.leanBodyMass, HKUnit.gramUnit(with: .kilo))
            case .hrv:
                return (.heartRateVariabilitySDNN, HKUnit.secondUnit(with: .milli))
            case .restingHeartRate:
                return (.restingHeartRate, HKUnit.count().unitDivided(by: .minute()))
            case .sleepHours:
                return nil
            }
        }

        /// 指定 quantity の日次推移を `HKStatisticsCollectionQuery` で取得。
        private func dailyQuantitySeries(
            _ identifier: HKQuantityTypeIdentifier,
            unit: HKUnit,
            days: Int,
            options: HKStatisticsOptions
        ) async -> [HealthTrendPoint] {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
            let calendar = Calendar.current
            let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(24 * 3600)
            guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate, end: endDate, options: .strictStartDate
            )

            return await withCheckedContinuation { (continuation: CheckedContinuation<[HealthTrendPoint], Never>) in
                let query = HKStatisticsCollectionQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: options,
                    anchorDate: calendar.startOfDay(for: startDate),
                    intervalComponents: DateComponents(day: 1)
                )
                query.initialResultsHandler = { _, results, _ in
                    guard let results else {
                        continuation.resume(returning: [])
                        return
                    }
                    var points: [HealthTrendPoint] = []
                    results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                        let quantity: HKQuantity? =
                            (options == .cumulativeSum)
                            ? statistics.sumQuantity()
                            : statistics.averageQuantity()
                        if let value = quantity?.doubleValue(for: unit) {
                            points.append(HealthTrendPoint(date: statistics.startDate, value: value))
                        }
                    }
                    continuation.resume(returning: points)
                }
                store.execute(query)
            }
        }

        /// 直近 24h の総睡眠時間を「時間」単位で返す。`asleep*` のみカウント。
        private func latestSleepHours() async -> Double? {
            guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
            let predicate = HKQuery.predicateForSamples(
                withStart: Date().addingTimeInterval(-24 * 3600),
                end: Date(),
                options: .strictEndDate
            )
            return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
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
                    let totalSeconds: TimeInterval =
                        samples
                        .filter { asleepValues.contains($0.value) }
                        .reduce(0) { acc, sample in
                            acc + sample.endDate.timeIntervalSince(sample.startDate)
                        }
                    continuation.resume(returning: totalSeconds / 3600)
                }
                store.execute(query)
            }
        }

        /// 直近 N 日の日別睡眠時間（時間）を返す。古い順。
        ///
        /// 睡眠サンプルは「就寝〜起床」が日付をまたぐため、`startDate` の日付でバケットする。
        /// 日次集計は `HKCategoryType` 用の StatisticsQuery が無いため自前 reduce。
        private func dailySleepHoursSeries(days: Int) async -> [HealthTrendPoint] {
            guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
            let calendar = Calendar.current
            let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(24 * 3600)
            guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate, end: endDate, options: .strictStartDate
            )
            return await withCheckedContinuation { (continuation: CheckedContinuation<[HealthTrendPoint], Never>) in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, samples, _ in
                    guard let samples = samples as? [HKCategorySample] else {
                        continuation.resume(returning: [])
                        return
                    }
                    let asleepValues: Set<Int> = [
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                        HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    ]
                    var bucketed: [Date: TimeInterval] = [:]
                    for sample in samples where asleepValues.contains(sample.value) {
                        let day = calendar.startOfDay(for: sample.startDate)
                        bucketed[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                    let points =
                        bucketed
                        .map { HealthTrendPoint(date: $0.key, value: $0.value / 3600) }
                        .sorted { $0.date < $1.date }
                    continuation.resume(returning: points)
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

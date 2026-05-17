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

    /// HKWorkout への書き込み権限をリクエストする。
    ///
    /// 初回呼び出し時にシステム UI が出る。ユーザーが拒否しても例外は投げず、
    /// 以降の save 呼び出しが失敗するだけの設計。
    public func requestWorkoutWriteAuthorization() async throws {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthStoreError.notAvailable
        }
        let toShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        try await store.requestAuthorization(toShare: toShare, read: [])
        #else
        throw HealthStoreError.notAvailable
        #endif
    }

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

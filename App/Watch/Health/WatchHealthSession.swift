import Foundation
import HealthKit

/// watchOS で HKWorkoutSession + HKLiveWorkoutBuilder を管理する。
///
/// 仕様書§4.1.3 / §4.2.4: Apple Watch スタンドアロン記録時に活動リング貢献 +
/// Workout Buddy（watchOS 26 純正）との並行動作を可能にする。
@MainActor
final class WatchHealthSession {

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    /// セッション開始時に呼ぶ。失敗しても Watch 上の Oikomi セッション記録には影響させない。
    func start() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        do {
            // 権限がまだなら取得
            try await store.requestAuthorization(
                toShare: [HKObjectType.workoutType()],
                read: []
            )

            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: store,
                workoutConfiguration: config
            )

            session.startActivity(with: Date())
            try await builder.beginCollection(at: Date())

            self.session = session
            self.builder = builder
        } catch {
            // 権限拒否 or セッション開始失敗：黙って受け流す
        }
    }

    /// セッション終了時に呼ぶ。HKWorkout として保存し、ringに貢献する。
    func end() async {
        guard let session, let builder else { return }
        let endDate = Date()
        session.end()
        do {
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
        } catch {
            // 保存失敗は黙って受け流す
        }
        self.session = nil
        self.builder = nil
    }
}

import Foundation
import Testing

@testable import OikomiKit

@Suite("RestTimerStore")
@MainActor
struct RestTimerStoreTests {

    /// テスト用に singleton 状態を毎回リセット。
    private func resetStore() {
        RestTimerStore.shared.cancel()
    }

    @Test("start で endAt / totalSeconds / weight / reps が反映される")
    func startSetsAllFields() {
        resetStore()
        let endAt = Date().addingTimeInterval(120)
        RestTimerStore.shared.start(
            endAt: endAt,
            totalSeconds: 120,
            completedWeightKg: 80,
            completedReps: 5
        )
        #expect(RestTimerStore.shared.endAt == endAt)
        #expect(RestTimerStore.shared.totalSeconds == 120)
        #expect(RestTimerStore.shared.completedWeightKg == 80)
        #expect(RestTimerStore.shared.completedReps == 5)
    }

    @Test("totalSeconds は最低 1 にクランプされる")
    func totalSecondsClampsToOne() {
        resetStore()
        RestTimerStore.shared.start(
            endAt: Date().addingTimeInterval(60),
            totalSeconds: 0
        )
        #expect(RestTimerStore.shared.totalSeconds == 1)
    }

    @Test("cancel で endAt / weight / reps がクリアされる")
    func cancelClearsFields() {
        resetStore()
        RestTimerStore.shared.start(
            endAt: Date().addingTimeInterval(60),
            totalSeconds: 60,
            completedWeightKg: 100,
            completedReps: 3
        )
        RestTimerStore.shared.cancel()
        #expect(RestTimerStore.shared.endAt == nil)
        #expect(RestTimerStore.shared.completedWeightKg == nil)
        #expect(RestTimerStore.shared.completedReps == nil)
    }

    @Test("expireIfPast は終了済みタイマーを自動クリア")
    func expireIfPastClearsExpired() {
        resetStore()
        let past = Date().addingTimeInterval(-5)
        RestTimerStore.shared.start(endAt: past, totalSeconds: 60)
        RestTimerStore.shared.expireIfPast()
        #expect(RestTimerStore.shared.endAt == nil)
    }

    @Test("expireIfPast は未来のタイマーには触らない")
    func expireIfPastIgnoresFuture() {
        resetStore()
        let future = Date().addingTimeInterval(60)
        RestTimerStore.shared.start(endAt: future, totalSeconds: 60)
        RestTimerStore.shared.expireIfPast()
        #expect(RestTimerStore.shared.endAt == future)
    }

    @Test("handleSync の restTimerStart で endAt / totalSeconds / weight / reps が更新される")
    func handleSyncStartUpdatesAll() {
        resetStore()
        let endAt = Date().addingTimeInterval(90)
        RestTimerStore.shared.handleSync(
            kind: SyncEnvelope.Kind.restTimerStart.rawValue,
            endAt: endAt,
            totalSeconds: 90,
            completedWeightKg: 60.0,
            completedReps: 8
        )
        #expect(RestTimerStore.shared.endAt == endAt)
        #expect(RestTimerStore.shared.totalSeconds == 90)
        #expect(RestTimerStore.shared.completedWeightKg == 60.0)
        #expect(RestTimerStore.shared.completedReps == 8)
    }

    @Test("handleSync の restTimerCancel で Store がクリアされる")
    func handleSyncCancelClears() {
        resetStore()
        RestTimerStore.shared.start(
            endAt: Date().addingTimeInterval(60),
            totalSeconds: 60
        )
        RestTimerStore.shared.handleSync(
            kind: SyncEnvelope.Kind.restTimerCancel.rawValue,
            endAt: nil,
            totalSeconds: nil,
            completedWeightKg: nil,
            completedReps: nil
        )
        #expect(RestTimerStore.shared.endAt == nil)
    }

    @Test("過去 endAt の handleSync(start) は無視される")
    func handleSyncIgnoresExpiredStart() {
        resetStore()
        let past = Date().addingTimeInterval(-10)
        RestTimerStore.shared.handleSync(
            kind: SyncEnvelope.Kind.restTimerStart.rawValue,
            endAt: past,
            totalSeconds: 60,
            completedWeightKg: nil,
            completedReps: nil
        )
        #expect(RestTimerStore.shared.endAt == nil)
    }

    @Test("未知の kind は何もしない")
    func handleSyncUnknownKindIsNoOp() {
        resetStore()
        let endAt = Date().addingTimeInterval(60)
        RestTimerStore.shared.start(endAt: endAt, totalSeconds: 60)
        RestTimerStore.shared.handleSync(
            kind: "unknown",
            endAt: nil,
            totalSeconds: nil,
            completedWeightKg: nil,
            completedReps: nil
        )
        #expect(RestTimerStore.shared.endAt == endAt)
    }
}

import Foundation
import Testing

@testable import OikomiKit

@Suite("ConditionSnapshot")
struct ConditionSnapshotTests {

    /// テスト用に分離した in-memory UserDefaults を生成する。
    private func ephemeralDefaults() -> UserDefaults {
        let suiteName = "condition-snapshot-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func sampleSnapshot(savedAt: Date) -> ConditionSnapshot {
        ConditionSnapshot(
            value: 72,
            band: ReadinessScore.Band.high.rawValue,
            confidence: ReadinessScore.Confidence.high.rawValue,
            sourceNote: nil,
            hrv: 48,
            restingHeartRate: 58,
            sleepHours: 7.2,
            savedAt: savedAt
        )
    }

    @Test("save → todaySnapshot の往復で値が復元される")
    func roundtrip() {
        let defaults = ephemeralDefaults()
        let now = Date()
        ConditionSnapshotStore.save(sampleSnapshot(savedAt: now), defaults: defaults)

        let loaded = ConditionSnapshotStore.todaySnapshot(referenceDate: now, defaults: defaults)
        #expect(loaded?.value == 72)
        #expect(loaded?.band == ReadinessScore.Band.high.rawValue)
        #expect(loaded?.hrv == 48)
        #expect(loaded?.restingHeartRate == 58)
        #expect(loaded?.sleepHours == 7.2)
    }

    @Test("ReadinessScore からの組み立てで value/band/note が転写される")
    func fromReadiness() {
        let readiness = ReadinessScore(
            value: 35, band: .low, confidence: .medium, hrvZ: -1.2,
            usedSignals: [.hrv, .sleep])
        let snapshot = ConditionSnapshot(
            readiness: readiness, hrv: 30, restingHeartRate: 70, sleepHours: 5.0)
        #expect(snapshot.value == 35)
        #expect(snapshot.band == ReadinessScore.Band.low.rawValue)
        #expect(snapshot.confidence == ReadinessScore.Confidence.medium.rawValue)
        #expect(snapshot.sourceNote == readiness.sourceNote)
    }

    @Test("前日保存分は todaySnapshot で nil（日付またぎ）")
    func staleSnapshotRejected() {
        let defaults = ephemeralDefaults()
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        ConditionSnapshotStore.save(sampleSnapshot(savedAt: yesterday), defaults: defaults)

        #expect(ConditionSnapshotStore.todaySnapshot(referenceDate: now, defaults: defaults) == nil)
    }

    @Test("clear で削除され todaySnapshot は nil")
    func clearRemoves() {
        let defaults = ephemeralDefaults()
        let now = Date()
        ConditionSnapshotStore.save(sampleSnapshot(savedAt: now), defaults: defaults)
        ConditionSnapshotStore.clear(defaults: defaults)
        #expect(ConditionSnapshotStore.todaySnapshot(referenceDate: now, defaults: defaults) == nil)
    }

    @Test("未保存なら todaySnapshot は nil")
    func emptyReturnsNil() {
        let defaults = ephemeralDefaults()
        #expect(ConditionSnapshotStore.todaySnapshot(defaults: defaults) == nil)
    }
}

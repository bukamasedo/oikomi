import Foundation
import Testing

@testable import OikomiKit

@Suite("RelativeStrength")
struct RelativeStrengthTests {

    @Test("体重比 = 1RM / 体重")
    func ratioComputed() {
        let bench = Exercise(name: "ベンチプレス")
        let pr = PersonalRecord(exercise: bench, weight: 90, reps: 1, estimated1RM: 100)
        let rows = RelativeStrength.report(records: [pr], bodyweightKg: 80)
        #expect(rows.count == 1)
        #expect(rows[0].exerciseName == "ベンチプレス")
        #expect(abs(rows[0].ratio - 1.25) < 0.0001)
    }

    @Test("体重比降順でソートされる")
    func sortedByRatioDesc() {
        let squat = Exercise(name: "スクワット")
        let curl = Exercise(name: "アームカール")
        let prSquat = PersonalRecord(exercise: squat, estimated1RM: 160)  // 2.0x
        let prCurl = PersonalRecord(exercise: curl, estimated1RM: 40)  // 0.5x
        let rows = RelativeStrength.report(records: [prCurl, prSquat], bodyweightKg: 80)
        #expect(rows.map(\.exerciseName) == ["スクワット", "アームカール"])
    }

    @Test("自重種目（estimated1RM <= 0）は除外")
    func excludesZeroOneRM() {
        let pullup = Exercise(name: "懸垂")
        let pr = PersonalRecord(exercise: pullup, estimated1RM: 0)
        let rows = RelativeStrength.report(records: [pr], bodyweightKg: 80)
        #expect(rows.isEmpty)
    }

    @Test("体重未取得（<= 0）で空配列")
    func emptyWhenNoBodyweight() {
        let bench = Exercise(name: "ベンチプレス")
        let pr = PersonalRecord(exercise: bench, estimated1RM: 100)
        #expect(RelativeStrength.report(records: [pr], bodyweightKg: 0).isEmpty)
    }
}

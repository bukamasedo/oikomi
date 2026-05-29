import Testing

@testable import OikomiKit

@Suite("Exercise.usesWeight")
struct ExerciseUsesWeightTests {

    @Test("バーベル × 重量レップ → 重量あり")
    func barbellWeightReps() {
        let ex = Exercise(name: "ベンチプレス", equipment: .barbell, measurementType: .weightReps)
        #expect(ex.usesWeight == true)
    }

    @Test("自重 × 自重レップ → 重量なし")
    func bodyweightReps() {
        let ex = Exercise(name: "懸垂", equipment: .bodyweight, measurementType: .bodyweightReps)
        #expect(ex.usesWeight == false)
    }

    @Test("自重 × 時間計測（プランク） → 重量なし")
    func bodyweightTime() {
        let ex = Exercise(name: "プランク", equipment: .bodyweight, measurementType: .time)
        #expect(ex.usesWeight == false)
    }

    /// 旧フォームで equipment=自重 だが measurementType が既定の .weightReps のまま
    /// 作成された「壊れた」カスタム種目。equipment を見て重量なしと判定できること（本修正の主眼）。
    @Test("自重 × 重量レップ（旧バグで作られた不整合データ） → 重量なし")
    func bodyweightButWeightRepsIsTreatedAsBodyweight() {
        let ex = Exercise(name: "自重カスタム", equipment: .bodyweight, measurementType: .weightReps)
        #expect(ex.usesWeight == false)
    }

    @Test("その他 × 重量レップ（加重種目） → 重量あり")
    func weightedVariantUsesWeight() {
        let ex = Exercise(name: "ウェイテッドプルアップ", equipment: .other, measurementType: .weightReps)
        #expect(ex.usesWeight == true)
    }

    @Test("自重以外 × 時間計測 → 重量なし")
    func nonBodyweightTimeHasNoWeight() {
        let ex = Exercise(name: "ファーマーズウォーク（時間）", equipment: .dumbbell, measurementType: .time)
        #expect(ex.usesWeight == false)
    }
}

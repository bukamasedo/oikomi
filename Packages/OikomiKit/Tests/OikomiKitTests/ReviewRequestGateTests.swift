import Foundation
import Testing

@testable import OikomiKit

@Suite("ReviewRequestGate")
struct ReviewRequestGateTests {

    /// 各テストで独立した UserDefaults を使う（共有 .standard を汚さない）。
    private func freshDefaults() -> UserDefaults {
        let name = "ReviewGateTest_\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    private let day: TimeInterval = 24 * 60 * 60
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("マイルストーン未満なら nil")
    func belowFirstMilestone() {
        let d = freshDefaults()
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 0, defaults: d, now: t0) == nil)
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 2, defaults: d, now: t0) == nil)
    }

    @Test("ちょうど 3 回で最初のマイルストーン 3 を返す")
    func firstMilestoneAtThree() {
        let d = freshDefaults()
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 3, defaults: d, now: t0) == 3)
    }

    @Test("3 を超えても、未消化の最大マイルストーン（=3）を返す")
    func returnsLargestUnconsumedAtOrBelowCount() {
        let d = freshDefaults()
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 5, defaults: d, now: t0) == 3)
    }

    @Test("3 消化後・15 未満は再依頼しない")
    func noRepeatUntilNextMilestone() {
        let d = freshDefaults()
        ReviewRequestGate.markRequested(milestone: 3, defaults: d, now: t0)
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 10, defaults: d, now: t0 + 200 * day) == nil)
    }

    @Test("15 到達でも前回依頼から 90 日未満なら nil")
    func intervalGuardBlocksWithin90Days() {
        let d = freshDefaults()
        ReviewRequestGate.markRequested(milestone: 3, defaults: d, now: t0)
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 15, defaults: d, now: t0 + 80 * day) == nil)
    }

    @Test("15 到達かつ 90 日経過で 15 を返す")
    func nextMilestoneAfterInterval() {
        let d = freshDefaults()
        ReviewRequestGate.markRequested(milestone: 3, defaults: d, now: t0)
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 15, defaults: d, now: t0 + 90 * day) == 15)
    }

    @Test("markRequested が状態を永続化し、同条件では nil になる")
    func markRequestedPersists() {
        let d = freshDefaults()
        let due = ReviewRequestGate.milestoneDue(completedSessionCount: 3, defaults: d, now: t0)
        #expect(due == 3)
        ReviewRequestGate.markRequested(milestone: due!, defaults: d, now: t0)
        // 直後・同カウントでは消化済み＋90日未満で出さない
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 3, defaults: d, now: t0 + day) == nil)
    }

    @Test("一気に 50 まで到達したら最大の未消化マイルストーン 40 を返す")
    func jumpsToHighestMilestone() {
        let d = freshDefaults()
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 50, defaults: d, now: t0) == 40)
    }

    @Test("全マイルストーン消化後は二度と出さない")
    func noneAfterAllConsumed() {
        let d = freshDefaults()
        ReviewRequestGate.markRequested(milestone: 40, defaults: d, now: t0)
        #expect(ReviewRequestGate.milestoneDue(completedSessionCount: 100, defaults: d, now: t0 + 365 * day) == nil)
    }
}

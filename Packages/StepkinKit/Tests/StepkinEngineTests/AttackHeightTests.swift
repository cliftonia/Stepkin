import Testing
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("AttackHeight")
struct AttackHeightTests {

    @Test(arguments: [
        (AttackHeight.high, AttackHeight.medium),
        (AttackHeight.medium, AttackHeight.low),
        (AttackHeight.low, AttackHeight.high)
    ])
    func `height beats the correct opponent`(
        winner: AttackHeight,
        loser: AttackHeight
    ) {
        #expect(winner.beats(loser))
    }

    @Test(arguments: AttackHeight.allCases)
    func `same height does not beat itself`(
        height: AttackHeight
    ) {
        #expect(!height.beats(height))
    }

    @Test
    func `high does not beat low`() {
        #expect(!AttackHeight.high.beats(.low))
    }

    @Test
    func `medium does not beat high`() {
        #expect(!AttackHeight.medium.beats(.high))
    }

    @Test
    func `low does not beat medium`() {
        #expect(!AttackHeight.low.beats(.medium))
    }
}

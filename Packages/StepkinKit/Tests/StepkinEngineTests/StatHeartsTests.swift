import Testing
@testable import StepkinEngine
import StepkinTestSupport

@Suite("StatHearts")
struct StatHeartsTests {

    @Test
    func `clamps to non-negative (capacity enforced by caller)`() {
        #expect(StatHearts(-1).value == 0)
        #expect(StatHearts(6).value == 6)
        #expect(StatHearts(3).value == 3)
    }

    @Test
    func `increment caps at the supplied max, decrement floors at zero`() {
        var hearts = StatHearts(3)
        hearts.increment(upTo: 4)
        #expect(hearts.value == 4)
        hearts.increment(upTo: 4)
        #expect(hearts.value == 4)

        var empty = StatHearts(0)
        empty.decrement()
        #expect(empty.value == 0)
    }
}

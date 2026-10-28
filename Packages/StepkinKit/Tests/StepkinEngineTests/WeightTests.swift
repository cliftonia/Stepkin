import Testing
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("Weight")
struct WeightTests {

    @Test
    func `clamps to 5-99 range`() {
        #expect(Weight(3).grams == 5)
        #expect(Weight(100).grams == 99)
        #expect(Weight(50).grams == 50)
    }
}

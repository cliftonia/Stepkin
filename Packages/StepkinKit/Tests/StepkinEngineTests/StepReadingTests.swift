import Testing
@testable import StepkinEngine

@Suite("StepReading")
struct StepReadingTests {

    @Test
    func `count is nil when steps are off`() {
        #expect(StepReading.off.count == nil)
    }

    @Test
    func `count is nil when no reading is available`() {
        #expect(StepReading.unavailable.count == nil)
    }

    @Test
    func `count carries the reading`() {
        #expect(StepReading.count(42).count == 42)
    }
}

import Testing
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

// DayPhase resolves the three explicit states from night + light:
// - not night            → .day
// - night, light off     → .night   (asleep, outside, dark)
// - night, light on      → .inside  (the room)
struct DayPhaseTests {

    @Test func `daytime is always day regardless of the light`() {
        #expect(DayPhase.resolve(isNight: false, lightsOn: true) == .day)
        #expect(DayPhase.resolve(isNight: false, lightsOn: false) == .day)
    }

    @Test func `night with the light off is night`() {
        #expect(DayPhase.resolve(isNight: true, lightsOn: false) == .night)
    }

    @Test func `night with the light on is inside`() {
        #expect(DayPhase.resolve(isNight: true, lightsOn: true) == .inside)
    }
}

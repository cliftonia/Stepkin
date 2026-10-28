import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("TimeCreditSimulator")
struct TimeCreditSimulatorTests {

    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let hour: TimeInterval = 3_600

    @Test
    func `an awake pet with Steps off earns an hour's credits and the anchor pays for them`() {
        let state = makeTestState(at: start)

        let result = TimeCreditSimulator.apply(to: state, at: start.addingTimeInterval(hour), steps: .off)

        #expect(result.lifetimeActiveSteps == TimeConstants.fallbackStepsPerWakingHour)
        #expect(result.timestamps.lastTimeCreditAt == start.addingTimeInterval(hour))
    }

    @Test
    func `less than one credit's time earns nothing and leaves the anchor`() {
        let state = makeTestState(at: start)

        let result = TimeCreditSimulator.apply(to: state, at: start.addingTimeInterval(7), steps: .off)

        #expect(result.lifetimeActiveSteps == 0)
        #expect(result.timestamps.lastTimeCreditAt == start)
    }

    @Test
    func `a sleeping pet earns nothing and owes nothing later`() {
        var state = makeTestState(at: start)
        state.isSleeping = true
        let wake = start.addingTimeInterval(8 * hour)

        let result = TimeCreditSimulator.apply(to: state, at: wake, steps: .off)

        #expect(result.lifetimeActiveSteps == 0)
        #expect(result.timestamps.lastTimeCreditAt == wake)
    }

    @Test
    func `a step count suppresses time credit and re-anchors`() {
        let state = makeTestState(at: start)
        let later = start.addingTimeInterval(hour)

        let result = TimeCreditSimulator.apply(to: state, at: later, steps: .count(3_000))

        #expect(result.lifetimeActiveSteps == 0)
        #expect(result.timestamps.lastTimeCreditAt == later)
    }

    @Test
    func `an unavailable reading earns nothing`() {
        let state = makeTestState(at: start)
        let later = start.addingTimeInterval(hour)

        let result = TimeCreditSimulator.apply(to: state, at: later, steps: .unavailable)

        #expect(result.lifetimeActiveSteps == 0)
        #expect(result.timestamps.lastTimeCreditAt == later)
    }

    @Test
    func `a dead pet earns nothing`() {
        var state = makeTestState(at: start)
        state.isDead = true

        let result = TimeCreditSimulator.apply(to: state, at: start.addingTimeInterval(hour), steps: .off)

        #expect(result.lifetimeActiveSteps == 0)
    }

    @Test
    func `a backward clock earns nothing and re-anchors`() {
        let state = makeTestState(at: start)
        let earlier = start.addingTimeInterval(-hour)

        let result = TimeCreditSimulator.apply(to: state, at: earlier, steps: .off)

        #expect(result.lifetimeActiveSteps == 0)
        #expect(result.timestamps.lastTimeCreditAt == earlier)
    }

    @Test
    func `the credit total cannot overflow`() {
        var state = makeTestState(at: start)
        state.lifetimeActiveSteps = Int.max - 10

        let result = TimeCreditSimulator.apply(to: state, at: start.addingTimeInterval(hour), steps: .off)

        #expect(result.lifetimeActiveSteps == Int.max)
    }

    @Test
    func `120 ticks of 30 seconds earn exactly one hour of credits`() {
        var state = makeTestState(at: start)

        for tick in 1...120 {
            state = TimeCreditSimulator.apply(
                to: state, at: start.addingTimeInterval(TimeInterval(tick) * 30), steps: .off
            )
        }

        #expect(state.lifetimeActiveSteps == TimeConstants.fallbackStepsPerWakingHour)
    }

    @Test
    func `Steps off parks the step accumulator so a returning count only baselines`() {
        var state = makeTestState(at: start)
        state.stepTrackedDay = start
        state.stepsCreditedToday = 3_000
        let dayLater = start.addingTimeInterval(24 * hour)

        let parked = TimeCreditSimulator.apply(to: state, at: dayLater, steps: .off)
        #expect(parked.stepTrackedDay == nil)
        #expect(parked.stepsCreditedToday == 0)

        // The off day was already paid in time credit, so the returning count is a baseline.
        let baselined = StepCrediting.creditLive(parked, todaySteps: 5_000, now: dayLater, calendar: .current)
        #expect(baselined.lifetimeActiveSteps == parked.lifetimeActiveSteps)
        #expect(baselined.stepsCreditedToday == 5_000)

        let later = StepCrediting.creditLive(baselined, todaySteps: 5_600, now: dayLater.addingTimeInterval(60), calendar: .current)
        #expect(later.lifetimeActiveSteps == parked.lifetimeActiveSteps + 600)
    }

    @Test
    func `Steps off parks the accumulator even while the pet sleeps`() {
        var state = makeTestState(at: start)
        state.isSleeping = true
        state.stepTrackedDay = start
        state.stepsCreditedToday = 800

        let parked = TimeCreditSimulator.apply(to: state, at: start.addingTimeInterval(hour), steps: .off)

        #expect(parked.stepTrackedDay == nil)
        #expect(parked.stepsCreditedToday == 0)
    }
}

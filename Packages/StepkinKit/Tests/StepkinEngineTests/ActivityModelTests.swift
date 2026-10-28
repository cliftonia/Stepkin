import Testing
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("ActivityModel")
struct ActivityModelTests {

    @Test func `factor clamps to 0...1`() {
        #expect(ActivityModel.factor(steps: 0) == 0)
        #expect(ActivityModel.factor(steps: -500) == 0)
        #expect(ActivityModel.factor(steps: ActivityModel.stepGoal) == 1)
        #expect(ActivityModel.factor(steps: ActivityModel.stepGoal * 5) == 1)
        #expect(abs(ActivityModel.factor(steps: ActivityModel.stepGoal / 2) - 0.5) < 0.0001)
    }

    @Test func `sedentary below the threshold`() {
        #expect(ActivityModel.isSedentary(steps: 0))
        #expect(ActivityModel.isSedentary(steps: ActivityModel.stepGoal) == false)
    }

    // Hunger drains faster the more you move.
    @Test func `hunger multiplier rises with steps`() {
        let still = ActivityModel.hungerRateMultiplier(steps: 0)
        let active = ActivityModel.hungerRateMultiplier(steps: ActivityModel.stepGoal)
        #expect(still < 1.0)
        #expect(active > 1.0)
        #expect(active > still)
    }

    // Strength drains faster the LESS you move.
    @Test func `strength multiplier falls with steps`() {
        let still = ActivityModel.strengthRateMultiplier(steps: 0)
        let active = ActivityModel.strengthRateMultiplier(steps: ActivityModel.stepGoal)
        #expect(still > 1.0)
        #expect(active < 1.0)
        #expect(still > active)
    }

}

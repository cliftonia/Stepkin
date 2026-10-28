import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("ConditioningSimulator")
struct ConditioningSimulatorTests {

    private static let base = Date(timeIntervalSince1970: 2_000_000)
    private static var interval: TimeInterval { TimeConstants.conditioningDecayInterval }

    private func conditioned(hp: Int, pow: Int) -> PetState {
        var state = makeTestState(species: .emberkin, at: Self.base)
        state.trainedHP = hp
        state.trainedPower = pow
        state.timestamps.lastTrainedAt = Self.base
        state.timestamps.lastBattledAt = Self.base
        return state
    }

    @Test
    func `loses one HP point per interval of no training`() {
        let state = conditioned(hp: 3, pow: 0)
        let later = Self.base.addingTimeInterval(Self.interval)
        let result = ConditioningSimulator.apply(to: state, at: later)
        #expect(result.trainedHP == 2)
    }

    @Test
    func `loses one POW point per interval of no battling`() {
        let state = conditioned(hp: 0, pow: 3)
        let later = Self.base.addingTimeInterval(Self.interval)
        let result = ConditioningSimulator.apply(to: state, at: later)
        #expect(result.trainedPower == 2)
    }

    @Test
    func `multiple intervals lose multiple points`() {
        let state = conditioned(hp: 3, pow: 3)
        let later = Self.base.addingTimeInterval(Self.interval * 2)
        let result = ConditioningSimulator.apply(to: state, at: later)
        #expect(result.trainedHP == 1)
        #expect(result.trainedPower == 1)
    }

    @Test
    func `decay floors at zero`() {
        let state = conditioned(hp: 2, pow: 1)
        let later = Self.base.addingTimeInterval(Self.interval * 10)
        let result = ConditioningSimulator.apply(to: state, at: later)
        #expect(result.trainedHP == 0)
        #expect(result.trainedPower == 0)
    }

    @Test
    func `no decay within the interval`() {
        let state = conditioned(hp: 3, pow: 3)
        let later = Self.base.addingTimeInterval(Self.interval - 1)
        let result = ConditioningSimulator.apply(to: state, at: later)
        #expect(result.trainedHP == 3)
        #expect(result.trainedPower == 3)
    }

    @Test
    func `a backward clock does not decay`() {
        let state = conditioned(hp: 3, pow: 3)
        let earlier = Self.base.addingTimeInterval(-Self.interval)
        let result = ConditioningSimulator.apply(to: state, at: earlier)
        #expect(result.trainedHP == 3)
        #expect(result.trainedPower == 3)
    }

    @Test
    func `recent activity resets the decay clock`() {
        var state = conditioned(hp: 3, pow: 3)
        // Trained / battled half an interval ago — not yet due.
        let recent = Self.base.addingTimeInterval(Self.interval / 2)
        state.timestamps.lastTrainedAt = recent
        state.timestamps.lastBattledAt = recent
        let now = Self.base.addingTimeInterval(Self.interval)
        let result = ConditioningSimulator.apply(to: state, at: now)
        #expect(result.trainedHP == 3)
        #expect(result.trainedPower == 3)
    }
}

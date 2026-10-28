import Testing
import Foundation
@testable import imon_Watch_App

@Suite("TrainAction")
struct TrainActionTests {

    @Test
    func `generated number is 1-9 and not 5`() {
        for _ in 0..<100 {
            let num = TrainAction.generateNumber()
            #expect(num >= 1 && num <= 9)
            #expect(num != 5)
        }
    }

    @Test
    func `high guess wins when number is greater than 5`() {
        let result = TrainAction.evaluateRound(
            number: 7, guess: .high
        )
        #expect(result.won)
    }

    @Test
    func `low guess wins when number is less than 5`() {
        let result = TrainAction.evaluateRound(
            number: 3, guess: .low
        )
        #expect(result.won)
    }

    @Test
    func `wrong guess loses`() {
        let result = TrainAction.evaluateRound(
            number: 8, guess: .low
        )
        #expect(!result.won)
    }

    @Test
    func `winning training increases strength and decreases weight`() {
        var state = makeTestState(strength: 2, weight: 30)
        state = TrainAction.applyResult(
            to: state, won: true, at: .now
        )
        #expect(state.strengthHearts.value == 3)
        #expect(state.weight.grams == 28)
        #expect(state.trainingCount == 1)
    }

    @Test
    func `winning training builds trained HP up to the cap`() {
        var state = makeTestState(species: .emberkin)
        state = TrainAction.applyResult(to: state, won: true, at: .now)
        #expect(state.trainedHP == 1)
        for _ in 0..<10 {
            state = TrainAction.applyResult(to: state, won: true, at: .now)
        }
        #expect(state.trainedHP == TimeConstants.maxConditioning)
    }

    @Test
    func `Dotkin never builds trained HP`() {
        var state = makeTestState(species: .dotkin)
        for _ in 0..<5 {
            state = TrainAction.applyResult(to: state, won: true, at: .now)
        }
        #expect(state.trainedHP == 0)
    }

    @Test
    func `a lost session grants no trained HP`() {
        var state = makeTestState(species: .emberkin)
        state = TrainAction.applyResult(to: state, won: false, at: .now)
        #expect(state.trainedHP == 0)
    }

    // MARK: - Session Outcome

    @Test(arguments: [
        ([true, true, true], true as Bool?),
        ([false, false, false], false as Bool?),
        ([true, false], nil),
        ([], nil),
        ([true, false, true, false, true], true),
        ([false, false, true, true], nil)
    ])
    func `session outcome follows the wins needed`(results: [Bool], expected: Bool?) {
        #expect(TrainAction.sessionOutcome(results: results) == expected)
    }

    @Test
    func `session is lost once losses exceed the allowance`() {
        let allowed = TimeConstants.trainRounds - TimeConstants.trainWinsNeeded
        #expect(TrainAction.sessionOutcome(results: Array(repeating: false, count: allowed)) == nil)
        #expect(TrainAction.sessionOutcome(results: Array(repeating: false, count: allowed + 1)) == false)
    }
}

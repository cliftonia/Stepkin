import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("CleanAction")
struct CleanActionTests {

    @Test
    func `clean removes all poop`() {
        var state = makeTestState()
        state.poopCount = 3
        state = CleanAction.apply(to: state, at: .now)
        #expect(state.poopCount == 0)
    }

    @Test
    func `cannot clean when no poop`() {
        var state = makeTestState()
        state.poopCount = 0
        #expect(!CleanAction.canClean(state))
    }

    @Test
    func `cleaning resets the poop timer to a fresh interval`() {
        let now = Date.now
        var state = makeTestState(at: now)
        state.poopCount = 2
        state.timestamps.lastPoopAt = now.addingTimeInterval(-7_000)   // nearly due
        let cleaned = CleanAction.apply(to: state, at: now)
        #expect(cleaned.poopCount == 0)
        #expect(cleaned.timestamps.lastPoopAt == now)
    }
}

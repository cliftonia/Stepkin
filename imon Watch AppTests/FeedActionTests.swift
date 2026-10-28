import Testing
import Foundation
@testable import imon_Watch_App

@Suite("FeedAction")
struct FeedActionTests {

    @Test
    func `meat increases hunger by 1 and weight by 1G`() {
        var state = makeTestState(hunger: 2, weight: 20)
        state = FeedAction.apply(to: state, food: .meat, at: .now)
        #expect(state.hungerHearts.value == 3)
        #expect(state.weight.grams == 21)
    }

    @Test
    func `vitamin increases strength by 1 and weight by 2G`() {
        var state = makeTestState(strength: 2, weight: 20)
        state = FeedAction.apply(to: state, food: .vitamin, at: .now)
        #expect(state.strengthHearts.value == 3)
        #expect(state.weight.grams == 22)
    }

    @Test
    func `meat is refused only when hunger is full`() {
        let full = makeTestState(hunger: PetSpecies.emberkin.maxHunger, strength: 1)
        #expect(FeedAction.isSated(full, food: .meat))
        #expect(!FeedAction.isSated(full, food: .vitamin))
    }

    @Test
    func `vitamin is refused only when strength is full`() {
        let full = makeTestState(hunger: 1, strength: PetSpecies.emberkin.maxStrength)
        #expect(FeedAction.isSated(full, food: .vitamin))
        #expect(!FeedAction.isSated(full, food: .meat))
    }

    @Test
    func `neither food is refused when both stats have room`() {
        let hungry = makeTestState(hunger: 1, strength: 1)
        #expect(!FeedAction.isSated(hungry, food: .meat))
        #expect(!FeedAction.isSated(hungry, food: .vitamin))
    }

    @Test
    func `cannot feed while sleeping`() {
        var state = makeTestState()
        state.isSleeping = true
        #expect(!FeedAction.canFeed(state))
    }

    @Test
    func `cannot feed when dead`() {
        var state = makeTestState()
        state.isDead = true
        #expect(!FeedAction.canFeed(state))
    }
}

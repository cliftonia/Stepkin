import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("CollapseTracker")
struct CollapseTrackerTests {

    @Test
    func `isLanguishing is true only when both stats are empty`() {
        #expect(makeTestState(hunger: 0, strength: 0).isLanguishing)
        #expect(!makeTestState(hunger: 1, strength: 0).isLanguishing)
        #expect(!makeTestState(hunger: 0, strength: 1).isLanguishing)
        #expect(!makeTestState(hunger: 2, strength: 2).isLanguishing)
    }

    @Test
    func `both stats empty starts the collapse countdown`() {
        let now = Date.now
        let state = makeTestState(hunger: 0, strength: 0, at: now)
        let result = CollapseTracker.apply(to: state, at: now)
        #expect(result.timestamps.collapsingAt == now)
    }

    /// The app may only notice hours after the fact — the countdown must date
    /// from the moment the pet actually ran out, not from the sighting.
    @Test
    func `the countdown starts when the stats emptied, not when the app looked`() {
        let now = Date.now
        let strengthWent = now.addingTimeInterval(-6 * 3_600)
        var state = makeTestState(hunger: 0, strength: 0, at: now)
        state.timestamps.hungerEmptiedAt = now.addingTimeInterval(-9 * 3_600)
        state.timestamps.strengthEmptiedAt = strengthWent

        let result = CollapseTracker.apply(to: state, at: now)

        // Languishing begins only once *both* are gone — the later moment.
        #expect(result.timestamps.collapsingAt == strengthWent)
    }

    @Test
    func `heart decay reports the moment the last heart was spent`() {
        let start = Date.now.addingTimeInterval(-10_000)
        var hearts = StatHearts(2)
        var anchor = start

        let emptiedAt = HeartDecay.deplete(
            &hearts, anchor: &anchor,
            baseInterval: 3_600, multiplier: 1, at: .now
        )

        #expect(hearts.isEmpty)
        #expect(emptiedAt == start.addingTimeInterval(2 * 3_600))
    }

    @Test
    func `heart decay reports nothing when the stat was already empty`() {
        var hearts = StatHearts(0)
        var anchor = Date.now.addingTimeInterval(-10_000)

        let emptiedAt = HeartDecay.deplete(
            &hearts, anchor: &anchor,
            baseInterval: 3_600, multiplier: 1, at: .now
        )

        #expect(emptiedAt == nil)
    }

    @Test
    func `an existing countdown is not reset while still languishing`() {
        let started = Date.now
        var state = makeTestState(hunger: 0, strength: 0, at: started)
        state.timestamps.collapsingAt = started
        let later = started.addingTimeInterval(600)
        let result = CollapseTracker.apply(to: state, at: later)
        #expect(result.timestamps.collapsingAt == started)
    }

    @Test
    func `recovering either stat clears the countdown`() {
        let now = Date.now
        var withHunger = makeTestState(hunger: 1, strength: 0, at: now)
        withHunger.timestamps.collapsingAt = now
        #expect(CollapseTracker.apply(to: withHunger, at: now).timestamps.collapsingAt == nil)

        var withStrength = makeTestState(hunger: 0, strength: 1, at: now)
        withStrength.timestamps.collapsingAt = now
        #expect(CollapseTracker.apply(to: withStrength, at: now).timestamps.collapsingAt == nil)
    }

    @Test
    func `a dead or egg pet is left untouched`() {
        let now = Date.now
        var dead = makeTestState(hunger: 0, strength: 0, at: now)
        dead.isDead = true
        #expect(CollapseTracker.apply(to: dead, at: now).timestamps.collapsingAt == nil)

        var egg = makeTestState(hunger: 0, strength: 0, at: now)
        egg.isEgg = true
        #expect(CollapseTracker.apply(to: egg, at: now).timestamps.collapsingAt == nil)
    }
}

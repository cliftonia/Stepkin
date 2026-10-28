import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("CareNotificationPlanner")
struct CareNotificationPlannerTests {

    /// A fixed calendar day at the given local hour, so day/night filtering is
    /// deterministic in any timezone (planner and test share `Calendar.current`).
    private func today(at hour: Int) -> Date {
        let calendar = Calendar.current
        let anchor = Date(timeIntervalSince1970: 1_700_000_000)
        let midnight = calendar.startOfDay(for: anchor)
        return calendar.date(byAdding: .hour, value: hour, to: midnight) ?? midnight
    }

    private func notification(
        _ plan: [CareNotification], _ kind: CareNotification.Kind
    ) -> CareNotification? {
        plan.first { $0.kind == kind }
    }

    @Test
    func `hunger fires when the remaining hearts empty`() {
        let now = today(at: 8)
        let state = makeTestState(species: .emberkin, hunger: 2, at: now)
        let plan = CareNotificationPlanner.plan(for: state, now: now, steps: nil)

        let hunger = notification(plan, .hunger)
        let expected = now.addingTimeInterval(2 * TimeConstants.hungerDepletionInterval)
        #expect(hunger?.fireDate == expected)
    }

    @Test
    func `strength fires when the remaining hearts empty`() {
        let now = today(at: 8)
        let state = makeTestState(species: .emberkin, strength: 3, at: now)
        let plan = CareNotificationPlanner.plan(for: state, now: now, steps: nil)

        let strength = notification(plan, .strength)
        let expected = now.addingTimeInterval(3 * TimeConstants.strengthDepletionInterval)
        #expect(strength?.fireDate == expected)
    }

    @Test
    func `mess is scheduled below the pile cap and not at it`() {
        let now = today(at: 8)
        var below = makeTestState(at: now)
        below.poopCount = TimeConstants.maxPoopPiles - 1
        #expect(notification(
            CareNotificationPlanner.plan(for: below, now: now, steps: nil), .mess
        ) != nil)

        var full = makeTestState(at: now)
        full.poopCount = TimeConstants.maxPoopPiles
        #expect(notification(
            CareNotificationPlanner.plan(for: full, now: now, steps: nil), .mess
        ) == nil)
    }

    @Test
    func `injury reminds at half the death window`() {
        let now = today(at: 8)
        var state = makeTestState(at: now)
        state.isInjured = true
        state.timestamps.injuredAt = now
        let plan = CareNotificationPlanner.plan(for: state, now: now, steps: nil)

        let injury = notification(plan, .injury)
        let expected = now.addingTimeInterval(TimeConstants.untreatedInjuryDeathTime / 2)
        #expect(injury?.fireDate == expected)
    }

    @Test
    func `a lazy afternoon earns an exercise nudge`() {
        let afternoon = today(at: 16)   // after 3pm
        let state = makeTestState(at: afternoon)

        // Lazy after 3pm → nudge; active → none; no step data → none.
        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: afternoon, steps: 1_000), .exercise
        ) != nil)
        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: afternoon, steps: 9_000), .exercise
        ) == nil)
        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: afternoon, steps: nil), .exercise
        ) == nil)

        // Before 3pm, no nudge even when lazy.
        let morning = today(at: 9)
        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: morning, steps: 1_000), .exercise
        ) == nil)
    }

    @Test
    func `an active wearer's hunger alert fires sooner than a still one`() {
        let now = today(at: 8)
        let state = makeTestState(species: .emberkin, hunger: 2, at: now)
        let active = notification(
            CareNotificationPlanner.plan(for: state, now: now, steps: 9_000), .hunger
        )
        let still = notification(
            CareNotificationPlanner.plan(for: state, now: now, steps: nil), .hunger
        )
        #expect((active?.fireDate ?? .distantFuture) < (still?.fireDate ?? .distantPast))
    }

    @Test
    func `a collapsing pet is warned before it fades`() {
        // The fading warning is exempt from the night drop, so it fires whenever due.
        let now = today(at: 18)   // 6pm — already "night" for the drop filter
        var state = makeTestState(hunger: 0, strength: 0, at: now)
        state.timestamps.collapsingAt = now

        let fading = notification(
            CareNotificationPlanner.plan(for: state, now: now, steps: nil), .fading
        )
        let expected = now.addingTimeInterval(
            TimeConstants.collapseDeathTime - TimeConstants.nearingDeathLead
        )
        #expect(fading?.fireDate == expected)
    }

    /// A need that survives the night is held until the owner wakes rather
    /// than dropped — the pet is just as hungry at 6am.
    @Test
    func `a night-bound hunger call is held until morning`() throws {
        // One heart left at 5pm empties after dark.
        let now = today(at: 17)
        let state = makeTestState(species: .emberkin, hunger: 1, at: now)

        let hunger = try #require(
            notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .hunger)
        )

        #expect(Calendar.current.component(.hour, from: hunger.fireDate)
            == TimeConstants.nightEndHour)
        #expect(hunger.fireDate > now)
    }

    /// A sleeping pet's clocks are frozen and restart at dawn, so its hunger
    /// call is projected from the wake hour with every heart intact.
    @Test
    func `a sleeping pet's hunger call counts from dawn`() throws {
        let bedtime = today(at: 21)
        var state = makeTestState(species: .emberkin, hunger: 4, at: bedtime)
        state.isSleeping = true
        let now = today(at: 23)

        let hunger = try #require(
            notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .hunger)
        )

        let dawn = today(at: TimeConstants.nightEndHour + 24)
        #expect(hunger.fireDate == dawn.addingTimeInterval(4 * TimeConstants.hungerDepletionInterval))
    }

    /// Decay that would straddle bedtime pauses at the settle and resumes at
    /// dawn — the reminder lands in the morning, not at a night-held 6am sharp.
    @Test
    func `an evening projection pauses at bedtime and resumes at dawn`() throws {
        let now = today(at: 19)
        let state = makeTestState(species: .emberkin, hunger: 2, at: now)

        let hunger = try #require(
            notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .hunger)
        )

        // 19:00 → 21:02 spends 122 of the 140 minutes; the last 18 run from 06:00.
        let dawn = today(at: TimeConstants.nightEndHour + 24)
        #expect(hunger.fireDate == dawn.addingTimeInterval(18 * 60))
    }

    /// The exercise nudge is about a step total the owner can no longer
    /// influence by morning, so it is dropped rather than held.
    @Test
    func `a night-bound exercise nudge is dropped, not deferred`() {
        let state = makeTestState(at: today(at: 7))
        let afterDark = today(at: 18)

        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: afterDark, steps: 0), .exercise
        ) == nil)

        // Daytime keeps its own hour.
        let daytime = today(at: 16)
        let kept = notification(
            CareNotificationPlanner.plan(for: state, now: daytime, steps: 0), .exercise
        )
        #expect(kept?.fireDate == daytime.addingTimeInterval(TimeConstants.exerciseNudgeLead))
    }

    /// An injury reminder held past the untreated-injury death window would
    /// arrive after the grave, so it is dropped instead.
    @Test
    func `an injury reminder is dropped when morning falls past the death window`() {
        let now = today(at: 16)
        var state = makeTestState(at: now)
        state.isInjured = true
        state.timestamps.injuredAt = now   // dies at 22:00; reminder due 19:00

        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: now, steps: nil), .injury
        ) == nil)
    }

    @Test
    func `past events are dropped`() {
        let base = today(at: 8)
        let state = makeTestState(at: base)
        let later = base.addingTimeInterval(100_000)  // long after every anchor
        #expect(CareNotificationPlanner.plan(for: state, now: later, steps: nil).isEmpty)
    }

    @Test
    func `dead or egg pets get no notifications`() {
        let now = today(at: 8)
        var dead = makeTestState(at: now)
        dead.isDead = true
        #expect(CareNotificationPlanner.plan(for: dead, now: now, steps: 0).isEmpty)

        var egg = makeTestState(at: now)
        egg.isEgg = true
        #expect(CareNotificationPlanner.plan(for: egg, now: now, steps: 0).isEmpty)
    }

    @Test
    func `reminders carry the pet's species for the app to word and illustrate`() {
        let now = today(at: 8)
        let state = makeTestState(species: .emberkin, hunger: 1, at: now)
        let plan = CareNotificationPlanner.plan(for: state, now: now, steps: nil)

        #expect(notification(plan, .hunger)?.species == .emberkin)
    }

    @Test
    func `each notification carries a stable per-kind id`() {
        // Stable ids are the dedup contract — a re-plan must replace the pending
        // reminder of the same kind, not stack a second one.
        let now = today(at: 8)
        let plan = CareNotificationPlanner.plan(for: makeTestState(at: now), now: now, steps: nil)
        for note in plan {
            #expect(note.id == note.kind.rawValue)
        }
    }
}

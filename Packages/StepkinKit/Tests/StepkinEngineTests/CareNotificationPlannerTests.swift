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
    func `a lazy day earns one exercise nudge at ten past three`() {
        let morning = today(at: 9)
        let state = makeTestState(at: morning)
        let due = today(at: TimeConstants.exerciseHour).addingTimeInterval(TimeConstants.exerciseNudgeLead)

        // Lazy → nudge at the fixed time; active → none; no step data → none.
        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: morning, steps: 1_000), .exercise
        )?.fireDate == due)
        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: morning, steps: 9_000), .exercise
        ) == nil)
        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: morning, steps: nil), .exercise
        ) == nil)
    }

    /// The nudge has one fixed moment a day, so a plan made after it (every
    /// later visit and hourly wake) cannot schedule another.
    @Test
    func `a plan made after the nudge time does not nudge again`() {
        let state = makeTestState(at: today(at: 7))

        for hour in [16, 18, 22] {
            #expect(notification(
                CareNotificationPlanner.plan(for: state, now: today(at: hour), steps: 0), .exercise
            ) == nil)
        }
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
        let now = today(at: 18)
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

    /// The pet is awake and draining until bedtime, so an evening call is
    /// made in the evening, while the owner can still answer it.
    @Test
    func `an evening hunger call fires in the evening`() throws {
        // One heart left at 5pm empties at ten past six.
        let now = today(at: 17)
        let state = makeTestState(species: .emberkin, hunger: 1, at: now)

        let hunger = try #require(
            notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .hunger)
        )

        #expect(hunger.fireDate == now.addingTimeInterval(TimeConstants.hungerDepletionInterval))
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

    /// The injury clock does not stop for the night, so its reminder is never
    /// held or dropped: silence here costs the pet its life.
    @Test(arguments: [16, 22])
    func `an injury reminder fires when due, evening or night`(hour: Int) {
        let now = today(at: hour)
        var state = makeTestState(at: now)
        state.isInjured = true
        state.timestamps.injuredAt = now

        #expect(notification(
            CareNotificationPlanner.plan(for: state, now: now, steps: nil), .injury
        )?.fireDate == now.addingTimeInterval(TimeConstants.untreatedInjuryDeathTime / 2))
    }

    /// A pet kept up by a light the player switched on does not pause at
    /// bedtime, so neither may its hunger call.
    @Test
    func `a pet kept up by the light is called for when it empties, not at dawn`() throws {
        let now = today(at: 22)
        var state = makeTestState(species: .emberkin, hunger: 2, at: now)
        state.wasNight = true
        state.lightsOn = true

        let hunger = try #require(
            notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .hunger)
        )

        #expect(hunger.fireDate == now.addingTimeInterval(2 * TimeConstants.hungerDepletionInterval))
    }

    /// A catch-up can find an injury already hours old. Its half-way reminder
    /// is then behind it, and the pet must not count down to death in silence.
    @Test
    func `an injury found past its half-way mark still gets a last call an hour before death`() {
        let now = today(at: 13)
        var state = makeTestState(at: now)
        state.isInjured = true
        state.timestamps.injuredAt = now.addingTimeInterval(-4 * 3_600)

        let injury = notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .injury)

        #expect(injury?.fireDate == now.addingTimeInterval(3_600))
    }

    @Test
    func `an injury found in its last hour is called at once`() {
        let now = today(at: 13)
        var state = makeTestState(at: now)
        state.isInjured = true
        state.timestamps.injuredAt = now.addingTimeInterval(-5.5 * 3_600)

        let injury = notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .injury)

        #expect(injury?.fireDate == now.addingTimeInterval(60))
    }

    /// The mess that will injure can be foreseen, and with no wake in between
    /// nothing replans: the injury's reminder has to be laid down in advance.
    @Test
    func `a mess heading for injury has its injury reminder planned ahead`() {
        let now = today(at: 8)
        var state = makeTestState(at: now)
        state.poopCount = TimeConstants.maxPoopPiles - 2
        state.timestamps.lastPoopAt = now.addingTimeInterval(-3_600)

        let injury = notification(CareNotificationPlanner.plan(for: state, now: now, steps: nil), .injury)

        // Piles at 09:00 and 11:00; the fourth injures, and the reminder is half-way to death.
        let injuredAt = now.addingTimeInterval(3 * 3_600)
        #expect(injury?.fireDate == injuredAt.addingTimeInterval(TimeConstants.untreatedInjuryDeathTime / 2))
    }

    @Test
    func `a sedentary day brings the foreseen injury a pile sooner`() {
        let now = today(at: 8)
        var state = makeTestState(at: now)
        state.poopCount = TimeConstants.maxPoopPiles - 2
        state.timestamps.lastPoopAt = now.addingTimeInterval(-3_600)

        let injury = notification(CareNotificationPlanner.plan(for: state, now: now, steps: 0), .injury)

        let injuredAt = now.addingTimeInterval(3_600)
        #expect(injury?.fireDate == injuredAt.addingTimeInterval(TimeConstants.untreatedInjuryDeathTime / 2))
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

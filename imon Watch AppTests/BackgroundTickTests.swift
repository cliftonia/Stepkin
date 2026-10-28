import Testing
import Foundation
@testable import imon_Watch_App

@Suite("BackgroundTick")
struct BackgroundTickTests {

    // MARK: - Capture helpers

    private final class StoreBox: @unchecked Sendable {
        var state: PetState?
        var saveCount = 0
    }

    private final class NoteCapture: @unchecked Sendable {
        var plan: [CareNotification]?
        var evolvedTo: PetSpecies?
        var cancelledAll = false
    }

    private final class RefreshCapture: @unchecked Sendable {
        var date: Date?
    }

    private func makeStore(_ box: StoreBox) -> PetStateStore {
        PetStateStore(
            save: { box.state = $0; box.saveCount += 1 },
            load: { box.state },
            delete: { box.state = nil }
        )
    }

    // MARK: - Tests

    @Test
    func `advancing a stale state depletes hunger and writes it back`() {
        let base = today(at: 9)
        let box = StoreBox()
        box.state = makeTestState(species: .emberkin, hunger: 4, at: base)
        let now = base.addingTimeInterval(3 * TimeConstants.hungerDepletionInterval)

        BackgroundTick.perform(
            store: makeStore(box), notifications: capturing(NoteCapture()),
            refresh: capturing(RefreshCapture()), complications: ComplicationReloader(reload: {}), notificationsEnabled: true, steps: nil, now: now
        )

        #expect(box.saveCount == 1)
        #expect(box.state?.hungerHearts.value == 1)
        #expect(box.state?.timestamps.lastAdvancedAt == now)
    }

    @Test
    func `the notification scheduler receives the plan for the advanced state`() {
        let base = today(at: 9)
        let box = StoreBox()
        box.state = makeTestState(species: .emberkin, hunger: 2, at: base)
        let now = base.addingTimeInterval(60)
        let note = NoteCapture()

        BackgroundTick.perform(
            store: makeStore(box), notifications: capturing(note),
            refresh: capturing(RefreshCapture()), complications: ComplicationReloader(reload: {}), notificationsEnabled: true, steps: nil, now: now
        )

        let expected = CareNotificationPlanner.plan(
            for: box.state ?? makeTestState(), now: now, steps: nil
        )
        #expect(note.plan == expected)
    }

    @Test
    func `the next refresh is requested an interval ahead`() {
        let base = today(at: 9)
        let box = StoreBox()
        box.state = makeTestState(at: base)
        let now = base.addingTimeInterval(60)
        let refresh = RefreshCapture()

        BackgroundTick.perform(
            store: makeStore(box), notifications: capturing(NoteCapture()),
            refresh: capturing(refresh), complications: ComplicationReloader(reload: {}), notificationsEnabled: true, steps: nil, now: now
        )

        #expect(refresh.date == now.addingTimeInterval(TimeConstants.backgroundRefreshInterval))
    }

    @Test
    func `no saved pet is a no-op`() {
        let box = StoreBox()  // empty store
        let note = NoteCapture()
        let refresh = RefreshCapture()

        BackgroundTick.perform(
            store: makeStore(box), notifications: capturing(note),
            refresh: capturing(refresh), complications: ComplicationReloader(reload: {}), notificationsEnabled: true, steps: nil, now: today(at: 9)
        )

        #expect(box.saveCount == 0)
        #expect(note.plan == nil)
        #expect(refresh.date == nil)
    }

    @Test
    func `a load failure still re-arms the next wake`() {
        struct LoadError: Error {}
        let store = PetStateStore(save: { _ in }, load: { throw LoadError() }, delete: {})
        let refresh = RefreshCapture()
        let now = today(at: 9)

        BackgroundTick.perform(
            store: store, notifications: capturing(NoteCapture()),
            refresh: capturing(refresh), complications: ComplicationReloader(reload: {}), notificationsEnabled: true, steps: nil, now: now
        )

        // A transient decode failure must not kill the refresh chain.
        #expect(refresh.date == now.addingTimeInterval(TimeConstants.backgroundRefreshInterval))
    }

    @Test
    func `a pet that reaches its step gate evolves and is announced`() {
        let now = today(at: 9)
        let box = StoreBox()
        var pet = makeTestState(species: .dotkin, at: now)
        pet.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve   // ready to grow
        box.state = pet
        let note = NoteCapture()

        BackgroundTick.perform(
            store: makeStore(box), notifications: capturing(note),
            refresh: capturing(RefreshCapture()), complications: ComplicationReloader(reload: {}), notificationsEnabled: true, steps: nil, now: now
        )

        #expect(box.state?.species == .hopkin)
        #expect(note.evolvedTo == .hopkin)
    }

    @Test
    func `an injury that emerges during the advance is reminded`() {
        let base = today(at: 9)
        let box = StoreBox()
        var seeded = makeTestState(species: .emberkin, at: base)
        seeded.poopCount = TimeConstants.maxPoopPiles  // injures on the next advance
        box.state = seeded
        let now = base.addingTimeInterval(60)
        let note = NoteCapture()

        BackgroundTick.perform(
            store: makeStore(box), notifications: capturing(note),
            refresh: capturing(RefreshCapture()), complications: ComplicationReloader(reload: {}), notificationsEnabled: true, steps: nil, now: now
        )

        #expect(box.state?.isInjured == true)
        #expect(note.plan?.contains { $0.kind == .injury } == true)
    }

    @Test
    func `disabled notifications skip the announce and clear pending reminders`() {
        let now = today(at: 9)
        let box = StoreBox()
        var pet = makeTestState(species: .dotkin, at: now)
        pet.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve   // ready to grow
        box.state = pet
        let note = NoteCapture()

        BackgroundTick.perform(
            store: makeStore(box), notifications: capturing(note),
            refresh: capturing(RefreshCapture()), complications: ComplicationReloader(reload: {}), notificationsEnabled: false, steps: nil, now: now
        )

        // The pet still advances, evolves, and is saved — only the user-facing
        // notifications are suppressed, and anything pending is cleared.
        #expect(box.state?.species == .hopkin)
        #expect(box.saveCount == 1)
        #expect(note.evolvedTo == nil)
        #expect(note.plan == nil)
        #expect(note.cancelledAll)
    }

    // MARK: - Scheduler builders

    private func capturing(_ note: NoteCapture) -> NotificationScheduler {
        NotificationScheduler(
            schedule: { note.plan = $0 },
            notify: { _, _, species in note.evolvedTo = species },
            cancelAll: { note.cancelledAll = true }, requestAuthorization: { true }
        )
    }

    private func capturing(_ refresh: RefreshCapture) -> BackgroundRefreshScheduler {
        BackgroundRefreshScheduler(schedule: { refresh.date = $0 })
    }
}

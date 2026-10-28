import Testing
import Foundation
@testable import imon_Watch_App

@Suite("OfflineSession")
struct OfflineSessionTests {

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

    private func makeDependencies(
        store: PetStateStore,
        note: NoteCapture = NoteCapture(),
        refresh: RefreshCapture? = RefreshCapture(),
        notificationsEnabled: Bool = true
    ) -> OfflineSession.Dependencies {
        OfflineSession.Dependencies(
            store: store,
            finalSteps: { _ in nil },
            witnesses: CareHandoff.Witnesses(
                notifications: NotificationScheduler(
                    schedule: { note.plan = $0 },
                    notify: { _, _, species in note.evolvedTo = species },
                    cancelAll: { note.cancelledAll = true }, requestAuthorization: { true }
                ),
                complications: ComplicationReloader(reload: {})
            ),
            refresh: refresh.map { capture in BackgroundRefreshScheduler(schedule: { capture.date = $0 }) },
            notificationsEnabled: notificationsEnabled
        )
    }

    private func run(
        _ dependencies: OfflineSession.Dependencies,
        action: PetAction = .tick,
        steps: StepReading = .unavailable,
        now: Date
    ) async -> PetActionOutcome {
        await OfflineSession.run(action, readings: (night: nil, steps: steps), dependencies: dependencies, now: now)
    }

    // MARK: - Tick

    @Test
    func `a tick advances the saved pet, writes it back and hands care off`() async {
        let base = today(at: 9)
        let box = StoreBox()
        box.state = makeTestState(species: .emberkin, hunger: 4, at: base)
        let now = base.addingTimeInterval(3 * TimeConstants.hungerDepletionInterval)
        let note = NoteCapture()

        let outcome = await run(makeDependencies(store: makeStore(box), note: note), now: now)

        #expect(outcome == .done)
        #expect(box.saveCount == 1)
        #expect(box.state?.hungerHearts.value == 1)
        #expect(box.state?.timestamps.lastAdvancedAt == now)
        let expected = CareNotificationPlanner.plan(for: box.state ?? makeTestState(), now: now, steps: nil)
        #expect(note.plan == expected)
    }

    @Test
    func `the next refresh is requested an interval ahead`() async {
        let base = today(at: 9)
        let box = StoreBox()
        box.state = makeTestState(at: base)
        let now = base.addingTimeInterval(60)
        let refresh = RefreshCapture()

        _ = await run(makeDependencies(store: makeStore(box), refresh: refresh), now: now)

        #expect(refresh.date == now.addingTimeInterval(TimeConstants.backgroundRefreshInterval))
    }

    @Test
    func `no saved pet returns noPet and touches nothing`() async {
        let box = StoreBox()
        let note = NoteCapture()
        let refresh = RefreshCapture()

        let outcome = await run(makeDependencies(store: makeStore(box), note: note, refresh: refresh), now: today(at: 9))

        #expect(outcome == .noPet)
        #expect(box.saveCount == 0)
        #expect(note.plan == nil)
        #expect(refresh.date == nil)
    }

    @Test
    func `a load failure still re-arms the next wake and returns noPet`() async {
        struct LoadError: Error {}
        let store = PetStateStore(save: { _ in }, load: { throw LoadError() }, delete: {})
        let refresh = RefreshCapture()
        let now = today(at: 9)

        let outcome = await run(makeDependencies(store: store, refresh: refresh), now: now)

        // A transient decode failure must not kill the refresh chain.
        #expect(outcome == .noPet)
        #expect(refresh.date == now.addingTimeInterval(TimeConstants.backgroundRefreshInterval))
    }

    @Test
    func `a pet that reaches its step gate evolves and is announced`() async {
        let now = today(at: 9)
        let box = StoreBox()
        var pet = makeTestState(species: .dotkin, at: now)
        pet.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve   // ready to grow
        box.state = pet
        let note = NoteCapture()

        _ = await run(makeDependencies(store: makeStore(box), note: note), now: now)

        #expect(box.state?.species == .hopkin)
        #expect(note.evolvedTo == .hopkin)
    }

    @Test
    func `disabled notifications skip the announce and clear pending reminders`() async {
        let now = today(at: 9)
        let box = StoreBox()
        var pet = makeTestState(species: .dotkin, at: now)
        pet.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve   // ready to grow
        box.state = pet
        let note = NoteCapture()

        _ = await run(makeDependencies(store: makeStore(box), note: note, notificationsEnabled: false), now: now)

        // The pet still advances, evolves, and is saved; only the user-facing
        // notifications are suppressed, and anything pending is cleared.
        #expect(box.state?.species == .hopkin)
        #expect(box.saveCount == 1)
        #expect(note.evolvedTo == nil)
        #expect(note.plan == nil)
        #expect(note.cancelledAll)
    }

    @Test
    func `the live step count is credited before saving`() async {
        let now = today(at: 9)
        let box = StoreBox()
        var pet = makeTestState(at: now)
        pet.stepTrackedDay = now
        pet.stepsCreditedToday = 1_000
        pet.lifetimeActiveSteps = 1_000
        box.state = pet

        _ = await run(makeDependencies(store: makeStore(box)), steps: .count(1_600), now: now)

        #expect(box.state?.lifetimeActiveSteps == 1_600)
        #expect(box.state?.stepsCreditedToday == 1_600)
    }

    // MARK: - Feed

    @Test
    func `feeding meat is applied and saved`() async {
        let now = today(at: 9)
        let box = StoreBox()
        box.state = makeTestState(species: .emberkin, hunger: 1, at: now)

        let outcome = await run(makeDependencies(store: makeStore(box)), action: .feed(.meat), now: now)

        #expect(outcome == .done)
        #expect(box.saveCount == 1)
        #expect(box.state?.hungerHearts.value == 2)
        #expect(box.state?.weight != Weight(20))
    }

    @Test
    func `feeding a sated pet is refused and nothing is fed`() async {
        let now = today(at: 9)
        let box = StoreBox()
        let full = makeTestState(species: .emberkin, hunger: PetSpecies.emberkin.maxHunger, at: now)
        box.state = full

        let outcome = await run(makeDependencies(store: makeStore(box)), action: .feed(.meat), now: now)

        #expect(outcome == .refused(reason: FeedRefusal.reason(for: full, food: .meat) ?? ""))
        #expect(box.state?.weight == full.weight)
    }

    @Test
    func `feeding a pet that cannot eat is refused`() async {
        let now = today(at: 9)
        let box = StoreBox()
        var gone = makeTestState(species: .emberkin, hunger: 1, at: now)
        gone.isDead = true
        box.state = gone

        let outcome = await run(makeDependencies(store: makeStore(box)), action: .feed(.vitamin), now: now)

        #expect(outcome == .refused(reason: FeedRefusal.cannotEat))
        #expect(box.state?.hungerHearts.value == 1)
    }
}

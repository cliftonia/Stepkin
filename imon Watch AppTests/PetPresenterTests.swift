import Testing
import Foundation
@testable import imon_Watch_App

@Suite("PetPresenter orchestration")
@MainActor
struct PetPresenterTests {

    /// Captures every state the presenter writes back through the store.
    private final class SaveBox: @unchecked Sendable {
        var saved: [PetState] = []
    }

    /// Captures what the presenter hands to the notification scheduler.
    private final class SchedulerBox: @unchecked Sendable {
        var scheduled: [CareNotification]?
        var cancelCount = 0
    }

    private final class CountBox: @unchecked Sendable {
        var count = 0
    }

    private func makePresenter(
        _ state: PetState,
        _ box: SaveBox,
        onDeath: @escaping () -> Void = {},
        scheduler: SchedulerBox = SchedulerBox()
    ) -> PetPresenter {
        makePetPresenter(
            state: state,
            store: PetStateStore(save: { box.saved.append($0) }, load: { nil }, delete: {}),
            scheduler: NotificationScheduler(
                schedule: { scheduler.scheduled = $0 },
                notify: { _, _, _ in },
                cancelAll: { scheduler.cancelCount += 1 },
                requestAuthorization: { true }
            ),
            onDeath: onDeath
        )
    }

    @Test
    func `stopping the game loop mid-walk leaves no wander timer armed and resets the offset`() {
        let presenter = makePresenter(makeTestState(), SaveBox())
        presenter.startGameLoop()
        for _ in 0..<50 where !presenter.wander.isWalking {
            presenter.wander.tryStartWalking()
        }
        #expect(presenter.wander.isWalking)

        presenter.stopGameLoop()

        #expect(!presenter.wander.isWalking)
        #expect(!presenter.wander.isScheduled)
        #expect(presenter.wander.offsetX == 8)
        #expect(presenter.spriteAnimator.isPlaying == false)
    }

    @Test
    func `applying a battle win advances state and persists it`() {
        let box = SaveBox()
        var state = makeTestState(species: .emberkin)
        state.battleWins = 2
        let presenter = makePresenter(state, box)

        presenter.applyBattleResult(.win)

        #expect(presenter.state.battleWins == 3)
        #expect(box.saved.last?.battleWins == 3)
    }

    @Test
    func `applying a training win builds strength and persists it`() {
        let box = SaveBox()
        let presenter = makePresenter(makeTestState(species: .emberkin, strength: 1), box)

        presenter.applyTrainingResult(won: true)

        let strength = presenter.state.strengthHearts.value
        #expect(strength > 1)
        #expect(box.saved.last?.strengthHearts.value == strength)
    }

    // MARK: - Death Edge

    @Test
    func `death during play fires onDeath exactly once and persists the grave`() {
        let box = SaveBox()
        let deaths = CountBox()
        var state = makeTestState()
        state.injuryCount = TimeConstants.maxInjuriesBeforeDeath
        let presenter = makePresenter(state, box, onDeath: { deaths.count += 1 })

        presenter.environmentDidChange()

        #expect(presenter.state.isDead)
        #expect(deaths.count == 1)
        #expect(box.saved.last?.isDead == true)

        // Already dead — the edge must not re-fire on the next advance.
        presenter.environmentDidChange()
        #expect(deaths.count == 1)
    }

    // MARK: - Step Settle Across the Fetch

    /// Holds a `finalSteps` fetch suspended until the test opens it.
    private final class FetchGate {
        private(set) var entered = false
        private var opened = false
        private var continuation: CheckedContinuation<Void, Never>?

        func wait() async {
            entered = true
            guard !opened else { return }
            await withCheckedContinuation { continuation = $0 }
        }

        func open() {
            opened = true
            continuation?.resume()
            continuation = nil
        }
    }

    /// A presenter whose live count is `steps` and whose missed day settles at
    /// `total` once `gate` opens; the pet last tracked yesterday at 500 steps.
    private func makeSettlingPresenter(gate: FetchGate, total: Int) -> PetPresenter {
        var state = makeTestState(species: .emberkin)
        state.stepTrackedDay = Date.now.addingTimeInterval(-86_400)
        state.stepsCreditedToday = 500
        state.lifetimeActiveSteps = 500
        state.evolutionGoalPenalty = 1_234
        return PetPresenter(
            state: state,
            store: PetStateStore(save: { _ in }, load: { nil }, delete: {}),
            currentSteps: { .count(10) },
            finalSteps: { _ in
                await gate.wait()
                return total
            },
            notificationScheduler: NotificationScheduler(
                schedule: { _ in }, notify: { _, _, _ in }, cancelAll: {}, requestAuthorization: { true }
            ),
            complicationReloader: ComplicationReloader(reload: {})
        )
    }

    /// An evolution accepted while HealthKit is answering resets the goal
    /// penalty; the settle must add only its own missed-day charge on top.
    @Test
    func `an evolution during the settle keeps its penalty reset`() async {
        let gate = FetchGate()
        let presenter = makeSettlingPresenter(gate: gate, total: 900)
        let charge = presenter.state.species.stage.lazyDayPenalty

        presenter.creditSteps()
        #expect(await waitUntil { gate.entered })
        presenter.state = EvolutionEngine.evolve(presenter.state, to: .rexkin, at: .now)
        gate.open()
        await presenter.dayRecoveryTask?.value

        #expect(presenter.state.species == .rexkin)
        #expect(presenter.state.evolutionGoalPenalty == charge)
        // 500 credited + a 400 tail + today's 10.
        #expect(presenter.state.lifetimeActiveSteps == 910)
        #expect(presenter.state.stepsCreditedToday == 10)
    }

    /// When the live accumulator moved to another day meanwhile, the settle is
    /// stale and is dropped rather than written over it.
    @Test
    func `a settle is dropped when the tracked day changed meanwhile`() async {
        let gate = FetchGate()
        let presenter = makeSettlingPresenter(gate: gate, total: 3_000)

        presenter.creditSteps()
        #expect(await waitUntil { gate.entered })
        presenter.state.stepTrackedDay = Date.now.addingTimeInterval(86_400 * 3)
        presenter.state.stepsCreditedToday = 42
        gate.open()
        await presenter.dayRecoveryTask?.value

        #expect(presenter.state.stepsCreditedToday == 42)
        #expect(presenter.state.lifetimeActiveSteps == 500)
        #expect(presenter.state.evolutionGoalPenalty == 1_234)
    }

    // MARK: - Scene Phase

    /// A save written while the presenter was suspended (a background wake or
    /// an intent) is newer than the in-memory pet, so activation adopts it.
    @Test
    func `activation adopts a newer save`() {
        var saved = makeTestState(at: .now.addingTimeInterval(-60))
        saved.battleWins = 7
        let presenter = makePetPresenter(
            state: makeTestState(at: .now.addingTimeInterval(-3_600)),
            store: PetStateStore(save: { _ in }, load: { [saved] in saved }, delete: {})
        )

        presenter.handleScenePhase(isActive: true, notificationsEnabled: false)
        presenter.stopGameLoop()

        #expect(presenter.state.battleWins == 7)
    }

    /// An older save is the presenter's own stale write: the live pet wins.
    @Test
    func `activation keeps the live pet over an older save`() {
        var saved = makeTestState(at: .now.addingTimeInterval(-7_200))
        saved.battleWins = 7
        let presenter = makePetPresenter(
            state: makeTestState(at: .now.addingTimeInterval(-3_600)),
            store: PetStateStore(save: { _ in }, load: { [saved] in saved }, delete: {})
        )

        presenter.handleScenePhase(isActive: true, notificationsEnabled: false)
        presenter.stopGameLoop()

        #expect(presenter.state.battleWins == 0)
    }

    @Test
    func `backgrounding with notifications on schedules care reminders`() {
        let scheduler = SchedulerBox()
        // A fading pet — the planner drops reminders that land in the night
        // window, so a healthy pet's list is empty when the suite runs in the
        // evening; the fading warning is the one kind that always survives.
        var state = makeTestState()
        state.timestamps.collapsingAt = .now
        let presenter = makePresenter(state, SaveBox(), scheduler: scheduler)

        presenter.handleScenePhase(isActive: false, notificationsEnabled: true)

        #expect(scheduler.scheduled?.isEmpty == false)
        #expect(scheduler.cancelCount == 0)
    }

    @Test
    func `backgrounding with notifications off cancels pending reminders`() {
        let scheduler = SchedulerBox()
        let presenter = makePresenter(makeTestState(), SaveBox(), scheduler: scheduler)

        presenter.handleScenePhase(isActive: false, notificationsEnabled: false)

        #expect(scheduler.scheduled == nil)
        #expect(scheduler.cancelCount == 1)
    }

    @Test
    func `foregrounding catches the simulation up without touching reminders`() {
        let box = SaveBox()
        let scheduler = SchedulerBox()
        let presenter = makePresenter(makeTestState(), box, scheduler: scheduler)

        presenter.handleScenePhase(isActive: true, notificationsEnabled: true)

        #expect(box.saved.isEmpty == false)
        #expect(scheduler.scheduled == nil)
        #expect(scheduler.cancelCount == 0)
        presenter.stopGameLoop()
    }

    // MARK: - Menu Ring

    @Test(arguments: [
        (PetViewModel.MenuAction.stats, PetViewModel.MenuAction.feed),
        (.heal, .settings),
        (.settings, .stats)
    ])
    func `the next-menu ring steps forward and wraps around`(
        from: PetViewModel.MenuAction, expected: PetViewModel.MenuAction
    ) {
        let presenter = makePresenter(makeTestState(), SaveBox())
        presenter.viewModel.menuSelection = from

        presenter.selectNextMenu()

        #expect(presenter.viewModel.menuSelection == expected)
    }

    @Test(arguments: [
        (PetViewModel.MenuAction.stats, PetViewModel.MenuAction.settings),
        (.feed, .stats)
    ])
    func `the previous-menu ring steps back and wraps around`(
        from: PetViewModel.MenuAction, expected: PetViewModel.MenuAction
    ) {
        let presenter = makePresenter(makeTestState(), SaveBox())
        presenter.viewModel.menuSelection = from

        presenter.selectPreviousMenu()

        #expect(presenter.viewModel.menuSelection == expected)
    }

    @Test
    func `crown selection maps onto the ring but is ignored mid-activity`() {
        let presenter = makePresenter(makeTestState(), SaveBox())

        presenter.selectMenu(crownValue: 2)
        #expect(presenter.viewModel.menuSelection == .train)

        presenter.viewModel.activity = .cleaning
        presenter.selectMenu(crownValue: 5)
        #expect(presenter.viewModel.menuSelection == .train)
    }

    // MARK: - Evolution Flash

    /// A pet whose lifetime steps have crossed the current stage's gate.
    private func makeEvolvableState() -> PetState {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve
        return state
    }

    @Test
    func `an idle pet past the step gate starts the evolution flash`() {
        let presenter = makePresenter(makeEvolvableState(), SaveBox())

        presenter.checkEvolution()

        #expect(presenter.viewModel.isEvolving)
        #expect(presenter.viewModel.isBusy)
    }

    @Test
    func `evolution is not started mid-activity`() {
        let presenter = makePresenter(makeEvolvableState(), SaveBox())
        presenter.viewModel.activity = .cleaning

        presenter.checkEvolution()

        // The busy guard leaves the existing activity untouched.
        #expect(presenter.viewModel.activity == .cleaning)
    }

    @Test
    func `an evolution already flashing is not restarted`() {
        let presenter = makePresenter(makeEvolvableState(), SaveBox())
        presenter.viewModel.activity = .evolving

        presenter.checkEvolution()

        #expect(presenter.viewModel.isEvolving)
    }

    /// The flash's reveal step — split from the strobe delay so it is testable
    /// without waiting on the ceremony's real sleep.
    @Test
    func `the reveal evolves the pet, returns to idle and persists it`() {
        let box = SaveBox()
        let presenter = makePresenter(makeEvolvableState(), box)
        presenter.viewModel.activity = .evolving

        presenter.performEvolution(to: .hopkin)

        #expect(presenter.state.species == .hopkin)
        #expect(presenter.viewModel.activity == .idle)
        #expect(box.saved.last?.species == .hopkin)
    }
}

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
        scheduler: SchedulerBox = SchedulerBox(),
        steps: StepReading = .unavailable,
        finalSteps: Int? = nil
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
            steps: steps,
            finalSteps: finalSteps,
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

    // MARK: - Step Credit

    /// A day that ends while the app is closed must still credit the steps
    /// taken after its last reading — HealthKit kept counting, the app did not.
    @Test
    func `a day that ended while closed credits its uncounted tail`() async {
        var state = makeTestState()
        let yesterday = Date.now.addingTimeInterval(-86_400)
        state.stepTrackedDay = yesterday
        state.stepsCreditedToday = 1_500
        state.lifetimeActiveSteps = 1_500
        let presenter = makePresenter(state, SaveBox(), steps: .count(200), finalSteps: 3_000)

        presenter.handleScenePhase(isActive: true, notificationsEnabled: false)
        await presenter.dayRecoveryTask?.value
        presenter.stopGameLoop()

        // 1,500 already credited + the 1,500 tail recovered + today's 200.
        #expect(presenter.state.lifetimeActiveSteps == 3_200)
        #expect(presenter.state.stepsCreditedToday == 200)
    }

    /// The recovered tail must also decide the lazy-day penalty: a day that
    /// finished above the threshold was never lazy, whatever the app last saw.
    @Test
    func `a recovered day above the lazy threshold escapes the penalty`() async {
        var state = makeTestState()
        state.stepTrackedDay = Date.now.addingTimeInterval(-86_400)
        state.stepsCreditedToday = 500
        let presenter = makePresenter(state, SaveBox(), steps: .count(10), finalSteps: 9_000)

        presenter.handleScenePhase(isActive: true, notificationsEnabled: false)
        await presenter.dayRecoveryTask?.value
        presenter.stopGameLoop()

        #expect(presenter.state.evolutionGoalPenalty == 0)
    }

    /// A missing tail must delay the rollover, never stall it.
    @Test
    func `an unavailable tail still rolls the day over`() async {
        var state = makeTestState()
        state.stepTrackedDay = Date.now.addingTimeInterval(-86_400)
        state.stepsCreditedToday = 4_000
        let presenter = makePresenter(state, SaveBox(), steps: .count(120), finalSteps: nil)

        presenter.handleScenePhase(isActive: true, notificationsEnabled: false)
        await presenter.dayRecoveryTask?.value
        presenter.stopGameLoop()

        #expect(presenter.state.stepsCreditedToday == 120)
        #expect(presenter.state.stepTrackedDay?.isSameDay(as: .now) == true)
    }

    // MARK: - Scene Phase

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

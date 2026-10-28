import Foundation
import os

/// The home screen's presenter: owns the live `PetState`, the tick loop, and
/// the sprite animators, fanning out to the feeding / healing / lights /
/// evolution extensions. Each tick advances the simulation, offers
/// evolutions, and saves; a death inside the tick fires `onDeath` during play.
/// Foregrounding restarts the loop with the catch-up; backgrounding hands
/// care reminders and the complication timeline to the system.
final class PetPresenter {

    /// The screen state the view binds to; recomputed from `state` after every change.
    private(set) var viewModel = PetViewModel()
    /// The base sprite animation player; `updateAnimation` picks weak, sleep or idle on it.
    let spriteAnimator = SpriteAnimator()
    /// The feeding extension's animator; stopped whenever an activity ends or the loop stops.
    let feedingAnimator = SpriteAnimator()

    /// The training mode's presenter, non-nil while training is running.
    var trainingPresenter: TrainingPresenter?
    /// The battle mode's presenter, non-nil while a battle is running.
    var battlePresenter: BattlePresenter?

    /// The live pet state, replaced by `GameEngine.advance` on every tick.
    var state: PetState
    /// The witness `save` persists the state through.
    let store: PetStateStore

    /// Schedules care reminders while the app is backgrounded.
    let notificationScheduler: NotificationScheduler
    /// The complication reload signal, sent after backgrounding bakes a fresh timeline.
    let complicationReloader: ComplicationReloader

    /// Weather-derived night (true/false), or nil when no reading is available.
    private let currentNight: () -> Bool?

    /// Today's step count, or nil when unavailable — drives activity scaling.
    /// Not private: the `+Modes` extension reads it when starting a battle.
    let currentSteps: () -> StepReading

    /// The final step total for a finished day, or nil when unavailable — a
    /// day that ended while the app was closed is credited in full at rollover.
    /// Not private: the `+Steps` extension performs the rollover.
    let finalSteps: (Date) async -> Int?

    /// Called when the pet dies during play, so the app can show the grave.
    private let onDeath: () -> Void

    private let gameTimer = MainActorTimer()
    /// The ambient wandering; the presenter wires its pause and sprite hooks in `init`.
    let wander = WanderController()
    /// The single in-flight activity ceremony (feed / clean / heal / refuse).
    var activityTask: Task<Void, Never>?
    /// The countdown from a lights toggle to sleep; cancelled when the game loop stops.
    let sleepSettle = DelayedTask()
    /// The in-flight rollover of a day that ended while the app was closed.
    /// Not private: the tests await it, since the rollover is asynchronous but
    /// must be observed.
    var dayRecoveryTask: Task<Void, Never>?

    #if DEBUG
    /// Index into the current debug evolution journey (see `+Evolution`).
    var debugStepIndex = 0
    #endif

    // MARK: - Init

    /// Creates the presenter around an existing `PetState`, filling the view
    /// model from it at once. Readings not injected default to nil — treated
    /// as unavailable — and dependencies to their live witnesses.
    init(
        state: PetState,
        store: PetStateStore,
        currentNight: @escaping () -> Bool? = { nil },
        currentSteps: @escaping () -> StepReading = { .unavailable },
        finalSteps: @escaping (Date) async -> Int? = { _ in nil },
        onDeath: @escaping () -> Void = {},
        notificationScheduler: NotificationScheduler = .live(),
        complicationReloader: ComplicationReloader = .live()
    ) {
        self.state = state
        self.store = store
        self.currentNight = currentNight
        self.currentSteps = currentSteps
        self.finalSteps = finalSteps
        self.onDeath = onDeath
        self.notificationScheduler = notificationScheduler
        self.complicationReloader = complicationReloader
        updateViewModel()
        configureWander()
    }

    // Wires the wander controller's pause condition and sprite hooks back to this presenter.
    private func configureWander() {
        wander.shouldPause = { [weak self] in
            guard let self else { return true }
            return viewModel.isBusy
                || viewModel.screenMode != .normal
                || state.isSleeping
                || state.isDead
                || state.isLanguishing
        }
        wander.playWalk = { [weak self] facing in
            guard let self else { return }
            spriteAnimator.play(SpriteCatalog.animation(for: state.species, kind: .sideWalk).facing(facing))
        }
        wander.onIdle = { [weak self] in
            self?.updateAnimation()
        }
    }

    // MARK: - Game Loop

    /// Starts the foreground tick loop: advances the state immediately, then
    /// ticks on `TimeConstants.gameTickInterval`, and starts wandering.
    /// Repeat calls while running are ignored.
    func startGameLoop() {
        // Idempotent — a re-fired `.task` would otherwise double-tick and double-save.
        guard !gameTimer.isRunning else { return }
        advanceState()
        gameTimer.start(interval: TimeConstants.gameTickInterval, repeats: true) { [weak self] in
            self?.tick()
        }
        wander.start()
    }

    /// Stops the loop and everything hanging off it: tick timer, ceremony and
    /// sleep-toggle tasks, the pending rollover, the training and battle modes,
    /// wandering, and both sprite animators.
    func stopGameLoop() {
        gameTimer.stop()
        cancelActivity()
        sleepSettle.cancel()
        // Left running, it would save a pet the app has already discarded.
        dayRecoveryTask?.cancel()
        dayRecoveryTask = nil
        // Mode teardown resumes wandering, so the wander stop must come last —
        // otherwise a hidden screen keeps walking its pet and redrawing.
        dismissTraining()
        dismissBattle()
        wander.stop()
        spriteAnimator.stop()
        feedingAnimator.stop()
    }

    /// Cancels the in-flight ceremony (feed / clean / heal / refuse) and returns
    /// the pet to idle. The single entry point for stopping any activity.
    func cancelActivity() {
        activityTask?.cancel()
        endActivity()
    }

    /// Returns to idle at the natural end of a ceremony (the running task is
    /// finishing on its own, so it isn't cancelled here).
    func endActivity() {
        activityTask = nil
        viewModel.activity = .idle
        feedingAnimator.stop()
        updateAnimation()
    }

    /// Cancels any in-flight ceremony and starts a new one. The single entry
    /// point for starting an activity — enforces the one-in-flight invariant.
    func startActivity(_ sequence: @escaping (PetPresenter) async -> Void) {
        activityTask?.cancel()
        activityTask = Task { [weak self] in
            guard let self else { return }
            await sequence(self)
        }
    }

    /// Starts the head-shake refusal ceremony (e.g. can't feed / clean / heal).
    func refuse() {
        startActivity { await $0.runRefuseSequence() }
    }

    private func tick() {
        advanceState()
        checkEvolution()
        save()
    }

    /// Re-applies environment-driven state (e.g. weather day/night) right away,
    /// so the dark screen follows real dusk without waiting for the next tick.
    func environmentDidChange() {
        advanceState()
        save()
    }

    /// The resolved night signal — the weather's daylight flag, else the fixed
    /// clock window.
    var currentlyNight: Bool {
        SleepSchedule.isNight(weatherNight: currentNight(), at: .now, calendar: .current)
    }

    private func advanceState() {
        let wasSleeping = state.isSleeping
        let wasDead = state.isDead
        state = GameEngine.advance(
            state, to: .now, isNight: currentNight(), steps: currentSteps(), calendar: .current
        )
        creditSteps()

        // Don't flip the persistent light — night training would leave the pet "inside".
        if !wasSleeping, state.isSleeping, viewModel.isBusy {
            state.isSleeping = false
        }

        updateViewModel()
        updateAnimation()

        // Surface a natural death right away (not just on next launch).
        if !wasDead, state.isDead {
            onDeath()
        }
    }

    // MARK: - Training & Battle Results

    /// Applies a finished training round's outcome, plays the happy animation
    /// when it was a win, and saves.
    func applyTrainingResult(won: Bool) {
        state = TrainAction.applyResult(to: state, won: won, at: .now)
        if won {
            spriteAnimator.play(.happy, for: state.species)
        }
        updateViewModel()
        save()
    }

    /// Applies a finished battle's outcome to the state and saves.
    func applyBattleResult(_ result: BattleResult) {
        state = BattleEngine.applyResult(result, to: state, at: .now)
        updateViewModel()
        save()
    }

    // MARK: - Menu Navigation

    /// Crown rotation maps straight onto the menu ring (ignored mid-activity).
    func selectMenu(crownValue: Double) {
        guard !viewModel.isBusy else { return }
        let all = PetViewModel.MenuAction.allCases
        let index = Int(crownValue.rounded()) % all.count
        viewModel.menuSelection = all[index]
    }

    /// Moves the menu selection one item forward, wrapping past the last.
    func selectNextMenu() {
        let all = PetViewModel.MenuAction.allCases
        let index = (viewModel.menuSelection.rawValue + 1) % all.count
        viewModel.menuSelection = all[index]
    }

    /// Moves the menu selection one item back, wrapping before the first.
    func selectPreviousMenu() {
        let all = PetViewModel.MenuAction.allCases
        let index = (viewModel.menuSelection.rawValue - 1 + all.count) % all.count
        viewModel.menuSelection = all[index]
    }

    // MARK: - Scene Phase

    /// Foregrounding runs the catch-up at once (no stale scene after hours away)
    /// and restarts the loop if stopped; backgrounding hands care reminders to
    /// the system — or clears them when the toggle is off. Activation never
    /// cancels: a wrist raise flips active and would wipe them before they fire.
    func handleScenePhase(isActive: Bool, notificationsEnabled: Bool) {
        if isActive {
            startGameLoop()
            environmentDidChange()
        } else {
            CareHandoff.perform(
                state: state, now: .now, steps: currentSteps().count, notificationsEnabled: notificationsEnabled,
                witnesses: CareHandoff.Witnesses(notifications: notificationScheduler, complications: complicationReloader)
            )
        }
    }

    // MARK: - Helpers

    /// Recomputes the view model's published fields from the current state.
    /// Called after every state change so the screen never shows stale values.
    func updateViewModel() {
        viewModel.status = PetStatus(from: state)
        viewModel.evolutionProgress = state.evolutionProgressFraction
        viewModel.moonPhase = MoonPhase.current(date: .now)
        viewModel.dayPhase = DayPhase.resolve(
            isNight: currentlyNight, lightsOn: state.lightsOn
        )
    }

    /// Picks the base sprite animation — weak, sleep or idle — from the state.
    /// Does nothing off the normal screen or mid-ceremony: a ceremony's own
    /// animation must keep playing.
    func updateAnimation() {
        guard viewModel.screenMode == .normal else { return }
        // Every other activity plays its own ceremony animation — never override it.
        switch viewModel.activity {
        case .idle, .feeding(.selecting):
            if PetStatus(from: state).isDrooping {
                // Drooping is languishing while awake — asleep it still rests, like the toy.
                spriteAnimator.play(SpriteCatalog.weakAnimation(for: state.species))
            } else {
                let kind: SpriteCatalog.AnimationKind =
                    state.isSleeping ? .sleep : .idle
                spriteAnimator.play(kind, for: state.species)
            }
        case .feeding(.serving), .feeding(.bite), .feeding(.satisfied),
             .cleaning, .healing, .refusing, .evolving:
            // The evolution flash keeps whatever sprite is on screen; the strobe
            // washes it, and the reveal plays its own happy bounce.
            break
        }
    }

    /// Persists the state through the store; a failure is logged, not thrown.
    func save() {
        store.save(state, loggingTo: Log.presentation)
    }
}

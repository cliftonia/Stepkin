import Foundation
import os
import Observation

/// The app's lifecycle phase machine. Resolves the saved pet into a
/// `LifecyclePhase` on launch and owns the presenter for whichever phase is
/// showing. Phases replace one another (hatch → onboarding → alive → dead →
/// hatch) rather than stacking, which is why lifecycle screens are not
/// `AppRoute`s — only stats and settings push onto the `NavigationStack`.
@Observable
final class AppPresenter {

    // MARK: - State

    /// The mutually exclusive phases of the lifecycle cycle. Each phase owns
    /// its presenter in the properties below, which is why the cases carry
    /// no payload.
    enum LifecyclePhase {
        case loading
        case hatching
        case onboarding
        case alive
        case dead
    }

    /// The lifecycle phase on screen; `loading` until `onAppear` resolves the saved pet.
    private(set) var phase: LifecyclePhase = .loading
    /// The pet screen's presenter; non-nil only while `phase` is `.alive`.
    private(set) var petPresenter: PetPresenter?
    /// The pushed stats screen's presenter, created by `navigateToStats`.
    private(set) var statsPresenter: StatsPresenter?
    /// The pushed settings screen's presenter, created by `navigateToSettings`.
    private(set) var settingsPresenter: SettingsPresenter?
    /// The hatch screen's presenter; non-nil only while `phase` is `.hatching`.
    private(set) var hatchPresenter: HatchPresenter?
    /// The onboarding screen's presenter; non-nil only while `phase` is `.onboarding`.
    private(set) var onboardingPresenter: OnboardingPresenter?
    /// The newborn saved at hatch, held until onboarding finishes.
    private var hatchedState: PetState?
    /// The death screen's presenter, created by `startDeath` when the pet dies.
    private(set) var deathPresenter: DeathPresenter?

    /// The `NavigationStack` path stats and settings push onto; phase transitions pop to root.
    let router = AppRouter()
    /// The weather store; its night signal feeds the catch-up tick and `PetPresenter`.
    let weatherStore: WeatherStore
    /// The step store; its readings feed the catch-up tick, activity scaling, and stats.
    let stepActivityStore: StepActivityStore
    /// The shared settings store; its weather and steps flags switch those readings on and off.
    let settings: SettingsStore

    private let store: PetStateStore
    private let permissions: PermissionRequester

    /// The in-flight permission round started by `startAlive`. Not private:
    /// the tests await it so the step refresh that follows can be observed.
    private(set) var permissionTask: Task<Void, Never>?

    // MARK: - Init

    /// Creates the presenter at the `loading` phase; nothing is read from
    /// the store until `onAppear` resolves the saved pet.
    init(
        store: PetStateStore = JSONPetStateStore.live(),
        weatherStore: WeatherStore = .makeDefault(),
        stepActivityStore: StepActivityStore = StepActivityStore(),
        settings: SettingsStore = SettingsStore(),
        permissions: PermissionRequester = .live()
    ) {
        self.store = store
        self.weatherStore = weatherStore
        self.stepActivityStore = stepActivityStore
        self.settings = settings
        self.permissions = permissions
    }

    // MARK: - Lifecycle

    /// Loads the saved pet and flips the phase machine to match it, after a
    /// catch-up tick that lands on now; a missing save, an egg state or a
    /// load error restarts at hatching.
    func onAppear() {
        loadOrStartNew()
    }

    private func loadOrStartNew() {
        do {
            guard let saved = try store.load() else {
                startHatching()
                return
            }
            if saved.isEgg {
                startHatching()
                return
            }

            // Advance before first render — no stale-night flash; away deaths surface at once.
            let advanced = GameEngine.advance(
                saved, to: .now,
                isNight: weatherStore.nightSignal(),
                steps: stepActivityStore.todaySteps
            )
            persist(advanced)

            if advanced.isDead {
                startDeath(state: advanced)
            } else {
                startAlive(state: advanced)
            }
        } catch {
            Log.presentation.error("Failed to load state: \(error, privacy: .public)")
            startHatching()
        }
    }

    /// Saves the pet; errors are logged, never thrown — otherwise a failed
    /// save would silently lose the pet (or its catch-up).
    private func persist(_ state: PetState) {
        do {
            try store.save(state)
        } catch {
            Log.presentation.error("Failed to save state: \(error, privacy: .public)")
        }
    }

    // MARK: - Phase Transitions

    private func startHatching() {
        phase = .hatching
        hatchPresenter = HatchPresenter { [weak self] in
            self?.onHatchComplete()
        }
    }

    private func onHatchComplete() {
        // Persist before onboarding — quitting mid-onboarding must not lose the pet.
        let state = PetState.hatched(at: .now)
        persist(state)
        hatchedState = state
        startOnboarding()
    }

    private func startOnboarding() {
        phase = .onboarding
        hatchPresenter?.cancel()
        hatchPresenter = nil
        onboardingPresenter = OnboardingPresenter { [weak self] in
            self?.finishOnboarding()
        }
    }

    private func finishOnboarding() {
        onboardingPresenter = nil
        startAlive(state: hatchedState ?? PetState.hatched(at: .now))
        hatchedState = nil
    }

    private func startAlive(state: PetState) {
        phase = .alive
        let presenter = PetPresenter(
            state: state,
            store: store,
            currentNight: { [weatherStore, settings] in
                // Weather off -> no night signal, so day/night falls back to the clock.
                settings.weatherEnabled ? weatherStore.nightSignal() : nil
            },
            currentSteps: { [stepActivityStore, settings] in
                // Steps off -> no reading, so no activity scaling.
                settings.stepsEnabled ? stepActivityStore.todaySteps : nil
            },
            finalSteps: { [stepActivityStore, settings] day in
                settings.stepsEnabled ? await stepActivityStore.finalSteps(for: day) : nil
            },
            onDeath: { [weak self] in self?.checkDeath() }
        )
        petPresenter = presenter
        hatchPresenter = nil
        onboardingPresenter = nil
        deathPresenter = nil
        router.popToRoot()
        requestPermissions()
    }

    /// Prompts for HealthKit and notifications once the pet is on screen,
    /// then re-reads today's steps so a freshly granted permission shows at
    /// once rather than after the cache window.
    private func requestPermissions() {
        guard permissionTask == nil else { return }
        permissionTask = Task { [weak self] in
            guard let self else { return }
            await permissions.requestAll()
            if settings.stepsEnabled {
                await stepActivityStore.refresh()
            }
            permissionTask = nil
        }
    }

    private func startDeath(state: PetState) {
        // Pop first — the grave must not appear beneath a pushed screen (e.g. Stats).
        router.popToRoot()
        phase = .dead
        deathPresenter = DeathPresenter(state: state, onRestart: { [weak self] in
            self?.onRestart()
        })
        petPresenter?.stopGameLoop()
        petPresenter = nil
    }

    private func onRestart() {
        do {
            try store.delete()
        } catch {
            Log.presentation.error("Failed to delete state: \(error, privacy: .public)")
        }
        startHatching()
    }

    // MARK: - Navigation Actions

    /// Pushes the stats screen with a snapshot of the live pet state; steps
    /// are included only when the steps setting is enabled, else nil. Does
    /// nothing while no pet is alive.
    func navigateToStats() {
        guard let petPresenter else { return }
        let presenter = StatsPresenter()
        presenter.update(
            from: petPresenter.state,
            steps: settings.stepsEnabled ? stepActivityStore.todaySteps : nil,
            stepsEnabled: settings.stepsEnabled
        )
        statsPresenter = presenter
        router.navigate(to: .stats)
    }

    /// Pushes the settings screen bound to the shared `SettingsStore`; DEBUG
    /// builds additionally wire a `SettingsDebugActions` set.
    func navigateToSettings() {
        #if DEBUG
        // Debug actions pop to the pet screen first so their effect is visible at once.
        let presenter = SettingsPresenter(settings: settings, debug: SettingsDebugActions(
            setWeather: { [weak self, weatherStore] condition in
                self?.router.popToRoot()
                weatherStore.setDebugCondition(condition)
            },
            forceEvolve: { [weak self] in self?.router.popToRoot(); self?.petPresenter?.debugEvolve() },
            careTest: { [weak self] in self?.router.popToRoot(); self?.petPresenter?.debugCareTest() },
            killPet: { [weak self] in self?.restartPet() },
            morph: { [weak self] species in
                self?.router.popToRoot()
                self?.petPresenter?.debugMorph(into: species)
            }
        ))
        #else
        let presenter = SettingsPresenter(settings: settings)
        #endif
        settingsPresenter = presenter
        router.navigate(to: .settings)
    }

    /// The `onDeath` hook from `PetPresenter` — re-reads the live state and
    /// flips to the death phase if the pet has died.
    func checkDeath() {
        guard let petPresenter else { return }
        let state = petPresenter.state
        if state.isDead {
            startDeath(state: state)
        }
    }

    /// Resets the current pet back to a fresh egg (the ⚠️ menu button).
    func restartPet() {
        #if DEBUG
        // Kill instead of reset in DEBUG so the Death screen is verifiable on demand.
        if let petPresenter {
            var state = petPresenter.state
            state.isDead = true
            persist(state)
            petPresenter.stopGameLoop()
            self.petPresenter = nil
            startDeath(state: state)
            return
        }
        #endif
        petPresenter?.stopGameLoop()
        petPresenter = nil
        onRestart()
    }
}

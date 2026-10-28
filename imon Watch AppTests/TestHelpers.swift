import Foundation
import Testing
@testable import imon_Watch_App

func makeTestState(
    species: PetSpecies = .emberkin,
    hunger: Int = 4,
    strength: Int = 4,
    weight: Int = 20,
    at date: Date = .now
) -> PetState {
    var state = PetState.hatched(at: date)
    state.species = species
    state.hungerHearts = StatHearts(hunger)
    state.strengthHearts = StatHearts(strength)
    state.weight = Weight(weight)
    return state
}

/// Builds a `UserDefaults` suite unique to this call and emptied, so tests never share persisted state.
func makeIsolatedDefaults(_ prefix: String) throws -> UserDefaults {
    let suite = "\(prefix).\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

/// A fixed, repeatable moment at `hour` o'clock on the same calendar day.
func today(at hour: Int) -> Date {
    let calendar = Calendar.current
    let midnight = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
    return calendar.date(byAdding: .hour, value: hour, to: midnight) ?? midnight
}

/// Builds a `PetPresenter` whose collaborators default to inert no-ops, so a test overrides only what it observes.
@MainActor
func makePetPresenter(
    state: PetState = makeTestState(),
    store: PetStateStore = PetStateStore(save: { _ in }, load: { nil }, delete: {}),
    scheduler: NotificationScheduler = NotificationScheduler(
        schedule: { _ in }, notify: { _, _, _ in }, cancelAll: {}, requestAuthorization: { true }
    ),
    reloader: ComplicationReloader = ComplicationReloader(reload: {}),
    steps: Int? = nil,
    finalSteps: Int? = nil,
    onDeath: @escaping () -> Void = {}
) -> PetPresenter {
    PetPresenter(
        state: state,
        store: store,
        currentSteps: { steps },
        finalSteps: { _ in finalSteps },
        onDeath: onDeath,
        notificationScheduler: scheduler,
        complicationReloader: reloader
    )
}

/// Polls every 5 ms until `condition` holds or `timeout` passes, so a slow simulator cannot flake a positive
/// assertion; returns whether the condition held.
@MainActor
func waitUntil(_ condition: @MainActor () -> Bool, timeout: Duration = .seconds(30)) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(5))
    }
    return condition()
}

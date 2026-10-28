import Foundation
import StepkinEngine

/// Builds a freshly hatched pet of `species` with the given hearts and weight, the shared starting
/// point for engine and app tests.
public func makeTestState(
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

/// The failure `makeIsolatedDefaults(_:)` throws when the system refuses the suite name.
public struct IsolatedDefaultsUnavailable: Error {}

/// Builds a `UserDefaults` suite unique to this call and emptied, so tests never share persisted
/// state.
public func makeIsolatedDefaults(_ prefix: String) throws -> UserDefaults {
    let suite = "\(prefix).\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else { throw IsolatedDefaultsUnavailable() }
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

/// Polls every 5 ms until `condition` holds or `timeout` passes, so a slow machine cannot flake a
/// positive assertion; returns whether the condition held.
@MainActor
public func waitUntil(_ condition: @MainActor () -> Bool, timeout: Duration = .seconds(30)) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(5))
    }
    return condition()
}

import Foundation

/// Polls every 5 ms until `condition` holds or `timeout` passes, so a slow machine cannot flake a positive
/// assertion; returns whether the condition held. A copy of the app test bundle's helper, kept here until
/// the shared test-support target hosts it.
@MainActor
func waitUntil(_ condition: @MainActor () -> Bool, timeout: Duration = .seconds(30)) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(5))
    }
    return condition()
}

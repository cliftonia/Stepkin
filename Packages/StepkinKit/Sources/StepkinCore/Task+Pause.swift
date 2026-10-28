import Foundation

/// Sleeps for the given beat and reports whether the task is still alive.
/// `guard await pause(ms: 800) else { return }` replaces the repeated
/// sleep-then-check-cancelled choreography in animation sequences.
public func pause(ms: Int) async -> Bool {
    try? await Task.sleep(for: .milliseconds(ms))
    return !Task.isCancelled
}

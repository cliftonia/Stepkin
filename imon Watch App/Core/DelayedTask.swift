import Foundation

/// Runs one main-actor closure after a delay; scheduling again cancels the
/// pending run. Owners hold one instance, and deinit cancels the wait so a
/// discarded owner never fires late.
@MainActor
final class DelayedTask {

    /// Whether a run is waiting on its delay; clears when the run starts.
    private(set) var isPending = false

    private var task: Task<Void, Never>?
    private var generation = 0

    /// Runs `run` on the main actor after `delay`, replacing any run already pending.
    func schedule(after delay: Duration, _ run: @escaping @MainActor () -> Void) {
        task?.cancel()
        generation += 1
        let current = generation
        isPending = true
        task = Task { [weak self] in
            try? await Task.sleep(for: delay)
            // A superseded or cancelled wait must neither run nor clear the newer one's state.
            guard !Task.isCancelled, let self, self.generation == current else { return }
            self.task = nil
            self.isPending = false
            run()
        }
    }

    /// Cancels the pending run, if any.
    func cancel() {
        task?.cancel()
        task = nil
        generation += 1
        isPending = false
    }

    // Runs on the main actor, so the task can be reached without an unsafe escape.
    isolated deinit {
        task?.cancel()
    }
}

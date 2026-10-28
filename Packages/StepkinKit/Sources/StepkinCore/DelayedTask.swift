import Foundation

/// Runs one main-actor closure after a delay; scheduling again cancels the
/// pending run. Owners hold one instance, and deinit cancels the wait so a
/// discarded owner never fires late. `schedule` and `cancel` both cancel the
/// previous task, so a superseded wait always sees cancellation after its
/// sleep; no identity check is needed.
@MainActor
public final class DelayedTask {

    /// Whether a run is waiting on its delay; clears when the run starts.
    public private(set) var isPending = false

    private var task: Task<Void, Never>?

    /// Creates an idle scheduler with nothing pending.
    public init() {}

    /// Runs `run` on the main actor after `delay`, replacing any run already pending.
    /// Returns the pending run, for callers that need to await it; production callers ignore it.
    @discardableResult
    public func schedule(after delay: Duration, _ run: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        task?.cancel()
        isPending = true
        let pending = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            self.task = nil
            self.isPending = false
            run()
        }
        task = pending
        return pending
    }

    /// Cancels the pending run, if any.
    public func cancel() {
        task?.cancel()
        task = nil
        isPending = false
    }

    // Runs on the main actor, so the task can be reached without an unsafe escape.
    isolated deinit {
        task?.cancel()
    }
}

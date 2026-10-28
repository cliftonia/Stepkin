import Foundation

/// A repeating or one-shot timer whose callback always runs on the main actor.
/// Owners hold one instance and `start` it again to replace the pending fire;
/// the run loop retains a scheduled timer, so deinit stops it rather than
/// leave a discarded owner's timer firing forever.
@MainActor
public final class MainActorTimer {

    /// Whether a timer is pending; a one-shot clears it when it fires, before the callback runs.
    public private(set) var isRunning = false

    private var timer: Timer?

    /// Creates an idle timer with nothing scheduled.
    public init() {}

    /// Schedules `fire` after `interval` seconds, once or repeatedly,
    /// replacing any timer already running.
    public func start(interval: TimeInterval, repeats: Bool, _ fire: @escaping @MainActor () -> Void) {
        stop()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRunning else { return }
                if !repeats {
                    self.stop()
                }
                fire()
            }
        }
    }

    /// Cancels the pending timer, if any.
    public func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    // Runs on the main actor, so the timer can be reached without an unsafe escape.
    isolated deinit {
        timer?.invalidate()
    }
}

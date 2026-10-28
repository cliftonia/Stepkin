import Foundation
import Observation

/// Ambient wandering: the pet idles in place, then after a random 3–8 second
/// wait walks 3–6 steps left or right inside X offsets 2...9. Every exit — a
/// pause, a skipped attempt, a finished walk — schedules the next attempt;
/// the loop ends only in `stop`. The owner supplies the pause condition and
/// the sprite hooks, so the controller knows nothing of the presenter.
@MainActor
@Observable
final class WanderController {

    /// The two phases of the loop, which never overlap and share one timer.
    private enum Phase {
        case idle
        case walking(direction: Int, stepsRemaining: Int)
    }

    /// The pet's horizontal offset on the LCD, from 2 to 9.
    private(set) var offsetX: Int = 8

    /// Whether wandering should hold still right now; asked before every attempt and step.
    @ObservationIgnored var shouldPause: () -> Bool = { false }
    /// Plays the walking sprite facing the given way when a walk begins.
    @ObservationIgnored var playWalk: (Facing) -> Void = { _ in }
    /// Called when a walk ends, so the owner can restore the idle sprite.
    @ObservationIgnored var onIdle: () -> Void = {}

    /// Whether a walk is in progress.
    var isWalking: Bool {
        if case .walking = phase { return true }
        return false
    }

    /// Whether a timer is pending; false after `stop`.
    var isScheduled: Bool { timer.isRunning }

    private var phase = Phase.idle
    private var isActive = false
    @ObservationIgnored private let timer = MainActorTimer()

    /// Starts the loop by scheduling the first walk attempt.
    func start() {
        isActive = true
        phase = .idle
        scheduleNextAttempt()
    }

    /// Stops the loop, arms no timer, and resets the offset to 8.
    func stop() {
        isActive = false
        timer.stop()
        phase = .idle
        offsetX = 8
    }

    /// Starts a walk with probability 0.6, otherwise skips to the next
    /// attempt. Direction is forced inward at the edges — right from offset
    /// 3 or lower, left from 8 or higher — and random in between. Internal
    /// so tests can drive an attempt without waiting out the random delay.
    func tryStartWalking() {
        // A stale or spurious fire during a walk or after `stop` is ignored.
        guard isActive, !isWalking else { return }
        guard !shouldPause(), Double.random(in: 0...1) < 0.6 else {
            scheduleNextAttempt()
            return
        }

        let direction: Int
        if offsetX <= 3 {
            direction = 1
        } else if offsetX >= 8 {
            direction = -1
        } else {
            direction = Bool.random() ? 1 : -1
        }
        phase = .walking(direction: direction, stepsRemaining: Int.random(in: 3...6))
        playWalk(direction > 0 ? .right : .left)
        timer.start(interval: 0.35, repeats: true) { [weak self] in
            self?.step()
        }
    }

    // Schedules the next attempt after a random 3–8 second delay, replacing any pending timer.
    private func scheduleNextAttempt() {
        timer.start(interval: Double.random(in: 3...8), repeats: false) { [weak self] in
            self?.tryStartWalking()
        }
    }

    // Advances the walk one step; pausing, leaving the band or running out of steps ends it.
    private func step() {
        guard isActive, case .walking(let direction, let remaining) = phase else { return }
        let newX = offsetX + direction
        guard !shouldPause(), remaining > 0, (2...9).contains(newX) else {
            returnToIdle()
            return
        }

        offsetX = newX
        phase = .walking(direction: direction, stepsRemaining: remaining - 1)
        if remaining - 1 <= 0 {
            returnToIdle()
        }
    }

    private func returnToIdle() {
        phase = .idle
        onIdle()
        scheduleNextAttempt()
    }
}

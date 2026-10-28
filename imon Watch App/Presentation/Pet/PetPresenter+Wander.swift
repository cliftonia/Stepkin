import Foundation

/// Ambient wandering: the pet idles in place, then walks a few steps left or
/// right. Each delay between walks is random, so every attempt is scheduled
/// as its own one-shot timer, and every exit — a pause, a skipped attempt,
/// a finished walk — schedules the next one; the loop stops only in
/// `stopWandering`. It pauses while the view model is busy, the screen mode
/// is not `.normal`, or the pet is sleeping, dead, or languishing.
extension PetPresenter {

    // MARK: - Wandering

    /// Starts the wander loop by scheduling the first walk attempt.
    func startWandering() {
        scheduleNextWander()
    }

    /// Stops the wander loop and resets `petOffsetX` to 8.
    func stopWandering() {
        wanderTimer.stop()
        wanderState = .idle
        viewModel.petOffsetX = 8
    }

    private var shouldPauseWander: Bool {
        viewModel.isBusy
            || viewModel.screenMode != .normal
            || state.isSleeping
            || state.isDead
            || state.isLanguishing
    }

    /// Schedules the next walk attempt after a random 3–8 second delay,
    /// replacing any pending timer.
    private func scheduleNextWander() {
        let delay = Double.random(in: 3...8)
        wanderTimer.start(interval: delay, repeats: false) { [weak self] in
            self?.tryStartWalking()
        }
    }

    /// Starts a walk with probability 0.6, otherwise skips to the next
    /// attempt. Direction is forced inward at the edges — right from offset
    /// 3 or lower, left from 8 or higher — and random in between; a walk is
    /// 3–6 steps.
    private func tryStartWalking() {
        guard !shouldPauseWander else {
            scheduleNextWander()
            return
        }

        guard Double.random(in: 0...1) < 0.6 else {
            scheduleNextWander()
            return
        }

        let offsetX = viewModel.petOffsetX
        let direction: Int
        if offsetX <= 3 {
            direction = 1
        } else if offsetX >= 8 {
            direction = -1
        } else {
            direction = Bool.random() ? 1 : -1
        }

        let steps = Int.random(in: 3...6)
        wanderState = .walking(
            direction: direction,
            stepsRemaining: steps
        )

        let walk = SpriteCatalog.animation(
            for: state.species, kind: .sideWalk
        )
        spriteAnimator.play(
            walk.facing(direction > 0 ? .right : .left)
        )

        wanderTimer.start(interval: 0.35, repeats: true) { [weak self] in
            self?.wanderStep()
        }
    }

    /// Advances the walk one step; the pet must stay inside X offsets 2...9,
    /// and leaving the band or running out of steps ends the walk.
    private func wanderStep() {
        guard case .walking(
            let direction,
            let remaining
        ) = wanderState else {
            returnToIdle()
            return
        }

        if shouldPauseWander {
            returnToIdle()
            return
        }

        let newX = viewModel.petOffsetX + direction
        guard newX >= 2, newX <= 9, remaining > 0 else {
            returnToIdle()
            return
        }

        viewModel.petOffsetX = newX
        wanderState = .walking(
            direction: direction,
            stepsRemaining: remaining - 1
        )

        if remaining - 1 <= 0 {
            returnToIdle()
        }
    }

    private func returnToIdle() {
        wanderTimer.stop()
        wanderState = .idle
        updateAnimation()
        scheduleNextWander()
    }
}

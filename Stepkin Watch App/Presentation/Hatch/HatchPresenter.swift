import Foundation
import WatchKit

/// Drives the hatch ceremony: a fixed egg → crack → newborn timeline that runs
/// once from `startHatching` and ends by calling `onHatched`. Purely visual —
/// the newborn `PetState` is only created and persisted by `AppPresenter`
/// after the callback, so abandoning the ceremony loses nothing.
final class HatchPresenter {

    /// Carries the current hatch phase shown to the view; only `startHatching` writes it.
    private(set) var viewModel = HatchViewModel()

    /// Plays the sprite loops for each phase; stopped when the ceremony ends.
    let spriteAnimator = SpriteAnimator()

    /// The running ceremony; non-nil from `startHatching` until it ends or `cancel` is called.
    private(set) var ceremonyTask: Task<Void, Never>?

    private let onHatched: () -> Void
    private let beat: @MainActor (Int) async -> Bool

    // MARK: - Init

    /// Creates the presenter; `onHatched` fires once the hatch ceremony ends.
    /// `beat` waits out one timeline step in milliseconds and returns false
    /// when the ceremony was cancelled, so tests can run it instantly.
    init(
        onHatched: @escaping () -> Void,
        beat: @escaping @MainActor (Int) async -> Bool = { await pause(ms: $0) }
    ) {
        self.onHatched = onHatched
        self.beat = beat
    }

    // MARK: - Actions

    /// Runs the ceremony's egg → crack → newborn timeline, then stops the
    /// sprite animator and calls `onHatched` — asynchronously, roughly five
    /// and a half seconds after this returns. A second call while the
    /// ceremony is still running is ignored; once it ends or is cancelled, a new one may start.
    func startHatching() {
        guard ceremonyTask == nil else { return }
        viewModel.phase = .egg
        spriteAnimator.play(SharedSprites.egg)

        ceremonyTask = Task {
            defer { ceremonyTask = nil }
            guard await beat(2_000) else { return }

            viewModel.phase = .cracking
            spriteAnimator.play(SharedSprites.eggCrack)
            WKInterfaceDevice.hatchHaptic()

            guard await beat(2_000) else { return }

            viewModel.phase = .hatched
            spriteAnimator.play(.happy, for: .dotkin)

            guard await beat(1_500) else { return }

            spriteAnimator.stop()
            onHatched()
        }
    }

    /// Stops a running ceremony without hatching, so the caller can drop the presenter.
    func cancel() {
        ceremonyTask?.cancel()
        ceremonyTask = nil
    }
}

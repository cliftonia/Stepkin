import Foundation
import Observation

/// Sprite animation playback for SwiftUI views.
/// `@Observable` so a view reading `currentFrame` re-renders on every frame
/// advance without any explicit publisher wiring.
@MainActor
@Observable
final class SpriteAnimator {

    /// The frame the view draws, taken from the playing animation; kept at
    /// the final pose after `stop()` rather than reset to empty.
    private(set) var currentFrame: SpriteFrame = .empty
    /// Index into the playing animation's frames; wraps to 0 when looping.
    private(set) var currentFrameIndex: Int = 0

    private var animation: SpriteAnimation?
    // The run loop retains a repeating timer, so it must be invalidated in
    // deinit or every discarded animator leaves a timer firing forever.
    // Not observed — a timer swap is never something a view redraws for.
    @ObservationIgnored private var timer: Timer?

    // Runs on the main actor, so the timer can be reached without an unsafe escape.
    isolated deinit {
        timer?.invalidate()
    }

    /// Plays a catalog animation; shared by every presenter so the
    /// `SpriteCatalog.animation(for:kind:)` lookup lives in one place.
    func play(_ kind: SpriteCatalog.AnimationKind, for species: PetSpecies) {
        play(SpriteCatalog.animation(for: species, kind: kind))
    }

    /// Replaces whatever is playing and starts from frame 0. Single-frame
    /// animations just display their frame — no timer is scheduled.
    func play(_ animation: SpriteAnimation) {
        stop()
        self.animation = animation
        currentFrameIndex = 0
        currentFrame = animation.frames.first ?? .empty

        guard animation.frameCount > 1 else { return }

        timer = Timer.scheduledTimer(
            withTimeInterval: animation.frameDuration,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }
    }

    /// Halts playback but deliberately leaves `currentFrame` showing the last
    /// frame, so a finished non-looping animation holds its final pose instead
    /// of blinking to empty.
    func stop() {
        timer?.invalidate()
        timer = nil
        animation = nil
        currentFrameIndex = 0
    }

    var isPlaying: Bool { animation != nil }

    private func advanceFrame() {
        guard let animation else { return }
        let nextIndex = currentFrameIndex + 1

        if nextIndex >= animation.frameCount {
            if animation.loops {
                currentFrameIndex = 0
            } else {
                stop()
                return
            }
        } else {
            currentFrameIndex = nextIndex
        }

        currentFrame = animation.frames[currentFrameIndex]
    }

}

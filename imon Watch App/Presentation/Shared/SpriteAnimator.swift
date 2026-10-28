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
    // Not observed — a timer swap is never something a view redraws for.
    // Its own deinit stops it, so a discarded animator leaves nothing firing.
    @ObservationIgnored private let timer = MainActorTimer()

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

        timer.start(interval: animation.frameDuration, repeats: true) { [weak self] in
            self?.advanceFrame()
        }
    }

    /// Halts playback but deliberately leaves `currentFrame` showing the last
    /// frame, so a finished non-looping animation holds its final pose instead
    /// of blinking to empty.
    func stop() {
        timer.stop()
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

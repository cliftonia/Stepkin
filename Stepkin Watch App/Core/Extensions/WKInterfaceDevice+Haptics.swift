import WatchKit

/// Named haptic cues, one per game event, so the `WKHapticType` mapping and
/// the master switch live in one place.
extension WKInterfaceDevice {

    /// Master switch for every haptic, mirrored from the Settings toggle. When
    /// off, all the cues below become no-ops so buttons and actions stay silent.
    static var hapticsEnabled = true

    private static func perform(_ type: WKHapticType) {
        guard hapticsEnabled else { return }
        WKInterfaceDevice.current().play(type)
    }

    /// Plays the feeding cue; a no-op while `hapticsEnabled` is off.
    static func feedHaptic() { perform(.click) }

    /// Plays the chomp cue; a no-op while `hapticsEnabled` is off.
    static func chompHaptic() { perform(.directionDown) }

    /// Plays the refusal cue; a no-op while `hapticsEnabled` is off.
    static func rejectHaptic() { perform(.failure) }

    /// Plays the cleaning cue; a no-op while `hapticsEnabled` is off.
    static func cleanHaptic() { perform(.success) }

    /// Plays the healing cue; a no-op while `hapticsEnabled` is off.
    static func healHaptic() { perform(.success) }

    /// Plays the evolution cue; a no-op while `hapticsEnabled` is off.
    static func evolveHaptic() { perform(.notification) }

    /// Plays the battle cue; a no-op while `hapticsEnabled` is off.
    static func battleHaptic() { perform(.directionUp) }

    /// Plays the battle-victory cue; a no-op while `hapticsEnabled` is off.
    static func battleWinHaptic() { perform(.success) }

    /// Plays the battle-defeat cue; a no-op while `hapticsEnabled` is off.
    static func battleLoseHaptic() { perform(.failure) }

    /// Plays the hatching cue; a no-op while `hapticsEnabled` is off.
    static func hatchHaptic() { perform(.start) }

    /// Plays the button-press cue; a no-op while `hapticsEnabled` is off.
    static func buttonHaptic() { perform(.click) }

    /// Plays the training-hit cue; a no-op while `hapticsEnabled` is off.
    static func trainingHitHaptic() { perform(.success) }

    /// Plays the training-miss cue; a no-op while `hapticsEnabled` is off.
    static func trainingMissHaptic() { perform(.retry) }

    /// Plays the training-victory cue; a no-op while `hapticsEnabled` is off.
    static func trainingWinHaptic() { perform(.notification) }

    /// Plays the training-defeat cue; a no-op while `hapticsEnabled` is off.
    static func trainingLoseHaptic() { perform(.failure) }
}

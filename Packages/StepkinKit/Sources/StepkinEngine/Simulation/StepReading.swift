/// Today's step signal as the engine sees it: switched off by the player, on
/// but not yet read, or a count.
public enum StepReading: Sendable, Equatable {
    /// The player has switched Steps off.
    case off
    /// Steps are on, but no reading has arrived yet.
    case unavailable
    /// Today's running step count.
    case count(Int)

    /// The count when one exists; nil for `off` and `unavailable`.
    public var count: Int? {
        switch self {
        case .off, .unavailable: nil
        case .count(let steps): steps
        }
    }
}

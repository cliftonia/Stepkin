import Foundation

// MARK: - Timing & Gameplay Constants

/// The gameplay timing table — every interval, threshold, and weight in one
/// place, so tuning against the original 1997 V1 device is a single-file diff.
public enum TimeConstants {

    // MARK: - Stat Depletion

    /// One hunger heart per interval.
    public static let hungerDepletionInterval: TimeInterval = 4_200

    /// One strength heart per interval.
    package static let strengthDepletionInterval: TimeInterval = 3_600

    // MARK: - Lifecycle Events

    /// One poop pile per interval.
    package static let poopInterval: TimeInterval = 7_200

    /// A care call unanswered for this long becomes a care mistake.
    package static let careMistakeWindow: TimeInterval = 1_200

    /// A light left on at night accrues one care mistake per interval, so one
    /// forgetful night nudges evolution toward neglect without hard-locking it.
    package static let lightsMistakeWindow: TimeInterval = 10_800

    // MARK: - Game Loop

    /// One game-loop tick per interval.
    public static let gameTickInterval: TimeInterval = 30

    /// The settle — the gap between the light going out at bedtime and the pet falling asleep.
    public static let sleepDelay: TimeInterval = 120

    /// The pet's bedtime: it only settles to sleep from 9pm until the morning
    /// wake hour, so an early winter dusk doesn't send it to bed at 5pm.
    package static let sleepHour: Int = 21

    /// The fallback night window (24h clock), used only when weather is unavailable.
    package static let nightStartHour: Int = 18
    /// The morning wake hour: the end of the night window begun at `nightStartHour`.
    package static let nightEndHour: Int = 6

    // MARK: - Limits

    /// Maximum poop piles on screen before health penalty.
    public static let maxPoopPiles: Int = 4

    // MARK: - Death Thresholds

    /// Total untreated injuries before the pet dies.
    public static let maxInjuriesBeforeDeath: Int = 20

    /// An untreated injury becomes fatal after this long.
    package static let untreatedInjuryDeathTime: TimeInterval = 21_600

    /// The languishing countdown toward collapse: once hunger and strength
    /// are both empty, the pet dies if this interval elapses without recovery.
    /// Care mistakes steer evolution but never kill, so this is the sole
    /// neglect death.
    package static let collapseDeathTime: TimeInterval = 172_800

    // MARK: - Notifications

    /// Local hour (24h) from which a low step count earns an exercise nudge.
    package static let exerciseHour: Int = 15

    /// Today's steps below this after `exerciseHour` earn an exercise nudge.
    package static let exerciseStepTarget: Int = 5_000

    /// Small lead before the exercise nudge fires, so it's prompt but not instant.
    package static let exerciseNudgeLead: TimeInterval = 600

    /// How long before a collapse death to warn that the pet is fading.
    package static let nearingDeathLead: TimeInterval = 21_600

    // MARK: - Background Refresh

    /// How far ahead to request the next background refresh; the system grants
    /// roughly one per hour for a Dock app, so asking sooner is pointless.
    public static let backgroundRefreshInterval: TimeInterval = 3_600

    // MARK: - Feeding

    /// Weight gained from one serving of meat (grams).
    package static let meatWeightGain: Int = 1

    /// Weight gained from one vitamin (grams).
    package static let vitaminWeightGain: Int = 2

    // MARK: - Training

    /// Weight lost per completed training session (grams).
    package static let trainWeightLoss: Int = 2

    /// Rounds in one training session.
    public static let trainRounds: Int = 5

    /// Wins needed in training to count as a successful session.
    package static let trainWinsNeeded: Int = 3

    // MARK: - Conditioning (trained HP / POW)

    /// Maximum trained bonus for HP and POW.
    package static let maxConditioning: Int = 3

    /// Neglect this long (no training / no battling) drops one trained point.
    package static let conditioningDecayInterval: TimeInterval = 43_200

    /// Activity factor at or above this grants the active HP bonus.
    package static let activeHPFactorThreshold: Double = 0.5

    // MARK: - Weather

    /// How long a weather reading is cached before refetching.
    public static let weatherCacheInterval: TimeInterval = 1_800

    /// How long the step count is cached before refetching.
    public static let stepCacheInterval: TimeInterval = 600
}

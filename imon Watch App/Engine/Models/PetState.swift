import Foundation

/// The complete simulated state of one pet — the single value the engine's
/// pure `(PetState, Date) -> PetState` simulators advance. Deliberately not
/// `Codable`: saves go through the flat, versioned `PetStateDTO`, so this
/// model can be regrouped or extended without breaking stored pets.
nonisolated struct PetState: Sendable {

    // MARK: - Identity

    /// The pet's unique identity, tagged so it cannot be swapped with a bare
    /// `UUID`.
    let id: Tagged<PetState, UUID>
    /// The pet's species, setting max hearts, base weight and evolution goal.
    var species: PetSpecies

    // MARK: - Vital Stats

    /// Hunger hearts, hatched full; both stats empty is languishing (see
    /// `isLanguishing`).
    var hungerHearts: StatHearts = .empty
    /// Strength hearts, hatched full; both stats empty is languishing (see
    /// `isLanguishing`).
    var strengthHearts: StatHearts = .empty
    /// The pet's weight; `hatched` starts it at the species' base weight.
    var weight: Weight = Weight(10)
    /// The pet's age; a hatched pet starts at zero.
    var age: Int = 0
    /// Messes the pet has left — the mess that can raise a care call.
    var poopCount: Int = 0
    /// Whether the pet is asleep; sleep pauses the waking simulators (see
    /// `isAwakeAndAlive`).
    var isSleeping: Bool = false
    /// Whether the light is on; switching it off at night starts the settle
    /// (see `lightsOffAt`).
    var lightsOn: Bool = true

    // MARK: - Health

    /// Whether the pet is injured — an injury is a care call (see
    /// `injuredAt`).
    var isInjured: Bool = false
    /// Running total of injuries the pet has suffered.
    var injuryCount: Int = 0
    /// Neglect count; steers evolution but never kills.
    var careMistakes: Int = 0

    // MARK: - Records

    /// Battles won; winning earns the decaying bonus power tracked by
    /// `trainedPower`.
    var battleWins: Int = 0
    /// Battles lost; with `battleWins`, the pet's lifetime battle record.
    var battleLosses: Int = 0
    /// Trainings completed; training earns the decaying bonus HP tracked by
    /// `trainedHP`.
    var trainingCount: Int = 0

    // MARK: - Conditioning (trained combat bonuses, earned and lost through play)

    /// Bonus battle HP earned by training; decays toward zero when idle.
    var trainedHP: Int = 0
    /// Bonus battle power earned by winning; decays toward zero when idle.
    var trainedPower: Int = 0

    // MARK: - Fitness (step-driven growth)

    /// Lifetime steps credited toward evolution (only ever grows).
    var lifetimeActiveSteps: Int = 0
    /// Today's steps already folded into `lifetimeActiveSteps`.
    var stepsCreditedToday: Int = 0
    /// The calendar day `stepsCreditedToday` belongs to; `nil` until first credit.
    var stepTrackedDay: Date?
    /// Extra steps added to the current stage's evolution goal by lazy days;
    /// reset to zero on each evolution.
    var evolutionGoalPenalty: Int = 0

    // MARK: - Lifecycle

    /// Whether the pet is dead — the end state of the collapse countdown.
    var isDead: Bool = false
    /// Whether the pet is an egg; eggs fail the `isAwakeAndAlive` interaction
    /// gate.
    var isEgg: Bool = false

    /// Last-known night state, for detecting dusk/dawn transitions.
    var wasNight: Bool = false

    // MARK: - Timestamps

    /// Every event timestamp and simulator anchor for the pet; see
    /// `Timestamps`.
    var timestamps: Timestamps
}

// MARK: - Timestamps

extension PetState {

    /// Every event timestamp for the pet, grouped together. Anchors are
    /// non-optional; one-off / pending events are optional.
    nonisolated struct Timestamps: Sendable {
        /// When the pet was born — fixed at creation.
        var bornAt: Date
        /// When the pet was last fed.
        var lastFedAt: Date
        /// When the pet last trained.
        var lastTrainedAt: Date
        /// The poop anchor — when the pet last pooped.
        var lastPoopAt: Date
        /// Hunger decay anchor — the hunger simulator counts whole intervals
        /// from here.
        var lastHungerDecayAt: Date
        /// Strength decay anchor — the strength simulator counts whole
        /// intervals from here.
        var lastStrengthDecayAt: Date
        /// When the pet last evolved; equals `bornAt` until the first
        /// evolution.
        var evolvedAt: Date
        /// When the state was last advanced — the previous tick's reference
        /// date.
        var lastAdvancedAt: Date
        /// When the pet last battled.
        var lastBattledAt: Date
        /// When the current injury happened; nil while the pet is uninjured.
        var injuredAt: Date?
        /// The start of an unanswered care call; nil while no call is pending.
        /// A care call left unanswered converts into a care mistake.
        var pendingCareMistakeAt: Date?
        /// The lights counterpart of `pendingCareMistakeAt`; nil while nothing
        /// is pending.
        var pendingLightsMistakeAt: Date?
        /// When the light was switched off at night — starts the settle.
        var lightsOffAt: Date?
        /// When languishing began — starts the collapse countdown toward death;
        /// cleared on recovery.
        var collapsingAt: Date?
        /// The moment each stat ran out, non-nil only while it is empty. The
        /// decay anchors keep advancing past empty, so the emptying moment
        /// cannot be recovered later — it is recorded as it happens, and gives
        /// `collapsingAt` its true start.
        var hungerEmptiedAt: Date?
        /// When strength ran out; non-nil only while strength is empty (see
        /// `hungerEmptiedAt`).
        var strengthEmptiedAt: Date?

        /// A freshly created pet: every anchor starts at `date`, with no
        /// pending events outstanding.
        init(creating date: Date) {
            bornAt = date
            lastFedAt = date
            lastTrainedAt = date
            lastPoopAt = date
            lastHungerDecayAt = date
            lastStrengthDecayAt = date
            evolvedAt = date
            lastAdvancedAt = date
            lastBattledAt = date
            injuredAt = nil
            pendingCareMistakeAt = nil
            pendingLightsMistakeAt = nil
            lightsOffAt = nil
            collapsingAt = nil
            hungerEmptiedAt = nil
            strengthEmptiedAt = nil
        }

        /// Creates a fully specified timestamp set; handwritten because the
        /// `init(creating:)` above suppresses the synthesised memberwise init.
        init(
            bornAt: Date,
            lastFedAt: Date,
            lastTrainedAt: Date,
            lastPoopAt: Date,
            lastHungerDecayAt: Date,
            lastStrengthDecayAt: Date,
            evolvedAt: Date,
            lastAdvancedAt: Date,
            lastBattledAt: Date,
            injuredAt: Date?,
            pendingCareMistakeAt: Date?,
            pendingLightsMistakeAt: Date?,
            lightsOffAt: Date?,
            collapsingAt: Date?,
            hungerEmptiedAt: Date? = nil,
            strengthEmptiedAt: Date? = nil
        ) {
            self.bornAt = bornAt
            self.lastFedAt = lastFedAt
            self.lastTrainedAt = lastTrainedAt
            self.lastPoopAt = lastPoopAt
            self.lastHungerDecayAt = lastHungerDecayAt
            self.lastStrengthDecayAt = lastStrengthDecayAt
            self.evolvedAt = evolvedAt
            self.lastAdvancedAt = lastAdvancedAt
            self.lastBattledAt = lastBattledAt
            self.injuredAt = injuredAt
            self.pendingCareMistakeAt = pendingCareMistakeAt
            self.pendingLightsMistakeAt = pendingLightsMistakeAt
            self.lightsOffAt = lightsOffAt
            self.collapsingAt = collapsingAt
            self.hungerEmptiedAt = hungerEmptiedAt
            self.strengthEmptiedAt = strengthEmptiedAt
        }
    }
}

// MARK: - Factory

nonisolated extension PetState {

    /// Creates a new Dotkin pet with full hearts and base weight.
    static func hatched(at date: Date = .now) -> PetState {
        let species = PetSpecies.dotkin
        return PetState(
            id: Tagged(rawValue: UUID()),
            species: species,
            hungerHearts: StatHearts(species.maxHunger),
            strengthHearts: StatHearts(species.maxStrength),
            weight: Weight(species.baseWeight),
            timestamps: Timestamps(creating: date)
        )
    }
}

// MARK: - Conditioning

nonisolated extension PetState {
    /// Whether the pet can build trained HP/POW. The Fresh runt (Dotkin) cannot.
    var canCondition: Bool { species != .dotkin }

    /// Hatched, alive, and awake — the gate for interactions and the waking
    /// simulators (hunger, strength, poop, injury).
    var isAwakeAndAlive: Bool { !isDead && !isEgg && !isSleeping }

    /// Both stats are empty — the pet is languishing and the collapse countdown
    /// toward death is running. Drives the on-screen weak look and Call sign.
    var isLanguishing: Bool {
        hungerHearts.isEmpty && strengthHearts.isEmpty
    }

    /// Lifetime steps needed to leave the current stage, including any lazy-day
    /// penalty. Guards the `Int.max` ultimate sentinel against overflow.
    var evolutionGoal: Int {
        let base = species.stage.stepsToEvolve
        guard base < Int.max - evolutionGoalPenalty else { return base }
        return base + evolutionGoalPenalty
    }

    /// Progress toward the next evolution as a 0...1 fraction, for the bezel ring.
    /// The final (ultimate) stage reads as a full ring.
    var evolutionProgressFraction: Double {
        guard species.stage != .ultimate else { return 1 }
        let goal = evolutionGoal
        guard goal > 0 else { return 0 }
        return min(1, max(0, Double(lifetimeActiveSteps) / Double(goal)))
    }
}

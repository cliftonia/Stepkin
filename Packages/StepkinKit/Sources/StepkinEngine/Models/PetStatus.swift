import Foundation

/// A read-only snapshot of `PetState` for presentation: values flattened to
/// display units and attention flags precomputed at construction, so views
/// render from a frozen moment rather than reaching into live engine state.
public struct PetStatus: Sendable {
    /// The pet's species, stored on the source `PetState`.
    public let species: PetSpecies
    /// The evolution stage, read from `species` at snapshot time.
    public let stage: EvolutionStage
    /// Hunger in hearts; empty hearts raise `needsAttention`.
    public let hungerHearts: StatHearts
    /// Strength in hearts; empty hearts raise `needsAttention`.
    public let strengthHearts: StatHearts
    /// Weight flattened to whole grams for display.
    public let weightGrams: Int
    /// The age counter in whole days, stored on the source `PetState`.
    public let ageDays: Int
    /// Poops present; any poop raises `needsAttention`.
    public let poopCount: Int
    /// Whether the pet is asleep at snapshot time.
    public let isSleeping: Bool
    /// Whether the light is on at snapshot time.
    public let lightsOn: Bool
    /// Whether the pet is injured; injury raises `needsAttention`.
    public let isInjured: Bool
    /// Whether the pet is dead at snapshot time.
    public let isDead: Bool
    /// Whether the pet is still an egg at snapshot time.
    public let isEgg: Bool
    /// Whether the pet is languishing, as computed on the source `PetState`.
    public let isLanguishing: Bool
    /// The battle-win tally, stored on the source `PetState`.
    public let battleWins: Int
    /// The battle-loss tally, stored on the source `PetState`.
    public let battleLosses: Int

    /// Whether the pet droops on screen: languishing and awake. Asleep it
    /// still rests, like the toy.
    public let isDrooping: Bool
    /// Whether a mess needs clearing: any poop is present or the pet is injured.
    public let hasCareMess: Bool

    /// The care-call flag — true while hunger or strength hearts are
    /// empty, any poop is present, or the pet is injured.
    public let needsAttention: Bool

    /// Creates a snapshot from one `PetState`, computing the care-call flag
    /// from the same values the snapshot carries so the two cannot drift.
    public init(from state: PetState) {
        species = state.species
        stage = state.species.stage
        hungerHearts = state.hungerHearts
        strengthHearts = state.strengthHearts
        weightGrams = state.weight.grams
        ageDays = state.age
        poopCount = state.poopCount
        isSleeping = state.isSleeping
        lightsOn = state.lightsOn
        isInjured = state.isInjured
        isDead = state.isDead
        isEgg = state.isEgg
        isLanguishing = state.isLanguishing
        battleWins = state.battleWins
        battleLosses = state.battleLosses
        isDrooping = state.isLanguishing && !state.isSleeping
        hasCareMess = state.poopCount > 0 || state.isInjured
        needsAttention = state.hungerHearts.isEmpty
            || state.strengthHearts.isEmpty
            || state.poopCount > 0
            || state.isInjured
    }
}

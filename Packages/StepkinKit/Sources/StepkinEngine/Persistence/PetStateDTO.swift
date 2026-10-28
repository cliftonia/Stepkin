import Foundation
import StepkinCore

/// On-disk representation of `PetState`.
///
/// Deliberately **flat and stable** so the domain model can be regrouped or
/// extended without breaking saved pets — only the mapping below changes.
/// `schemaVersion` is optional so pre-versioning saves still decode (nil = v1),
/// and is the hook for future migrations.
struct PetStateDTO: Codable, Sendable {

    /// The version `init(from:)` writes into `schemaVersion`.
    static let currentVersion = 3

    /// Save format version; nil in pre-versioning saves, which decode as v1.
    var schemaVersion: Int?

    /// Identity of the pet whose state this stores.
    var id: Tagged<PetState, UUID>
    /// The pet's species.
    var species: PetSpecies

    /// Hunger hearts; both this and `strengthHearts` empty is languishing.
    var hungerHearts: StatHearts
    /// Strength hearts; both this and `hungerHearts` empty is languishing.
    var strengthHearts: StatHearts
    /// The pet's weight.
    var weight: Weight
    /// The pet's age.
    var age: Int
    /// Unscooped mess; one of the things a care call asks for.
    var poopCount: Int
    /// Whether the pet is asleep — from the settle until the next wake.
    var isSleeping: Bool
    /// Whether the light is on; the light going out starts the settle.
    var lightsOn: Bool

    /// Whether the pet is injured; injury is one of the care calls.
    var isInjured: Bool
    /// Injuries the pet has had.
    var injuryCount: Int
    /// Care mistakes so far; they steer evolution but never kill.
    var careMistakes: Int

    /// Running tally of battles won.
    var battleWins: Int
    /// Running tally of battles lost.
    var battleLosses: Int
    /// Running tally of training sessions.
    var trainingCount: Int

    /// Extra HP from training. Nil in older saves, defaulted to 0 on load.
    var trainedHP: Int?
    /// Extra power from training. Nil in older saves, defaulted to 0 on load.
    var trainedPower: Int?

    /// The lifetime steps accumulator for evolution, credited per day at
    /// rollover. Nil in older saves, defaulted to 0 on load.
    var lifetimeActiveSteps: Int?
    /// Steps credited on `stepTrackedDay`; the per-day side of rollover. Nil
    /// in older saves, defaulted to 0 on load.
    var stepsCreditedToday: Int?
    /// The calendar day `stepsCreditedToday` belongs to; stays nil in older saves.
    var stepTrackedDay: Date?
    /// Lazy-day penalty raising the evolution goal. Nil in older saves,
    /// defaulted to 0 on load.
    var evolutionGoalPenalty: Int?

    /// Whether the pet has died — the end of the collapse countdown.
    var isDead: Bool
    /// Whether the pet is still an egg.
    var isEgg: Bool
    /// The night signal from the previous tick. Nil in older saves, defaulted
    /// to false on load.
    var wasNight: Bool?

    /// When the pet was born; doubles as the `lastBattledAt` fallback for
    /// older saves.
    var bornAt: Date
    /// When the pet was last fed.
    var lastFedAt: Date
    /// When the pet last trained.
    var lastTrainedAt: Date
    /// Anchor the poop simulator counts whole intervals from; re-anchored on
    /// wake.
    var lastPoopAt: Date
    /// Anchor the hunger decay counts whole intervals from; re-anchored on
    /// wake.
    var lastHungerDecayAt: Date
    /// Anchor the strength decay counts whole intervals from; re-anchored on
    /// wake.
    var lastStrengthDecayAt: Date
    /// When the pet last evolved.
    var evolvedAt: Date
    /// When the current injury began; nil while uninjured and in older saves.
    var injuredAt: Date?
    /// When the open care call started; unanswered for 20 min it becomes
    /// a care mistake. Nil with no care call open, and in older saves.
    var pendingCareMistakeAt: Date?
    /// When the light was left on into bedtime, counting toward a care
    /// mistake. Nil with no lights mistake pending, and in older saves.
    var pendingLightsMistakeAt: Date?
    /// When the light went out, starting the settle. Nil while the light is
    /// on, and in older saves.
    var lightsOffAt: Date?
    /// When the pet became languishing, starting the 48 h collapse countdown.
    /// Nil while hunger or strength holds, and in older saves.
    var collapsingAt: Date?
    /// When the last hunger heart emptied. Nil while any hunger heart
    /// remains, and in older saves.
    var hungerEmptiedAt: Date?
    /// When the last strength heart emptied. Nil while any strength heart
    /// remains, and in older saves.
    var strengthEmptiedAt: Date?
    /// Timestamp of the last tick; a long gap turns the next tick into a
    /// catch-up.
    var lastAdvancedAt: Date
    /// When the pet last battled. Nil in older saves, defaulted to `bornAt`
    /// on load.
    var lastBattledAt: Date?
}

// MARK: - Mapping

extension PetStateDTO {
    /// Creates the stored form of a `PetState`, stamping `schemaVersion` with
    /// `Self.currentVersion` and flattening `PetState.timestamps` into fields.
    init(from state: PetState) {
        let times = state.timestamps
        schemaVersion = Self.currentVersion
        id = state.id
        species = state.species
        hungerHearts = state.hungerHearts
        strengthHearts = state.strengthHearts
        weight = state.weight
        age = state.age
        poopCount = state.poopCount
        isSleeping = state.isSleeping
        lightsOn = state.lightsOn
        isInjured = state.isInjured
        injuryCount = state.injuryCount
        careMistakes = state.careMistakes
        battleWins = state.battleWins
        battleLosses = state.battleLosses
        trainingCount = state.trainingCount
        trainedHP = state.trainedHP
        trainedPower = state.trainedPower
        lifetimeActiveSteps = state.lifetimeActiveSteps
        stepsCreditedToday = state.stepsCreditedToday
        stepTrackedDay = state.stepTrackedDay
        evolutionGoalPenalty = state.evolutionGoalPenalty
        isDead = state.isDead
        isEgg = state.isEgg
        wasNight = state.wasNight
        bornAt = times.bornAt
        lastFedAt = times.lastFedAt
        lastTrainedAt = times.lastTrainedAt
        lastPoopAt = times.lastPoopAt
        lastHungerDecayAt = times.lastHungerDecayAt
        lastStrengthDecayAt = times.lastStrengthDecayAt
        evolvedAt = times.evolvedAt
        injuredAt = times.injuredAt
        pendingCareMistakeAt = times.pendingCareMistakeAt
        pendingLightsMistakeAt = times.pendingLightsMistakeAt
        lightsOffAt = times.lightsOffAt
        collapsingAt = times.collapsingAt
        hungerEmptiedAt = times.hungerEmptiedAt
        strengthEmptiedAt = times.strengthEmptiedAt
        lastAdvancedAt = times.lastAdvancedAt
        lastBattledAt = times.lastBattledAt
    }
}

extension PetState {
    /// Rebuilds a domain `PetState` from its stored form; fields absent from
    /// older saves decode as nil and are defaulted here — numeric fields to 0,
    /// `wasNight` to `false`, `lastBattledAt` to `bornAt`.
    init(from dto: PetStateDTO) {
        self.init(
            id: dto.id,
            species: dto.species,
            hungerHearts: dto.hungerHearts,
            strengthHearts: dto.strengthHearts,
            weight: dto.weight,
            age: dto.age,
            poopCount: dto.poopCount,
            isSleeping: dto.isSleeping,
            lightsOn: dto.lightsOn,
            isInjured: dto.isInjured,
            injuryCount: dto.injuryCount,
            careMistakes: dto.careMistakes,
            battleWins: dto.battleWins,
            battleLosses: dto.battleLosses,
            trainingCount: dto.trainingCount,
            trainedHP: dto.trainedHP ?? 0,
            trainedPower: dto.trainedPower ?? 0,
            lifetimeActiveSteps: dto.lifetimeActiveSteps ?? 0,
            stepsCreditedToday: dto.stepsCreditedToday ?? 0,
            stepTrackedDay: dto.stepTrackedDay,
            evolutionGoalPenalty: dto.evolutionGoalPenalty ?? 0,
            isDead: dto.isDead,
            isEgg: dto.isEgg,
            wasNight: dto.wasNight ?? false,
            timestamps: PetState.Timestamps(
                bornAt: dto.bornAt,
                lastFedAt: dto.lastFedAt,
                lastTrainedAt: dto.lastTrainedAt,
                lastPoopAt: dto.lastPoopAt,
                lastHungerDecayAt: dto.lastHungerDecayAt,
                lastStrengthDecayAt: dto.lastStrengthDecayAt,
                evolvedAt: dto.evolvedAt,
                lastAdvancedAt: dto.lastAdvancedAt,
                lastBattledAt: dto.lastBattledAt ?? dto.bornAt,
                injuredAt: dto.injuredAt,
                pendingCareMistakeAt: dto.pendingCareMistakeAt,
                pendingLightsMistakeAt: dto.pendingLightsMistakeAt,
                lightsOffAt: dto.lightsOffAt,
                collapsingAt: dto.collapsingAt,
                hungerEmptiedAt: dto.hungerEmptiedAt,
                strengthEmptiedAt: dto.strengthEmptiedAt
            )
        )
    }
}

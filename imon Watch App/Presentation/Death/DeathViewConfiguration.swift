/// The death screen's display values, fixed at the moment the pet died.
nonisolated struct DeathViewConfiguration: Hashable, Sendable {
    /// The species name shown on the grave.
    let speciesName: String
    /// The pet's age in whole days at death.
    let ageDays: Int
}

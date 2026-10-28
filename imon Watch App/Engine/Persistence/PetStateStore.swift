import Foundation
import os

/// The persistence boundary as a witness. Three closures a test can stub
/// individually, with the production wiring supplied by
/// `JSONPetStateStore.live`. `load` returns `nil` when no save exists;
/// throwing is reserved for a save that exists but cannot be decoded.
nonisolated struct PetStateStore: Sendable {
    /// Persists the pet's state.
    let save: @Sendable (PetState) throws -> Void
    /// Returns the saved pet state, or nil when no save exists. Throws only
    /// when a save exists but cannot be decoded.
    let load: @Sendable () throws -> PetState?
    /// Removes the saved pet state.
    let delete: @Sendable () throws -> Void
}

nonisolated extension PetStateStore {
    /// Saves the pet, logging a failure to `logger` instead of throwing, so a
    /// failed save never takes the caller down with it.
    func save(_ state: PetState, loggingTo logger: Logger) {
        do {
            try save(state)
        } catch {
            logger.error("Save failed: \(error, privacy: .public)")
        }
    }
}

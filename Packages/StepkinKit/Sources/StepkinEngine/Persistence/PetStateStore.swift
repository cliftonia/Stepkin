import Foundation
import os

/// The persistence boundary as a witness. Three closures a test can stub
/// individually, with the production wiring supplied by
/// `JSONPetStateStore.live`. `load` returns `nil` when no save exists;
/// throwing is reserved for a save that exists but cannot be decoded.
public struct PetStateStore: Sendable {
    /// Persists the pet's state.
    public let save: @Sendable (PetState) throws -> Void
    /// Returns the saved pet state, or nil when no save exists. Throws only
    /// when a save exists but cannot be decoded.
    public let load: @Sendable () throws -> PetState?
    /// Removes the saved pet state.
    public let delete: @Sendable () throws -> Void

    /// Creates a store from its three closures; production wiring comes from
    /// `JSONPetStateStore.live`, tests stub each closure.
    public init(
        save: @escaping @Sendable (PetState) throws -> Void,
        load: @escaping @Sendable () throws -> PetState?,
        delete: @escaping @Sendable () throws -> Void
    ) {
        self.save = save
        self.load = load
        self.delete = delete
    }
}

extension PetStateStore {
    /// Saves the pet, logging a failure to `logger` instead of throwing, so a
    /// failed save never takes the caller down with it.
    public func save(_ state: PetState, loggingTo logger: Logger) {
        do {
            try save(state)
        } catch {
            logger.error("Save failed: \(error, privacy: .public)")
        }
    }
}

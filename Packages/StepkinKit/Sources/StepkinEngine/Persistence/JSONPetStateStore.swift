import Foundation
import StepkinCore
import os

/// Builds the production `PetStateStore` witness: the pet serialised through
/// the versioned `PetStateDTO` into a single JSON blob in `UserDefaults` — a
/// save measured in hundreds of bytes, so a file store would add only failure
/// modes.
public enum JSONPetStateStore {

    /// The `UserDefaults` key holding the current JSON save.
    static let key = "com.cliftonia.imon.petState"
    /// The previous good save, kept so one torn or undecodable write cannot
    /// cost a months-old pet. Do not rename either key: both are on wrists.
    static let backupKey = "com.cliftonia.imon.petState.backup"

    // MARK: - Live

    /// Creates the store on `.standard` so persistence never depends on the
    /// App Group being provisioned. Only the complication hand-off needs the
    /// shared suite (`ComplicationStore`), and it degrades gracefully if that
    /// suite is missing.
    public static func live(
        defaults: UserDefaults = .standard
    ) -> PetStateStore {
        let box = DefaultsBox(defaults: defaults)
        return PetStateStore(
            save: { state in
                let defaults = box.defaults
                let data = try JSONEncoder().encode(PetStateDTO(from: state))
                if let previous = defaults.data(forKey: key) {
                    defaults.set(previous, forKey: backupKey)
                }
                defaults.set(data, forKey: key)
            },
            load: {
                let defaults = box.defaults
                guard let data = defaults.data(forKey: key) else {
                    return nil
                }
                do {
                    return PetState(from: try JSONDecoder().decode(PetStateDTO.self, from: data))
                } catch {
                    // The backup is one save behind; the engine's catch-up closes the gap.
                    guard let backup = defaults.data(forKey: backupKey) else { throw error }
                    Log.engine.error("Save undecodable; restoring backup: \(error, privacy: .public)")
                    return PetState(from: try JSONDecoder().decode(PetStateDTO.self, from: backup))
                }
            },
            delete: {
                let defaults = box.defaults
                defaults.removeObject(forKey: key)
                defaults.removeObject(forKey: backupKey)
            }
        )
    }

    /// Carries the suite into the store's `@Sendable` closures. `UserDefaults`
    /// is documented thread-safe but not marked `Sendable`, so the box vouches
    /// for it.
    private struct DefaultsBox: @unchecked Sendable {
        /// The suite the store reads and writes.
        let defaults: UserDefaults
    }
}

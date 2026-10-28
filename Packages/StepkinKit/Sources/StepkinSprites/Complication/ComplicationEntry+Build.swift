import Foundation
import StepkinEngine

/// Sprite-side builder: turns a `PetState` into a `ComplicationEntry`, baking the
/// current sprite rows. Lives in StepkinSprites because it touches
/// `SpriteCatalog`; the display values and mood word come from the engine's
/// `init(date:state:spriteRows:)`.
extension ComplicationEntry {

    /// Creates an entry from a state snapshot, baking the first frame of the
    /// sleep or idle sprite; a missing frame set bakes as blank rows.
    public init(date: Date, state: PetState) {
        self.init(date: date, state: state, spriteRows: Self.spriteRows(for: state))
    }

    /// The first frame of the pet's sleep or idle sprite, one `UInt16` per row;
    /// blank rows when the species has no frames for that animation.
    public static func spriteRows(for state: PetState) -> [UInt16] {
        let kind: SpriteCatalog.AnimationKind = state.isSleeping ? .sleep : .idle
        return SpriteCatalog.frames(for: state.species, kind: kind).first?.rows
            ?? [UInt16](repeating: 0, count: 16)
    }
}

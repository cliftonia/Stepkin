import Foundation
import StepkinEngine

/// Sprite-side timeline overload: bakes each projected entry with the catalog's
/// sprite rows, so callers keep the short call shape while the engine stays
/// free of bitmaps.
extension ComplicationTimeline {

    /// Returns future projections spaced `stride` seconds apart, starting at
    /// `now`, each baked with `ComplicationEntry.spriteRows(for:)`. `count` is
    /// clamped to a minimum of one by the engine's timeline.
    public static func entries(
        for state: PetState,
        from now: Date,
        count: Int = 8,
        stride: TimeInterval = 1_800
    ) -> [ComplicationEntry] {
        entries(for: state, from: now, count: count, stride: stride, spriteRows: ComplicationEntry.spriteRows(for:))
    }
}

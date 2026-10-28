import Foundation

/// Projects a deterministic timeline of complication snapshots from the saved
/// pet, advancing the engine to each future point so the face shows hunger
/// draining over the next few hours without a live refresh.
public enum ComplicationTimeline {

    /// Returns future projections spaced `stride` seconds apart, starting at
    /// `now`. `count` is clamped to a minimum of one, so an entry at `now`
    /// itself is always produced. `spriteRows` supplies the rows baked for each
    /// projected state, keeping the sprite stack out of the engine.
    public static func entries(
        for state: PetState,
        from now: Date,
        count: Int = 8,
        stride: TimeInterval = 1_800,
        spriteRows: (PetState) -> [UInt16]
    ) -> [ComplicationEntry] {
        // A finished pet (dead/egg) has nothing to project.
        guard !state.isDead, !state.isEgg else {
            return [ComplicationEntry(date: now, state: state, spriteRows: spriteRows(state))]
        }

        return (0..<max(1, count)).map { index in
            let date = now.addingTimeInterval(Double(index) * stride)
            let projected = GameEngine.advance(state, to: date, isNight: nil, steps: .unavailable, calendar: .current)
            return ComplicationEntry(date: date, state: projected, spriteRows: spriteRows(projected))
        }
    }
}

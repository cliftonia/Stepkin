import Foundation
import StepkinCore

/// Decays the trained HP / POW bonuses toward zero when the pet stops training
/// or battling. One point is lost per `conditioningDecayInterval`, counted from
/// the `lastTrainedAt` (HP) and `lastBattledAt` (POW) anchors. The bonus floors
/// at zero, so effective HP / power never drops below the species base.
enum ConditioningSimulator {

    /// Decays both trained bonuses from their anchors up to `now`. Dead pets
    /// and eggs are returned unchanged.
    static func apply(to state: PetState, at now: Date) -> PetState {
        var state = state
        guard !state.isDead, !state.isEgg else { return state }

        state.trainedHP = decay(
            bonus: state.trainedHP,
            anchor: &state.timestamps.lastTrainedAt,
            to: now
        )
        state.trainedPower = decay(
            bonus: state.trainedPower,
            anchor: &state.timestamps.lastBattledAt,
            to: now
        )
        return state
    }

    /// Reduces `bonus` by one per whole elapsed interval since `anchor`,
    /// advancing the anchor by only the points consumed, so it never passes `now`.
    private static func decay(
        bonus: Int,
        anchor: inout Date,
        to now: Date
    ) -> Int {
        guard bonus > 0 else { return bonus }
        let interval = TimeConstants.conditioningDecayInterval
        let ticks = TickMath.ticks(from: anchor, to: now, interval: interval)
        guard ticks > 0 else { return bonus }

        let lost = min(bonus, ticks)
        anchor = anchor.addingTimeInterval(Double(lost) * interval)
        return bonus - lost
    }
}

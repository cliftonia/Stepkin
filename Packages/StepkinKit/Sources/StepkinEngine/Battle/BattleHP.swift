import Foundation
import StepkinCore

/// Battle stamina: species base HP, +1 while the `ActivityModel` factor for
/// today's steps clears the `TimeConstants` threshold, plus HP earned
/// through training. A pure operation namespace — every input arrives as a
/// parameter, so nothing can fall out of sync.
public enum BattleHP {

    /// `steps` is today's running count; `nil` (steps disabled or unavailable)
    /// forgoes the active +1 bonus.
    public static func calculate(for state: PetState, steps: Int? = nil) -> Int {
        let base = state.species.baseHP
        let activeBonus = (steps.map { ActivityModel.factor(steps: $0) >= TimeConstants.activeHPFactorThreshold } ?? false) ? 1 : 0
        return base + activeBonus + state.trainedHP
    }

    /// Renders `hp` filled hearts followed by empties up to `maxHP`; an `hp`
    /// above `maxHP` is allowed and just lengthens the string.
    public static func heartsString(hp: Int, maxHP: Int) -> String {
        String(repeating: "\u{2665}", count: hp)
            + String(
                repeating: "\u{2661}",
                count: max(0, maxHP - hp)
            )
    }
}

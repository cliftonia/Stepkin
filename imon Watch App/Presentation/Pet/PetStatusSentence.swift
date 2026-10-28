import Foundation

/// The one spoken sentence for a pet's condition, shared by VoiceOver on the
/// home screen and by the Siri check intent so the two never drift.
nonisolated enum PetStatusSentence {

    /// Describes `status` in one comma-separated sentence. `menu`, when given,
    /// appends the highlighted menu entry (VoiceOver only; Siri has no menu).
    static func describe(_ status: PetStatus, includeMenu menu: String? = nil) -> String {
        var parts = ["\(status.species.displayName), \(status.stage.displayName)"]
        if status.isDead {
            parts.append(String(localized: "has passed away", comment: "Spoken pet status: the pet has died."))
        } else {
            let hunger = status.hungerHearts.value
            let maxHunger = status.species.maxHunger
            parts.append(String(localized: "hunger \(hunger) of \(maxHunger)", comment: "Spoken pet status: full hunger hearts of the maximum."))
            let strength = status.strengthHearts.value
            let maxStrength = status.species.maxStrength
            parts.append(
                String(localized: "strength \(strength) of \(maxStrength)", comment: "Spoken pet status: full strength hearts of the maximum.")
            )
            parts += conditions(of: status)
        }
        if let menu { parts.append(String(localized: "menu: \(menu)", comment: "Spoken pet status: the highlighted menu entry.")) }
        return parts.joined(separator: ", ")
    }

    /// The attention phrases, in the order they are spoken.
    private static func conditions(of status: PetStatus) -> [String] {
        var parts: [String] = []
        if status.isSleeping { parts.append(String(localized: "sleeping", comment: "Spoken pet status phrase.")) }
        if status.poopCount > 0 {
            let count = status.poopCount
            parts.append(
                count == 1
                    ? String(localized: "1 mess to clean", comment: "Spoken pet status phrase: one mess on screen.")
                    : String(localized: "\(count) messes to clean", comment: "Spoken pet status phrase: several messes on screen.")
            )
        }
        if status.isInjured { parts.append(String(localized: "injured", comment: "Spoken pet status phrase.")) }
        if status.isLanguishing { parts.append(String(localized: "needs care", comment: "Spoken pet status phrase.")) }
        return parts
    }
}

import Foundation

/// The one spoken sentence for a pet's condition, shared by VoiceOver on the
/// home screen and by the Siri check intent so the two never drift.
nonisolated enum PetStatusSentence {

    /// Describes `status` in one comma-separated sentence. `menu`, when given,
    /// appends the highlighted menu entry (VoiceOver only; Siri has no menu).
    static func describe(_ status: PetStatus, includeMenu menu: String? = nil) -> String {
        var parts = ["\(status.species.displayName), \(status.stage.displayName)"]
        if status.isDead {
            parts.append("has passed away")
        } else {
            parts.append("hunger \(status.hungerHearts.value) of \(status.species.maxHunger)")
            parts.append("strength \(status.strengthHearts.value) of \(status.species.maxStrength)")
            parts += conditions(of: status)
        }
        if let menu { parts.append("menu: \(menu)") }
        return parts.joined(separator: ", ")
    }

    /// The attention phrases, in the order they are spoken.
    private static func conditions(of status: PetStatus) -> [String] {
        var parts: [String] = []
        if status.isSleeping { parts.append("sleeping") }
        if status.poopCount > 0 {
            parts.append(status.poopCount == 1 ? "1 mess to clean" : "\(status.poopCount) messes to clean")
        }
        if status.isInjured { parts.append("injured") }
        if status.isLanguishing { parts.append("needs care") }
        return parts
    }
}

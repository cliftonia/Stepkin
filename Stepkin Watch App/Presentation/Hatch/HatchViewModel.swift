import Foundation
import Observation

/// Display state for the hatch screen; the view redraws from `phase` as the egg
/// cracks and hatches.
///
/// The hatch takes no input and runs no logic, so one stored phase is the
/// entire state — the class exists to let `@Observable` publish its change.
@Observable
final class HatchViewModel {

    /// What the view draws on the hatch screen; starts at `.egg`.
    var phase: HatchPhase = .egg

    /// The hatch's display states in the order they play out: `egg`,
    /// `cracking`, then `hatched`.
    enum HatchPhase: Sendable {
        case egg
        case cracking
        case hatched
    }
}

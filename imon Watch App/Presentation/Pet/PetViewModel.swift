import Foundation
import Observation

/// Display state for the pet screen. Holds the screen's state — mode,
/// activity, menu selection and the display values the view renders — as
/// plain mutable properties, with `@Observable` doing the change tracking.
@Observable
final class PetViewModel {

    // MARK: - Screen Mode

    /// Which flow the screen is in: normal play, or the training or battle
    /// mode. Kept as a separate axis from `Activity` — either a mode or an
    /// activity on its own blocks input (`isBusy`).
    enum ScreenMode {
        case normal
        case training
        case battle
    }

    /// The flow the screen is in; anything but `.normal` blocks input via `isBusy`.
    var screenMode: ScreenMode = .normal

    /// Day / night / inside — drives the LCD scene (sun, night sky, or room).
    var dayPhase: DayPhase = .day

    // MARK: - Pet Display

    /// The pet's state, rendered by the view; `nil` when no state has been provided yet.
    var status: PetStatus?

    /// Progress toward the next evolution (0...1) — drives the bezel ring.
    var evolutionProgress: Double = 0
    /// The moon's phase at the last refresh, shown in the night sky.
    var moonPhase: MoonPhase = .new

    // MARK: - Menu

    /// The main menu's entries. Sequential `Int` values from `stats = 0` plus
    /// `CaseIterable` let the menu be enumerated and stepped by position;
    /// `stats` is also the initial `menuSelection`.
    enum MenuAction: Int, CaseIterable {
        case stats = 0
        case feed
        case train
        case battle
        case clean
        case lights
        case heal
        case settings
    }

    /// The menu entry currently selected, stepped by `MenuAction` position.
    var menuSelection: MenuAction = .stats

    // MARK: - Activity

    /// The steps of the feeding ceremony.
    enum FeedingPhase: Equatable {
        case selecting
        case serving
        case bite(Int)
        case satisfied
    }

    /// What the pet is actively doing — the single source of truth for input
    /// blocking, the LCD scene and the animation. A refusal is its own case
    /// because it plays in the normal scene rather than a clean action booth.
    enum Activity: Equatable {
        case idle
        case feeding(FeedingPhase)
        case cleaning
        case healing
        case refusing
        /// The evolution flash — a strobe that plays in the normal scene, then
        /// reveals the new creature. Automatic: there is nothing to tap.
        case evolving
    }

    /// The ceremony currently in flight; `.idle` when none is playing.
    var activity: Activity = .idle
    /// The food chosen while the feeding ceremony is in its `selecting` step.
    var selectedFood: FeedAction.FoodKind = .meat

    /// The feeding sub-phase, when feeding — for the buttons and animation.
    var feedingPhase: FeedingPhase? {
        if case .feeding(let phase) = activity { return phase }
        return nil
    }

    /// The ceremonies that play in their own clean scene (a refusal does not).
    var isInActionScene: Bool {
        switch activity {
        case .feeding, .cleaning, .healing: return true
        case .idle, .refusing, .evolving: return false
        }
    }

    var isEvolving: Bool { activity == .evolving }

    /// True when any activity or mode is active (blocks input).
    var isBusy: Bool {
        activity != .idle
            || screenMode == .training || screenMode == .battle
    }

    // MARK: - Debug

    /// A short on-screen diagnostic shown in the debug row (e.g. notification
    /// permission status after the care-test long-press).
    var debugNotice: String = ""
}

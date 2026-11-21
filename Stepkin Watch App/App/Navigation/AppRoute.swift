import Foundation

/// Pushable destinations. Lifecycle screens (pet, hatch, death) are driven by
/// `AppPresenter.phase`, not the NavigationStack, so they are not routes.
enum AppRoute: Hashable {
    case stats
    case settings
}

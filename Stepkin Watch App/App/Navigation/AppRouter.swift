import SwiftUI

/// Owner of the `NavigationStack` path so non-View code (`AppPresenter`) can
/// push `AppRoute`s and pop back to the pet screen on phase changes.
@Observable
final class AppRouter {
    /// The `NavigationStack` binding; `navigate(to:)` appends and `popToRoot()` clears it.
    var path = NavigationPath()

    /// Pushes `route`, presenting its screen.
    func navigate(to route: AppRoute) {
        path.append(route)
    }

    /// Replaces the path so the pet screen becomes the root again.
    func popToRoot() {
        path = NavigationPath()
    }
}

import Foundation

/// The App Group shared between the watch app and its complication widget, so
/// both processes read and write the same saved pet.
public enum AppGroup {
    /// Lookup key for the shared container. Renaming it strands the saved pet.
    public static let identifier = "group.cliftonia.stepkin"
}

extension UserDefaults {
    /// The shared container, or `.standard` until the App Group entitlement is
    /// present — so persistence keeps working before the capability is enabled
    /// and upgrades to the shared suite automatically once it is.
    public static var skykinShared: UserDefaults {
        UserDefaults(suiteName: AppGroup.identifier) ?? .standard
    }
}

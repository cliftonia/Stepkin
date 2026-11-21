import Foundation

/// The legal attribution WeatherKit's terms require an app to link to wherever
/// it shows Apple Weather data. Linked from the Settings page's About section.
nonisolated enum WeatherAttribution {
    /// The page the Settings attribution link opens; nil only if the embedded string fails to
    /// parse.
    static let legalPageURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")
}

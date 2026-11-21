import WidgetKit
import SwiftUI

/// The complication extension's entry point. The bundle shape exists so the
/// extension can group several widgets under one `@main`; it currently holds
/// only `StepkinComplication`.
@main
struct StepkinComplicationBundle: WidgetBundle {
    var body: some Widget {
        StepkinComplication()
    }
}

/// The watch-face complication. Renders the timeline the app bakes into the
/// shared App Group, so the face shows the saved pet without the widget
/// process ever running the engine — see `ComplicationProvider`.
struct StepkinComplication: Widget {
    /// The widget kind placed on watch faces. Renaming it removes the complication
    /// from every face that carries it, so it keeps the original spelling.
    private static let kind = "SkykinComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Stepkin")
        .description("Your pet at a glance.")
        .supportedFamilies([
            .accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner
        ])
    }
}

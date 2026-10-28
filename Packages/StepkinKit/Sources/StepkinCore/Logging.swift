import os

/// One `os.Logger` per layer so Console filtering follows the architecture.
public enum Log {
    private static let subsystem = "com.cliftonia.stepkin"

    /// Logger for the engine layer.
    public static let engine = Logger(subsystem: subsystem, category: "engine")
    /// Logger for the presentation layer.
    public static let presentation = Logger(subsystem: subsystem, category: "presentation")
    /// Logger for the weather layer.
    public static let weather = Logger(subsystem: subsystem, category: "weather")
    /// Logger for the health layer.
    public static let health = Logger(subsystem: subsystem, category: "health")
    /// Logger for the background layer.
    public static let background = Logger(subsystem: subsystem, category: "background")
}

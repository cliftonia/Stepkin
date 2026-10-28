// swift-tools-version: 6.2
import PackageDescription

let settings: [SwiftSetting] = [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]

let package = Package(
    name: "StepkinKit",
    platforms: [.macOS(.v15), .watchOS("26.2")],
    products: [
        .library(name: "StepkinCore", targets: ["StepkinCore"]),
        .library(name: "StepkinEngine", targets: ["StepkinEngine"]),
        .library(name: "StepkinSprites", targets: ["StepkinSprites"]),
        .library(name: "StepkinTestSupport", targets: ["StepkinTestSupport"]),
    ],
    targets: [
        .target(name: "StepkinCore", swiftSettings: settings),
        .target(name: "StepkinEngine", dependencies: ["StepkinCore"], swiftSettings: settings),
        .target(name: "StepkinSprites", dependencies: ["StepkinCore", "StepkinEngine"], swiftSettings: settings),
        .target(name: "StepkinTestSupport", dependencies: ["StepkinCore", "StepkinEngine"], swiftSettings: settings),
        .testTarget(name: "StepkinCoreTests", dependencies: ["StepkinCore", "StepkinTestSupport"], swiftSettings: settings),
        .testTarget(name: "StepkinEngineTests", dependencies: ["StepkinCore", "StepkinEngine", "StepkinTestSupport"], swiftSettings: settings),
    ],
    swiftLanguageModes: [.v6]
)

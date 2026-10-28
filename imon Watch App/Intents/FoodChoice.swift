import AppIntents

/// The foods Siri can feed, mirroring `FeedAction.FoodKind` for the Shortcuts parameter.
enum FoodChoice: String, AppEnum {
    /// Meat, which refills a hunger heart.
    case meat
    /// A vitamin, which refills a strength heart.
    case vitamin

    /// How the parameter's type is named in Shortcuts.
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Food"

    /// How each case is named in Shortcuts.
    static let caseDisplayRepresentations: [FoodChoice: DisplayRepresentation] = [
        .meat: "Meat",
        .vitamin: "Vitamin"
    ]

    /// The engine's food this choice stands for.
    var kind: FeedAction.FoodKind {
        switch self {
        case .meat: .meat
        case .vitamin: .vitamin
        }
    }
}

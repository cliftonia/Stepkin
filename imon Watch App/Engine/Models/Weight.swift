import Foundation

/// The pet's weight in grams, kept inside the original device's two-digit
/// range. Every mutation saturates at the bounds, so no sequence of feeds or
/// training can push the value out of displayable range.
nonisolated struct Weight: Codable, Sendable, Hashable {

    /// The lower end of the two-digit displayable range; subtraction saturates here.
    static let minGrams = 5
    /// The upper end of the two-digit displayable range; addition saturates here.
    static let maxGrams = 99

    /// The current weight, kept within `minGrams`–`maxGrams` by every write path.
    private(set) var grams: Int

    /// Creates a weight, clamping the given grams into the two-digit range.
    init(_ grams: Int) {
        self.grams = max(Self.minGrams, min(Self.maxGrams, grams))
    }

    /// Adds grams, saturating at `maxGrams`.
    mutating func add(_ amount: Int) {
        grams = min(Self.maxGrams, grams + amount)
    }

    /// Subtracts grams, saturating at `minGrams`.
    mutating func subtract(_ amount: Int) {
        grams = max(Self.minGrams, grams - amount)
    }
}

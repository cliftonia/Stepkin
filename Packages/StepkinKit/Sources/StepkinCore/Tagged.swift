import Foundation

/// A raw value branded with a phantom type, so identifiers that share a
/// representation (two `String` IDs, say) cannot be mixed at compile time.
/// `Codable` passes the bare raw value through, so the brand never appears
/// in persisted JSON.
public struct Tagged<Phantom, RawValue>: Sendable where RawValue: Sendable {
    /// The wrapped value; `Codable` passes it through bare, without the brand.
    public let rawValue: RawValue

    /// Brands `rawValue` with the phantom type.
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension Tagged: Equatable where RawValue: Equatable {}
extension Tagged: Hashable where RawValue: Hashable {}

extension Tagged: Codable where RawValue: Codable {
    /// Creates the branded value from the bare raw value, mirroring
    /// `encode(to:)` so persisted data carries no brand.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(RawValue.self)
    }

    /// Encodes the bare raw value without the brand, mirroring
    /// `init(from:)`.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

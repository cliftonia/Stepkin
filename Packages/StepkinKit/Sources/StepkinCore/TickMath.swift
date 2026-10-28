import Foundation

/// Safe whole-interval arithmetic for the time-based simulators.
public enum TickMath {

    /// Counts the whole `interval`s between `start` and `now`. Returns 0 for
    /// a non-positive `interval`, a non-finite span, or a negative span (a
    /// backward clock); clamps at `Int.max` — on watchOS (`arm64_32`) `Int`
    /// is 32-bit, so a bare `Int(largeDouble)` can trap on device.
    public static func ticks(
        from start: Date,
        to now: Date,
        interval: TimeInterval
    ) -> Int {
        guard interval > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(start)
        guard elapsed.isFinite, elapsed > 0 else { return 0 }
        let count = (elapsed / interval).rounded(.down)
        guard count >= 1 else { return 0 }
        return count >= Double(Int.max) ? Int.max : Int(count)
    }
}

import Foundation

// MARK: - Calendar Conveniences

/// Same-day comparisons defaulting to the current calendar.
/// Engine code keeps taking a `Calendar` parameter instead of using these,
/// so its date arithmetic stays deterministic.
extension Date {

    /// Reports whether two dates fall on the same calendar day in `calendar`, so
    /// moments hours apart can match while moments across midnight do not.
    public func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }
}

import Foundation

/// Derives the Smart Stack relevance windows from a baked timeline.
enum RelevanceWindows {
    /// One interval per maximal run of consecutive entries where the pet needs care and is
    /// neither dead nor an egg. A run starts at its first entry's date and ends at the next
    /// entry's date, or an hour after the last entry when the run ends the timeline.
    static func windows(in entries: [WidgetEntry]) -> [DateInterval] {
        let sorted = entries.sorted { $0.date < $1.date }
        var result: [DateInterval] = []
        var runStart: Date?
        for entry in sorted {
            let calling = entry.needsAttention && entry.isDead != true && entry.isEgg != true
            if calling, runStart == nil { runStart = entry.date }
            if !calling, let start = runStart {
                result.append(DateInterval(start: start, end: entry.date))
                runStart = nil
            }
        }
        if let start = runStart, let last = sorted.last {
            result.append(DateInterval(start: start, end: last.date.addingTimeInterval(3_600)))
        }
        return result
    }
}

import Testing
import Foundation
@testable import Stepkin_Watch_App

@Suite("NotificationSpriteRenderer")
struct NotificationSpriteRendererTests {

    /// A render the system never took (reminders denied, a failed schedule)
    /// would otherwise stay in the temporary folder for good.
    @Test
    func `old leftover renders are removed and everything else is kept`() throws {
        let files = FileManager.default
        let folder = files.temporaryDirectory.appendingPathComponent("renderer-\(UUID().uuidString)")
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: folder) }
        let now = Date.now
        let old = folder.appendingPathComponent("stepkin-old.png")
        let fresh = folder.appendingPathComponent("stepkin-fresh.png")
        let other = folder.appendingPathComponent("other.png")
        for url in [old, fresh, other] {
            try Data().write(to: url)
        }
        let longAgo = now.addingTimeInterval(-2 * NotificationSpriteRenderer.leftoverAge)
        try files.setAttributes([.modificationDate: longAgo], ofItemAtPath: old.path)
        try files.setAttributes([.modificationDate: longAgo], ofItemAtPath: other.path)

        NotificationSpriteRenderer.removeLeftovers(now: now, in: folder)

        #expect(!files.fileExists(atPath: old.path))
        #expect(files.fileExists(atPath: fresh.path))
        #expect(files.fileExists(atPath: other.path))
    }
}

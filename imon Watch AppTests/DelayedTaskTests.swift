import Foundation
import Testing
@testable import imon_Watch_App

@Suite("DelayedTask") @MainActor struct DelayedTaskTests {
    @Test func `cancel before the delay never runs`() async throws {
        let task = DelayedTask()
        var runs = 0
        task.schedule(after: .milliseconds(10)) { runs += 1 }
        #expect(task.isPending)
        task.cancel()
        try await Task.sleep(for: .milliseconds(100))
        #expect(runs == 0)
        #expect(!task.isPending)
    }

    @Test func `scheduling twice runs the second only`() async throws {
        let task = DelayedTask()
        var firsts = 0
        var seconds = 0
        task.schedule(after: .milliseconds(10)) { firsts += 1 }
        task.schedule(after: .milliseconds(10)) { seconds += 1 }
        try await Task.sleep(for: .milliseconds(100))
        #expect(firsts == 0)
        #expect(seconds == 1)
    }

    @Test func `isPending is false after the run`() async throws {
        let task = DelayedTask()
        var runs = 0
        task.schedule(after: .milliseconds(10)) { runs += 1 }
        try await Task.sleep(for: .milliseconds(100))
        #expect(runs == 1)
        #expect(!task.isPending)
    }
}

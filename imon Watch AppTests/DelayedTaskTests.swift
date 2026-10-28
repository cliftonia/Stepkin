import Foundation
import Testing
@testable import imon_Watch_App

@Suite("DelayedTask") @MainActor struct DelayedTaskTests {
    /// Polls until `condition` holds, up to two seconds, so a loaded simulator cannot flake a positive assertion.
    private func wait(until condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(2)
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
    }

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
        try await wait { seconds == 1 }
        try await Task.sleep(for: .milliseconds(50))
        #expect(firsts == 0)
        #expect(seconds == 1)
    }

    @Test func `a replaced short wait neither runs nor clears the longer pending one`() async throws {
        let task = DelayedTask()
        var firsts = 0
        var seconds = 0
        task.schedule(after: .milliseconds(10)) { firsts += 1 }
        task.schedule(after: .milliseconds(300)) { seconds += 1 }
        try await Task.sleep(for: .milliseconds(60))
        #expect(task.isPending)
        #expect(firsts == 0 && seconds == 0)
        try await wait { !task.isPending }
        #expect(firsts == 0)
        #expect(seconds == 1)
    }

    @Test func `isPending is false after the run`() async throws {
        let task = DelayedTask()
        var runs = 0
        task.schedule(after: .milliseconds(10)) { runs += 1 }
        try await wait { runs == 1 }
        #expect(runs == 1)
        #expect(!task.isPending)
    }
}

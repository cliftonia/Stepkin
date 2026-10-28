import Foundation
import Testing
@testable import StepkinCore

@Suite("MainActorTimer") @MainActor struct MainActorTimerTests {
    @Test func `start marks running and stop clears it`() {
        let timer = MainActorTimer()
        timer.start(interval: 60, repeats: true) {}
        #expect(timer.isRunning)
        timer.stop()
        #expect(!timer.isRunning)
    }

    @Test func `a one-shot fires once and is no longer running`() async throws {
        let timer = MainActorTimer()
        var fires = 0
        timer.start(interval: 0.02, repeats: false) { fires += 1 }
        #expect(await waitUntil { fires == 1 })
        try await Task.sleep(for: .milliseconds(100))
        #expect(fires == 1)
        #expect(!timer.isRunning)
    }

    @Test func `start again replaces the pending timer`() async {
        let timer = MainActorTimer()
        var first = 0
        var second = 0
        timer.start(interval: 0.02, repeats: false) { first += 1 }
        timer.start(interval: 0.02, repeats: false) { second += 1 }
        #expect(await waitUntil { second == 1 })
        #expect(first == 0)
    }
}

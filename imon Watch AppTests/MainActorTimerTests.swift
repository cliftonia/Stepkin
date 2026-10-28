import Foundation
import Testing
@testable import imon_Watch_App

@Suite("MainActorTimer") @MainActor struct MainActorTimerTests {
    @Test func `start marks running and stop clears it`() {
        let timer = MainActorTimer()
        timer.start(interval: 60, repeats: true) {}
        #expect(timer.isRunning)
        timer.stop()
        #expect(!timer.isRunning)
    }

    @Test func `a one-shot fires once and is no longer running`() async {
        let timer = MainActorTimer()
        await confirmation(expectedCount: 1) { fired in
            timer.start(interval: 0.02, repeats: false) { fired() }
            try? await Task.sleep(for: .milliseconds(120))
        }
        #expect(!timer.isRunning)
    }

    @Test func `start again replaces the pending timer`() async {
        let timer = MainActorTimer()
        var first = 0
        var second = 0
        timer.start(interval: 0.02, repeats: false) { first += 1 }
        timer.start(interval: 0.02, repeats: false) { second += 1 }
        try? await Task.sleep(for: .milliseconds(120))
        #expect(first == 0 && second == 1)
    }
}

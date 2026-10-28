import Foundation
import Testing
@testable import imon_Watch_App

/// Covers the wander controller's stop, pause and band guarantees.
@MainActor
struct WanderControllerTests {

    /// Attempts until a walk begins; the 0.6 chance makes a single attempt unreliable.
    private func beginWalk(_ controller: WanderController) -> Bool {
        for _ in 0..<50 {
            controller.tryStartWalking()
            if controller.isWalking { return true }
        }
        return false
    }

    /// Drives the current walk to its end, returning the offset after each step.
    private func finishWalk(_ controller: WanderController) -> [Int] {
        var offsets: [Int] = []
        while controller.isWalking {
            controller.step()
            offsets.append(controller.offsetX)
        }
        return offsets
    }

    @Test
    func `stop resets the offset and arms no timer`() {
        let controller = WanderController(offsetX: 5)
        controller.start()
        #expect(beginWalk(controller))
        controller.step()

        controller.stop()

        #expect(controller.offsetX == 8)
        #expect(!controller.isWalking)
        #expect(!controller.isScheduled)
    }

    @Test
    func `a paused controller never walks`() async throws {
        let controller = WanderController()
        controller.shouldPause = { true }
        controller.start()
        for _ in 0..<20 {
            controller.tryStartWalking()
        }

        try await Task.sleep(for: .milliseconds(50))

        #expect(!controller.isWalking)
        controller.stop()
    }

    @Test
    func `a walk from the left edge is forced right`() {
        let controller = WanderController(offsetX: 3)
        controller.start()
        #expect(beginWalk(controller))

        controller.step()

        #expect(controller.offsetX == 4)
        controller.stop()
    }

    @Test
    func `a walk from the right edge is forced left`() {
        let controller = WanderController(offsetX: 8)
        controller.start()
        #expect(beginWalk(controller))

        controller.step()

        #expect(controller.offsetX == 7)
        controller.stop()
    }

    @Test
    func `every driven step stays inside the band`() {
        let controller = WanderController(offsetX: 5)
        controller.start()
        var observed: [Int] = []
        for _ in 0..<300 {
            #expect(beginWalk(controller))
            observed += finishWalk(controller)
        }
        controller.stop()

        #expect(observed.count > 300)
        #expect(observed.allSatisfy { (2...9).contains($0) })
    }

    @Test
    func `a stale fire after stop is a no-op`() {
        let controller = WanderController(offsetX: 5)
        controller.start()
        #expect(beginWalk(controller))
        controller.stop()

        controller.step()
        controller.tryStartWalking()

        #expect(controller.offsetX == 8)
        #expect(!controller.isWalking)
        #expect(!controller.isScheduled)
    }

    @Test
    func `pausing mid-walk returns to idle`() {
        let controller = WanderController(offsetX: 5)
        var idleCount = 0
        var paused = false
        controller.shouldPause = { paused }
        controller.onIdle = { idleCount += 1 }
        controller.start()
        #expect(beginWalk(controller))
        paused = true

        controller.step()

        #expect(idleCount == 1)
        #expect(!controller.isWalking)
        controller.stop()
    }
}

import Foundation
import Testing
@testable import imon_Watch_App

/// Covers the wander controller's stop, pause and band guarantees.
@MainActor
struct WanderControllerTests {

    @Test
    func `stop resets the offset and arms no timer`() async throws {
        let controller = WanderController()
        controller.start()
        controller.tryStartWalking()
        try await Task.sleep(for: .milliseconds(400))

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
    func `a walk stays inside the band`() async throws {
        let controller = WanderController()
        controller.start()
        var walks = 0
        controller.playWalk = { _ in walks += 1 }
        while !controller.isWalking {
            controller.tryStartWalking()
        }

        var observed: Set<Int> = []
        for _ in 0..<50 {
            observed.insert(controller.offsetX)
            try await Task.sleep(for: .milliseconds(20))
        }
        controller.stop()

        #expect(walks == 1)
        #expect(observed.allSatisfy { (2...9).contains($0) })
    }
}

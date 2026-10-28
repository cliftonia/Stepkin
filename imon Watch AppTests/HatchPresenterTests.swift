import Foundation
import Testing
@testable import imon_Watch_App

@Suite("HatchPresenter") @MainActor struct HatchPresenterTests {
    @Test func `a second start while the ceremony runs does not hatch twice`() async {
        var hatches = 0
        var beats = 0
        let presenter = HatchPresenter(onHatched: { hatches += 1 }, beat: { _ in
            beats += 1
            return true
        })
        presenter.startHatching()
        presenter.startHatching()
        await presenter.ceremonyTask?.value
        #expect(hatches == 1)
        #expect(beats == 3)
        #expect(presenter.viewModel.phase == .hatched)
    }

    @Test func `a failed beat stops the ceremony without hatching`() async {
        var hatches = 0
        let presenter = HatchPresenter(onHatched: { hatches += 1 }, beat: { _ in false })
        presenter.startHatching()
        await presenter.ceremonyTask?.value
        #expect(hatches == 0)
    }

    @Test func `cancel stops a running ceremony before it hatches`() async {
        var hatches = 0
        let presenter = HatchPresenter(onHatched: { hatches += 1 }, beat: { _ in
            try? await Task.sleep(for: .seconds(10))
            return !Task.isCancelled
        })
        presenter.startHatching()
        let task = presenter.ceremonyTask
        presenter.cancel()
        await task?.value
        #expect(hatches == 0)
        #expect(presenter.viewModel.phase == .egg)
        #expect(presenter.ceremonyTask == nil)
    }
}

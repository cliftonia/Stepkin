import Testing
@testable import imon_Watch_App

@Suite("HatchPresenter") @MainActor struct HatchPresenterTests {
    @Test func `a second start while the ceremony runs does not hatch twice`() async {
        var hatches = 0
        let presenter = HatchPresenter(onHatched: { hatches += 1 }, beat: { _ in true })
        presenter.startHatching()
        presenter.startHatching()
        await presenter.ceremonyTask?.value
        #expect(hatches == 1)
        #expect(presenter.viewModel.phase == .hatched)
    }

    @Test func `cancel stops the ceremony before it hatches`() async {
        var hatches = 0
        let presenter = HatchPresenter(onHatched: { hatches += 1 }, beat: { _ in false })
        presenter.startHatching()
        await presenter.ceremonyTask?.value
        #expect(hatches == 0)
    }
}

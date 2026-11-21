import Testing
@testable import Stepkin_Watch_App

// Locks the conditional logic behind the LCD scene + input blocking:
// - feeding / cleaning / healing → busy AND an action scene (clean booth)
// - refusing                     → busy but NOT an action scene (normal scene)
// - training / battle            → busy but NOT an action scene (arena)
// - idle                         → neither
@MainActor
struct PetViewModelTests {

    @Test func `idle is neither busy nor an action scene`() {
        let viewModel = PetViewModel()
        #expect(viewModel.isBusy == false)
        #expect(viewModel.isInActionScene == false)
        #expect(viewModel.feedingPhase == nil)
    }

    @Test func `feeding is a busy action scene and exposes its phase`() {
        let viewModel = PetViewModel()
        viewModel.activity = .feeding(.selecting)
        #expect(viewModel.isBusy)
        #expect(viewModel.isInActionScene)
        #expect(viewModel.feedingPhase == .selecting)
    }

    @Test func `cleaning is a busy action scene`() {
        let viewModel = PetViewModel()
        viewModel.activity = .cleaning
        #expect(viewModel.isBusy)
        #expect(viewModel.isInActionScene)
    }

    @Test func `healing is a busy action scene`() {
        let viewModel = PetViewModel()
        viewModel.activity = .healing
        #expect(viewModel.isBusy)
        #expect(viewModel.isInActionScene)
    }

    // A refusal blocks input but plays in the normal scene, not a clean booth.
    @Test func `refusing is busy but not an action scene`() {
        let viewModel = PetViewModel()
        viewModel.activity = .refusing
        #expect(viewModel.isBusy)
        #expect(viewModel.isInActionScene == false)
    }

    @Test func `training and battle are busy but not action scenes`() {
        let viewModel = PetViewModel()
        viewModel.screenMode = .training
        #expect(viewModel.isBusy)
        #expect(viewModel.isInActionScene == false)

        viewModel.screenMode = .battle
        #expect(viewModel.isBusy)
        #expect(viewModel.isInActionScene == false)
    }

    @Test func `feeding phase is nil when not feeding`() {
        let viewModel = PetViewModel()
        #expect(viewModel.feedingPhase == nil)
        viewModel.activity = .cleaning
        #expect(viewModel.feedingPhase == nil)
    }
}

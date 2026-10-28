import Testing
import Foundation
@testable import imon_Watch_App

@Suite("PetStatusSentence")
@MainActor
struct PetStatusSentenceTests {

    private func status(
        hunger: Int = 4, strength: Int = 4, poop: Int = 0, asleep: Bool = false, dead: Bool = false
    ) -> PetStatus {
        var state = makeTestState(hunger: hunger, strength: strength)
        state.poopCount = poop
        state.isSleeping = asleep
        state.isDead = dead
        return PetStatus(from: state)
    }

    @Test(arguments: [
        (hunger: 0, strength: 4, poop: 0, asleep: false, dead: false, expected: "hunger 0 of"),
        (hunger: 4, strength: 4, poop: 0, asleep: true, dead: false, expected: "sleeping"),
        (hunger: 4, strength: 4, poop: 2, asleep: false, dead: false, expected: "2 messes to clean"),
        (hunger: 4, strength: 4, poop: 0, asleep: false, dead: true, expected: "has passed away"),
        (hunger: 4, strength: 4, poop: 0, asleep: false, dead: false, expected: "strength 4 of")
    ])
    func `the sentence names the pet's condition`(
        row: (hunger: Int, strength: Int, poop: Int, asleep: Bool, dead: Bool, expected: String)
    ) {
        let sentence = PetStatusSentence.describe(
            status(hunger: row.hunger, strength: row.strength, poop: row.poop, asleep: row.asleep, dead: row.dead)
        )

        #expect(sentence.contains(row.expected))
    }

    @Test
    func `the menu part is appended only when asked for`() {
        let withMenu = PetStatusSentence.describe(status(), includeMenu: "feed")
        let without = PetStatusSentence.describe(status())

        #expect(withMenu.hasSuffix(", menu: feed"))
        #expect(!without.contains("menu"))
    }

    @Test
    func `the view model's description ends with its menu part`() {
        let viewModel = PetViewModel()
        viewModel.status = status()

        #expect(viewModel.accessibilityDescription.hasSuffix("menu: \(viewModel.menuSelection.accessibilityName)"))
    }
}

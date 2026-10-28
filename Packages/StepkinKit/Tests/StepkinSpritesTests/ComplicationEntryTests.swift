import Testing
import Foundation
import StepkinEngine
@testable import StepkinSprites
import StepkinTestSupport

@Suite("ComplicationEntry")
struct ComplicationEntryTests {

    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func `a healthy pet reads as happy and calm`() {
        let state = makeTestState(species: .emberkin, hunger: 4, strength: 4)
        let entry = ComplicationEntry(date: date, state: state)
        #expect(entry.speciesName == "Emberkin")
        #expect(entry.hungerValue == 4)
        #expect(entry.hungerMax == PetSpecies.emberkin.maxHunger)
        #expect(entry.needsAttention == false)
        #expect(entry.statusText == "happy")
        #expect(entry.moodKey == "happy")
        #expect(entry.spriteRows.count == 16)
    }

    @Test
    func `an empty-hunger pet needs attention and reads as hungry`() {
        let state = makeTestState(species: .emberkin, hunger: 0)
        let entry = ComplicationEntry(date: date, state: state)
        #expect(entry.needsAttention)
        #expect(entry.statusText == "hungry")
        #expect(entry.moodKey == "hungry")
    }

    @Test
    func `an injured pet reads as hurt`() {
        var state = makeTestState(species: .emberkin)
        state.isInjured = true
        let entry = ComplicationEntry(date: date, state: state)
        #expect(entry.isInjured)
        #expect(entry.needsAttention)
        #expect(entry.statusText == "hurt")
        #expect(entry.moodKey == "hurt")
    }

    /// One fixture per mood; each also trips every later check, so a wrong precedence would pick another mood.
    private static let precedenceTable: [(mood: ComplicationEntry.Mood, state: PetState)] = ComplicationEntry.Mood.allCases.map {
        var state = makeTestState(species: .emberkin, hunger: 0, strength: 0)
        state.poopCount = 1
        state.isSleeping = true
        switch $0 {
        case .gone: state.isDead = true
        case .egg: state.isEgg = true
        case .hurt: state.isInjured = true
        case .hungry: break
        case .weak: state.hungerHearts = StatHearts(4)
        case .messy:
            state.hungerHearts = StatHearts(4)
            state.strengthHearts = StatHearts(4)
        case .asleep:
            state.hungerHearts = StatHearts(4)
            state.strengthHearts = StatHearts(4)
            state.poopCount = 0
        case .happy:
            state.hungerHearts = StatHearts(4)
            state.strengthHearts = StatHearts(4)
            state.poopCount = 0
            state.isSleeping = false
        }
        return ($0, state)
    }

    @Test(arguments: precedenceTable)
    func `each mood is the first match in the precedence order`(row: (mood: ComplicationEntry.Mood, state: PetState)) {
        let entry = ComplicationEntry(date: date, state: row.state)
        #expect(entry.moodKey == row.mood.rawValue)
        #expect(entry.statusText == row.mood.rawValue)
    }

    @Test
    func `a dead pet reads as gone and an egg as egg`() {
        var dead = makeTestState(species: .emberkin)
        dead.isDead = true
        #expect(ComplicationEntry(date: date, state: dead).moodKey == "gone")
        var egg = makeTestState(species: .emberkin)
        egg.isEgg = true
        #expect(ComplicationEntry(date: date, state: egg).moodKey == "egg")
    }
}

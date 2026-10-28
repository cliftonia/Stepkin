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

    @Test(arguments: ComplicationEntry.Mood.allCases)
    func `the mood key is the raw identifier and the status word`(mood: ComplicationEntry.Mood) {
        #expect(mood.rawValue.isEmpty == false)
        #expect(Set(ComplicationEntry.Mood.allCases.map(\.rawValue)).count == 8)
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

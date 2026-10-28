import Testing
import Foundation
@testable import StepkinEngine
import StepkinTestSupport

@Suite("JSONPetStateStore")
struct JSONPetStateStoreTests {

    @Test
    func `a save round-trips through the store`() throws {
        let defaults = try makeIsolatedDefaults("JSONPetStateStoreTests")
        let store = JSONPetStateStore.live(defaults: defaults)
        var state = makeTestState(species: .hopkin)
        state.lifetimeActiveSteps = 4_321

        try store.save(state)
        let loaded = try #require(try store.load())

        #expect(loaded.species == .hopkin)
        #expect(loaded.lifetimeActiveSteps == 4_321)
    }

    @Test
    func `an undecodable save falls back to the previous good one`() throws {
        let defaults = try makeIsolatedDefaults("JSONPetStateStoreTests")
        let store = JSONPetStateStore.live(defaults: defaults)
        try store.save(makeTestState(species: .dotkin))
        try store.save(makeTestState(species: .hopkin))

        defaults.set(Data("not json".utf8), forKey: JSONPetStateStore.key)
        let loaded = try #require(try store.load())

        // The backup is the save before the torn one.
        #expect(loaded.species == .dotkin)
    }

    @Test
    func `an undecodable save with no backup still throws`() throws {
        let defaults = try makeIsolatedDefaults("JSONPetStateStoreTests")
        let store = JSONPetStateStore.live(defaults: defaults)
        defaults.set(Data("not json".utf8), forKey: JSONPetStateStore.key)

        #expect(throws: (any Error).self) { try store.load() }
    }

    @Test
    func `delete clears the backup too`() throws {
        let defaults = try makeIsolatedDefaults("JSONPetStateStoreTests")
        let store = JSONPetStateStore.live(defaults: defaults)
        try store.save(makeTestState())
        try store.save(makeTestState())

        try store.delete()

        #expect(defaults.data(forKey: JSONPetStateStore.key) == nil)
        #expect(defaults.data(forKey: JSONPetStateStore.backupKey) == nil)
        #expect(try store.load() == nil)
    }
}

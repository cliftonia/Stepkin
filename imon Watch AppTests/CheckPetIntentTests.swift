import Testing
import Foundation
@testable import imon_Watch_App

@Suite("CheckPetIntent", .serialized)
@MainActor
struct CheckPetIntentTests {

    private func speak(describing sentence: String?) async -> String {
        let original = IntentGateway.describe
        defer { IntentGateway.describe = original }
        IntentGateway.describe = { sentence }
        return await CheckPetIntent.speak()
    }

    @Test
    func `the pet's sentence is spoken`() async {
        let spoken = await speak(describing: "Emberkin, Baby, hunger 4 of 4")

        #expect(spoken == "Emberkin, Baby, hunger 4 of 4")
    }

    @Test
    func `with no pet it says so`() async {
        let spoken = await speak(describing: nil)

        #expect(spoken == "There is no pet yet.")
    }

    /// Records the order in which the gateway routes and reads the pet.
    private final class EventLog {
        var events: [String] = []
    }

    /// A check must describe the pet as it is now, so it ticks through the
    /// single writer before the status is read.
    @Test
    func `a check ticks the pet through the router before reading its status`() async {
        let log = EventLog()
        let status = PetStatus(from: makeTestState())

        let sentence = await IntentGateway.sentence(
            after: { action in
                if case .tick = action { log.events.append("tick") }
                return .done
            },
            reading: {
                log.events.append("read")
                return status
            }
        )

        #expect(log.events == ["tick", "read"])
        #expect(sentence == PetStatusSentence.describe(status))
    }
}

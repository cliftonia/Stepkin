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
}

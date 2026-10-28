import Testing
import Foundation
@testable import imon_Watch_App

@Suite("FeedPetIntent", .serialized)
@MainActor
struct FeedPetIntentTests {

    private final class ActionRecorder {
        var actions: [PetAction] = []
    }

    private func speak(_ outcome: PetActionOutcome, food: FoodChoice = .meat, recorder: ActionRecorder) async -> String {
        let original = IntentGateway.route
        defer { IntentGateway.route = original }
        IntentGateway.route = { action in
            recorder.actions.append(action)
            return outcome
        }
        return await FeedPetIntent.speak(food: food)
    }

    @Test
    func `a done feed says fed and routes the chosen food`() async {
        let recorder = ActionRecorder()

        let spoken = await speak(.done, recorder: recorder)

        #expect(spoken == "Fed.")
        guard case .feed(.meat)? = recorder.actions.first, recorder.actions.count == 1 else {
            Issue.record("expected a single meat feed, got \(recorder.actions)")
            return
        }
    }

    @Test
    func `the vitamin choice routes a vitamin feed`() async {
        let recorder = ActionRecorder()

        _ = await speak(.done, food: .vitamin, recorder: recorder)

        guard case .feed(.vitamin)? = recorder.actions.first else {
            Issue.record("expected a vitamin feed, got \(recorder.actions)")
            return
        }
    }

    @Test
    func `a refusal speaks its reason`() async {
        let spoken = await speak(.refused(reason: FeedRefusal.full), recorder: ActionRecorder())

        #expect(spoken == FeedRefusal.full)
    }

    @Test
    func `no pet says there is no pet to feed`() async {
        let spoken = await speak(.noPet, recorder: ActionRecorder())

        #expect(spoken == "There is no pet to feed yet.")
    }
}

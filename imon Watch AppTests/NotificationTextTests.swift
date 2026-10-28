import Testing
import Foundation
@testable import imon_Watch_App

@Suite("Notification text")
struct NotificationTextTests {

    @Test(arguments: [
        (CareNotification.Kind.hunger, "Emberkin is hungry!"),
        (.strength, "Emberkin is weak \u{2014} give it vitamins!"),
        (.mess, "Emberkin made a mess!"),
        (.injury, "Emberkin is hurt \u{2014} heal it!"),
        (.exercise, "Emberkin needs some exercise!"),
        (.fading, "Emberkin is fading \u{2014} care for it now!")
    ])
    func `each care reminder names the need and the pet`(kind: CareNotification.Kind, expected: String) {
        #expect(CareNotificationText.body(for: kind, speciesName: "Emberkin") == expected)
    }

    @Test(arguments: [CareNotification.Kind.hunger, .strength, .mess, .injury, .exercise, .fading])
    func `a care reminder is titled with the species name`(kind: CareNotification.Kind) {
        #expect(CareNotificationText.title(for: kind, speciesName: "Emberkin") == "Emberkin")
    }

    @Test
    func `the evolution announcement names both species`() {
        #expect(CareNotificationText.evolutionTitle == "Evolution!")
        #expect(CareNotificationText.evolutionBody(from: "Dotkin", to: "Emberkin") == "Dotkin evolved into Emberkin!")
    }
}

import Testing
import Foundation

@Suite("WidgetEntry decoding")
struct WidgetEntryDecodingTests {

    @Test
    func `a legacy entry without the new keys decodes with nil flags`() throws {
        let json = """
        {"date": 0, "speciesName": "Dotkin", "spriteRows": [960, 4080], "hungerValue": 2,
         "hungerMax": 4, "needsAttention": true, "statusText": "hungry", "stage": "baby"}
        """
        let entry = try JSONDecoder().decode(WidgetEntry.self, from: Data(json.utf8))

        #expect(entry.speciesName == "Dotkin")
        #expect(entry.spriteRows == [960, 4080])
        #expect(entry.needsAttention)
        #expect(entry.isInjured == nil)
        #expect(entry.isDead == nil)
        #expect(entry.isEgg == nil)
    }

    @Test
    func `a current entry decodes the flags`() throws {
        let json = """
        {"date": 0, "speciesName": "Dotkin", "spriteRows": [], "hungerValue": 0, "hungerMax": 4,
         "needsAttention": false, "statusText": "sick", "isInjured": true, "isDead": false, "isEgg": true}
        """
        let entry = try JSONDecoder().decode(WidgetEntry.self, from: Data(json.utf8))

        #expect(entry.isInjured == true)
        #expect(entry.isDead == false)
        #expect(entry.isEgg == true)
    }

    @Test
    func `a legacy entry without a mood key shows its status text`() throws {
        let entry = try decode(statusText: "hungry", moodKey: nil)

        #expect(entry.moodKey == nil)
        #expect(entry.moodText == entry.statusText)
    }

    @Test
    func `a current entry localizes its mood key`() throws {
        let entry = try decode(statusText: "hungry", moodKey: "hungry")

        #expect(entry.moodText == "hungry")
    }

    @Test
    func `an unknown mood key falls back to the status text`() throws {
        let entry = try decode(statusText: "happy", moodKey: "ecstatic")

        #expect(entry.moodText == "happy")
    }

    // Decodes a minimal entry with the given status word and optional mood key.
    private func decode(statusText: String, moodKey: String?) throws -> WidgetEntry {
        let keyField = moodKey.map { ", \"moodKey\": \"\($0)\"" } ?? ""
        let json = """
        {"date": 0, "speciesName": "Dotkin", "spriteRows": [], "hungerValue": 0, "hungerMax": 4,
         "needsAttention": false, "statusText": "\(statusText)"\(keyField)}
        """
        return try JSONDecoder().decode(WidgetEntry.self, from: Data(json.utf8))
    }
}

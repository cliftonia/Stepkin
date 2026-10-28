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
}

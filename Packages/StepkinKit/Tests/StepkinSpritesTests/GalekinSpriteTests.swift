import Testing
import StepkinEngine
@testable import StepkinSprites

@Suite("Galekin Sprites")
struct GalekinSpriteTests {

    // MARK: - Custom Animation Frame Counts

    @Test
    func `eat animation has four frames`() {
        let animation = SpriteCatalog.animation(
            for: .galekin, kind: .eat
        )
        #expect(animation.frames.count == 4)
    }

    @Test
    func `happy animation has four frames`() {
        let animation = SpriteCatalog.animation(
            for: .galekin, kind: .happy
        )
        #expect(animation.frames.count == 4)
    }

    @Test
    func `refuse animation has four frames`() {
        let animation = SpriteCatalog.animation(
            for: .galekin, kind: .refuse
        )
        #expect(animation.frames.count == 4)
    }

    // MARK: - Custom Animations Are Not Default-Derived

    @Test
    func `refuse keeps body anchored while head shifts`() {
        let idle = SpriteCatalog.animation(
            for: .galekin, kind: .idle
        )
        let refuse = SpriteCatalog.animation(
            for: .galekin, kind: .refuse
        )
        // Default refuse shifts the entire sprite;
        // custom refuse keeps wings (row 7) identical to idle
        let idleWingRow = idle.frames[0].rows[7]
        #expect(refuse.frames[0].rows[7] == idleWingRow)
        #expect(refuse.frames[1].rows[7] == idleWingRow)
    }

    // MARK: - Wing Tip Continuity

    @Test
    func `idle frames have body pixels in wing tip row`() {
        let idle = SpriteCatalog.animation(
            for: .galekin, kind: .idle
        )
        for frame in idle.frames {
            let tipRow = frame.rows[9]
            // Body core at cols 6-9 should have pixels set
            let bodyCols: UInt16 = 0x03C0 // ......####......
            #expect(tipRow & bodyCols == bodyCols)
        }
    }

    @Test
    func `eat last frame returns to idle`() {
        let idle = SpriteCatalog.animation(
            for: .galekin, kind: .idle
        )
        let eat = SpriteCatalog.animation(
            for: .galekin, kind: .eat
        )
        #expect(idle.frames.contains(eat.frames[3]))
    }

    @Test
    func `refuse last frame returns to idle`() {
        let idle = SpriteCatalog.animation(
            for: .galekin, kind: .idle
        )
        let refuse = SpriteCatalog.animation(
            for: .galekin, kind: .refuse
        )
        #expect(refuse.frames[3] == idle.frames[0])
    }
}

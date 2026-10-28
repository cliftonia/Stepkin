import Testing
import StepkinEngine
@testable import StepkinSprites

@Suite("SpriteCatalog")
struct SpriteCatalogTests {

    @Test
    func `refuse animation has four frames`() {
        let animation = SpriteCatalog.animation(
            for: .emberkin,
            kind: .refuse
        )
        #expect(animation.frames.count == 4)
    }

    @Test
    func `refuse animation does not loop`() {
        let animation = SpriteCatalog.animation(
            for: .emberkin,
            kind: .refuse
        )
        #expect(!animation.loops)
    }

    @Test
    func `refuse animation has correct frame duration`() {
        let animation = SpriteCatalog.animation(
            for: .emberkin,
            kind: .refuse
        )
        #expect(animation.frameDuration == 0.15)
    }

    @Test
    func `weak animation is a slow looping derivation of idle`() {
        let weak = SpriteCatalog.weakAnimation(for: .emberkin)
        #expect(weak.frames.count == 4)
        #expect(weak.loops)
        #expect(weak.frameDuration == 0.7)
        // Derived by drooping, so it must carry real body pixels (not empty).
        #expect(weak.frames.contains { $0 != .empty })
    }

    @Test
    func `every species yields a non-empty weak animation`() {
        for species in PetSpecies.allCases {
            let weak = SpriteCatalog.weakAnimation(for: species)
            #expect(weak.frames.allSatisfy { $0 != .empty })
        }
    }
}

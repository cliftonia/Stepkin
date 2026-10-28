import Testing
import StepkinEngine
@testable import StepkinSprites

@Suite("SpriteAnimation")
struct SpriteAnimationTests {

    @Test
    func `mirrored preserves frame count`() {
        let animation = SpriteAnimation(
            frames: [
                SpriteFrame(rows: Array(repeating: 0, count: 16)),
                SpriteFrame(rows: Array(repeating: 0, count: 16))
            ],
            frameDuration: 0.5,
            loops: true
        )
        let mirrored = animation.mirrored()
        #expect(mirrored.frames.count == animation.frames.count)
    }

    @Test
    func `mirrored preserves frame duration`() {
        let animation = SpriteAnimation(
            frames: [
                SpriteFrame(rows: Array(repeating: 0, count: 16))
            ],
            frameDuration: 0.25,
            loops: false
        )
        let mirrored = animation.mirrored()
        #expect(mirrored.frameDuration == 0.25)
    }

    @Test
    func `mirrored preserves loop setting`() {
        let looping = SpriteAnimation(
            frames: [
                SpriteFrame(rows: Array(repeating: 0, count: 16))
            ],
            loops: true
        )
        let nonLooping = SpriteAnimation(
            frames: [
                SpriteFrame(rows: Array(repeating: 0, count: 16))
            ],
            loops: false
        )
        #expect(looping.mirrored().loops == true)
        #expect(nonLooping.mirrored().loops == false)
    }

    @Test
    func `mirrored mirrors each frame`() {
        var rows = Array(repeating: UInt16(0), count: 16)
        rows[0] = 0x8000 // #...............
        let frame = SpriteFrame(rows: rows)
        let animation = SpriteAnimation(frames: [frame])
        let mirrored = animation.mirrored()
        // Mirroring 0x8000 (bit 15) should set bit 0 = 0x0001
        #expect(mirrored.frames[0].rows[0] == 0x0001)
    }

    @Test
    func `double mirror returns original`() {
        let animation = SpriteCatalog.animation(
            for: .emberkin, kind: .idle
        )
        let doubleMirrored = animation.mirrored().mirrored()
        #expect(doubleMirrored.frames == animation.frames)
    }
}

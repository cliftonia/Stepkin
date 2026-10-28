import Testing
@testable import StepkinSprites

@Suite("SharedSprites")
struct SharedSpritesTests {

    @Test
    func `water drops stay within LCD bounds at offset 20`() {
        let frames = [
            SharedSprites.waterDrops1,
            SharedSprites.waterDrops2
        ]
        for frame in frames {
            for row in frame.rows {
                // At offsetX=20, col 12+ is off-screen (32-wide LCD)
                // Bits 3..0 correspond to cols 12-15
                let offScreenBits: UInt16 = 0x000F
                #expect(row & offScreenBits == 0)
            }
        }
    }

    // MARK: - Satisfaction Heart

    @Test
    func `satisfaction heart stays within LCD bounds at offset 20`() {
        let heart = SharedSprites.satisfactionHeart
        for row in heart.rows {
            let offScreenBits: UInt16 = 0x000F
            #expect(row & offScreenBits == 0)
        }
    }

    @Test
    func `satisfaction heart has pixel data`() {
        let heart = SharedSprites.satisfactionHeart
        let hasPixels = heart.rows.contains { $0 != 0 }
        #expect(hasPixels)
    }

    // MARK: - Clean Sparkle

    @Test
    func `clean sparkle frames stay within LCD bounds`() {
        let frames = [
            SharedSprites.cleanSparkle1,
            SharedSprites.cleanSparkle2
        ]
        for frame in frames {
            for row in frame.rows {
                let offScreenBits: UInt16 = 0x000F
                #expect(row & offScreenBits == 0)
            }
        }
    }
}

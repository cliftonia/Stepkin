import Testing
import Foundation
import StepkinEngine
@testable import StepkinSprites

@Suite("Battle projectiles")
struct BattleProjectileTests {

    /// Topmost lit row of the launch frame (smaller = higher on the LCD).
    private func topRow(_ animation: SpriteAnimation) -> Int? {
        animation.frames.first?.rows.firstIndex { $0 != 0 }
    }

    private func bottomRow(_ animation: SpriteAnimation) -> Int? {
        animation.frames.first?.rows.lastIndex { $0 != 0 }
    }

    @Test(arguments: PetSpecies.allCases)
    func `high, medium and low occupy distinct vertical bands`(species: PetSpecies) throws {
        let high = try #require(topRow(SpriteCatalog.projectile(for: species, height: .high)))
        let medium = try #require(topRow(SpriteCatalog.projectile(for: species, height: .medium)))
        let low = try #require(topRow(SpriteCatalog.projectile(for: species, height: .low)))

        // High sits strictly above medium, which sits strictly above low.
        #expect(high < medium)
        #expect(medium < low)
    }

    @Test(arguments: PetSpecies.allCases)
    func `no projectile band clips off the top or bottom edge`(species: PetSpecies) throws {
        for height in AttackHeight.allCases {
            let animation = SpriteCatalog.projectile(for: species, height: height)
            #expect(try #require(topRow(animation)) >= 0)
            #expect(try #require(bottomRow(animation)) <= 15)
        }
    }
}

import Foundation
import StepkinEngine

// MARK: - Side-Profile Animations (Battle & Training)

extension SpriteCatalog {

    /// Side-profile standing stance, facing the opponent/target.
    public static func sideStance(
        for species: PetSpecies
    ) -> SpriteAnimation {
        SpriteAnimation(
            frames: frames(for: species, kind: .sideWalk),
            frameDuration: 0.5,
            loops: true
        )
    }

    /// Species-specific side-profile attack pose. Species without a
    /// dedicated attack hold their side stance.
    public static func sideAttack(
        for species: PetSpecies
    ) -> SpriteAnimation {
        switch species {
        case .hopkin:
            let ready = frames(for: .hopkin, kind: .sideWalk).first
                ?? .empty
            return SpriteAnimation(
                frames: [
                    ready, hopkinMouthHalf,
                    hopkinMouthWide, hopkinMouthWide
                ],
                frameDuration: 0.18,
                loops: false
            )
        case .emberkin: return mouthChomp(.emberkin, emberkinMouthWide)
        case .rexkin: return mouthChomp(.rexkin, rexkinMouthWide)
        case .blazekin: return mouthChomp(.blazekin, blazekinMouthWide)
        case .galekin: return mouthChomp(.galekin, galekinMouthWide)
        case .tidekin: return mouthChomp(.tidekin, tidekinMouthWide)
        case .sludgekin: return mouthChomp(.sludgekin, sludgekinMouthWide)
        case .steelkin: return mouthChomp(.steelkin, steelkinMouthWide)
        case .dreadkin: return mouthChomp(.dreadkin, dreadkinMouthWide)
        case .pyrekin: return mouthChomp(.pyrekin, pyrekinMouthWide)
        case .dotkin: return mouthChomp(.dotkin, dotkinMouthWide)
        case .marshkin: return mouthChomp(.marshkin, marshkinMouthWide)
        case .orbkin: return mouthChomp(.orbkin, orbkinMouthWide)
        case .plushkin: return mouthChomp(.plushkin, plushkinMouthWide)
        }
    }

    /// Opens from the side stance to a held mouth-wide pose.
    private static func mouthChomp(
        _ species: PetSpecies,
        _ wide: SpriteFrame
    ) -> SpriteAnimation {
        let ready = frames(for: species, kind: .sideWalk).first
            ?? .empty
        return SpriteAnimation(
            frames: [ready, wide, wide],
            frameDuration: 0.2,
            loops: false
        )
    }

    // Hopkin's mouth-open chomp (native facing left). The back of the
    // body stays full — only the front (mouth) opens.
    private static let hopkinMouthHalf = SpriteFrame(rows: [
        0x0000, //  ................
        0x01C0, //  .......###......
        0x0380, //  ......###.......
        0x0780, //  .....####.......
        0x1FC0, //  ...#######......
        0x3FE0, //  ..#########.....
        0x7FF0, //  .###########....
        0x6FF0, //  .##.########....  eye
        0x6FF0, //  .##.########....
        0x3FF0, //  ..##########....  mouth opening
        0x7FE0, //  .##########.....
        0x3FC0, //  ..########......
        0x1F80, //  ...######.......
        0x0F00, //  ....####........
        0x0000, //  ................
        0x0000  //  ................
    ])

    private static let hopkinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x01C0, //  .......###......
        0x0380, //  ......###.......
        0x0780, //  .....####.......
        0x1FC0, //  ...#######......
        0x3FE0, //  ..#########.....
        0x7FF0, //  .###########....  back stays full
        0x6FF0, //  .##.########....  eye
        0x6FF0, //  .##.########....
        0x1FF0, //  ...#########....  upper lip
        0x0FF0, //  ....########....  mouth wide open
        0x3FE0, //  ..#########.....  lower jaw
        0x3FC0, //  ..########......
        0x1F80, //  ...######.......
        0x0000, //  ................
        0x0000  //  ................
    ])

    // Raptor mouth-open (native left), built on the sideWalk profile: the
    // head rears up a pixel and the jaws jut FORWARD into a wide maw while
    // the hinge at the back stays solid, so the silhouette never breaks.
    // Body, tail, and braced legs match the new side-profile stance.
    private static let emberkinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x3C00, //  ..####..........  skull top, reared up
        0x7E00, //  .######.........  skull
        0x7600, //  .###.##.........  eye
        0xFE00, //  #######.........  upper jaw juts forward
        0x0600, //  .....##.........  maw open, hinge at the back
        0x7E00, //  .######.........  lower jaw juts forward
        0x0F00, //  ....####........  neck
        0x0FE6, //  ....#######..##.  body + tail tip kicked up
        0x1FFC, //  ...###########..  body + tail
        0x1FE0, //  ...########.....  tail underside
        0x0FC0, //  ....######......  belly
        0x0780, //  .....####.......  legs braced together
        0x0480, //  .....#..#.......
        0x0CC0, //  ....##..##......  feet
        0x0000  //  ................
    ])

    // T-rex mouth-open (native left), built on the sideWalk profile: the
    // jaws jut FORWARD into a wide maw while the hinge at the back stays
    // solid, so the silhouette never breaks. Horn, body, tail, and braced
    // legs match the new side-profile stance.
    private static let rexkinMouthWide = SpriteFrame(rows: [
        0x0180, //  .......##.......  horn
        0x3F00, //  ..######........  skull top
        0x7700, //  .###.###........  eye
        0xFF00, //  ########........  upper jaw juts forward
        0x0300, //  ......##........  maw open, hinge at the back
        0x7F00, //  .#######........  lower jaw juts forward
        0x0F80, //  ....#####.......  neck
        0x0FE0, //  ....#######.....  shoulders
        0x1FF6, //  ...#########.##.  body + tail tip kicked up
        0x1FFE, //  ...############.  body + tail
        0x1FF8, //  ...##########...  tail underside
        0x0FE0, //  ....#######.....  belly
        0x07C0, //  .....#####......  legs braced together
        0x0480, //  .....#..#.......
        0x0CC0, //  ....##..##......  feet
        0x0000  //  ................
    ])

    // Stocky dino mouth-open (native left), built on the sideWalk profile:
    // the jaws jut FORWARD into a wide maw while the hinge at the back
    // stays solid, so the silhouette never breaks. Deep body, short thick
    // tail, and braced legs match the new side-profile stance.
    private static let blazekinMouthWide = SpriteFrame(rows: [
        0x2A00, //  ..#.#.#.........  flame crest
        0x3E00, //  ..#####.........  skull top, reared up
        0x7700, //  .###.###........  eye
        0xFF00, //  ########........  upper jaw juts forward
        0x0300, //  ......##........  maw open, hinge at the back
        0x7F00, //  .#######........  lower jaw juts forward
        0x0FC0, //  ....######......  neck
        0x1FE2, //  ...########...#.  shoulders, flame lick over tail
        0x1FF6, //  ...#########.##.  body + flame-tip tail
        0x3FFE, //  ..#############.  deep body + tail
        0x3FF8, //  ..############..  tail underside
        0x1FE0, //  ...########.....  belly
        0x07C0, //  .....#####......  legs braced together
        0x0480, //  .....#..#.......
        0x0CC0, //  ....##..##......  feet
        0x0000  //  ................
    ])

    // Serpent-dragon mouth-open (native left), built on the sideWalk
    // profile: jaws jut FORWARD, hinge solid at the back. Wing on the
    // back and the coiled tail base match the new stance.
    private static let galekinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x0300, //  ......##........  crest swept back
        0x1F00, //  ...#####........  skull + crest
        0x1B00, //  ...##.##........  eye
        0xFF00, //  ########........  upper beak juts forward
        0x0300, //  ......##........  beak open, hinge at the back
        0x7F00, //  .#######........  lower beak juts forward
        0x0E70, //  ....###..###....  neck + wing behind
        0x07F0, //  .....#######....  body + wing merge
        0x0FB0, //  ....#####.##....  body + wing tips
        0x0FC0, //  ....######......  body
        0x07E0, //  .....######.....
        0x03F0, //  ......######....  tail
        0x00F8, //  ........#####...
        0x01F8, //  .......######...  coiled tail base
        0x0000  //  ................
    ])

    // Sea-serpent mouth-open (native left), built on the slithering
    // sideWalk profile: the head rears off the ground and the jaws
    // jut FORWARD, hinge solid at the back, body rippling behind.
    private static let tidekinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x0000, //  ................
        0x0000, //  ................
        0x0000, //  ................
        0x0000, //  ................
        0x0000, //  ................
        0x0000, //  ................
        0x0C00, //  ....##..........  fin crest, head reared
        0x1600, //  ...#.##.........  eye
        0xFE00, //  #######.........  upper jaw juts forward
        0x0600, //  .....##.........  maw open, hinge at the back
        0x7E00, //  .######.........  lower jaw juts forward
        0x1F8E, //  ...######...###.  neck + wave crests
        0x3FFE, //  ..#############.  body
        0x7FFE, //  .##############.  belly on the ground
        0x0000  //  ................
    ])

    // Ooze mouth-open (native left), built on the sideWalk profile:
    // the maw gapes toward the foe while the hinge at the back stays
    // solid. Eye stalk, wide base, and slime trail match the stance.
    private static let sludgekinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x0000, //  ................
        0x0000, //  ................
        0x1000, //  ...#............  eye stalk forward
        0x3000, //  ..##............  eyeball
        0x1000, //  ...#............
        0x0F80, //  ....#####.......  mound top
        0x1BE0, //  ...##.#####.....  eye
        0x3FE0, //  ..#########.....  upper lip
        0x0070, //  .........###....  maw open, hinge at the back
        0x3FF0, //  ..##########....  lower lip
        0x3FF8, //  ..###########...
        0x7FFC, //  .#############..
        0xFFFE, //  ###############.  wide base
        0x7FFC, //  .#############..
        0x2208  //  ..#...#.....#...  slime trail
    ])

    // Mech-dino mouth-open (native left), built on the sideWalk
    // profile: jaws jut FORWARD, hinge solid at the back. Horn, visor
    // slit, steel wing, and braced legs match the new stance.
    private static let steelkinMouthWide = SpriteFrame(rows: [
        0x0180, //  .......##.......  horn
        0x3F00, //  ..######........  skull top
        0x6700, //  .##..###........  visor slit
        0xFF00, //  ########........  upper jaw juts forward
        0x0300, //  ......##........  maw open, hinge at the back
        0x7F00, //  .#######........  lower jaw juts forward
        0x0FA0, //  ....#####.#.....  neck + armor spike
        0x0FC8, //  ....######..#...  shoulders + spike
        0x1FF6, //  ...#########.##.  body + tail tip
        0x1FFC, //  ...###########..  body + tail
        0x1FE0, //  ...########.....  tail underside
        0x0FC0, //  ....######......  belly
        0x07C0, //  .....#####......  legs braced together
        0x0480, //  .....#..#.......
        0x0CC0, //  ....##..##......  feet
        0x0000  //  ................
    ])

    // Demon mouth-open (native left), built on the sideWalk profile: the
    // jaws jut FORWARD into a wide maw while the hinge at the back stays
    // solid. Swept horns, folded cloak-wing, and braced legs match the
    // new side-profile stance.
    private static let dreadkinMouthWide = SpriteFrame(rows: [
        0x0300, //  ......##........  horns swept back
        0x3E00, //  ..#####.........  skull top
        0x6F00, //  .##.####........  eye
        0xFF00, //  ########........  upper jaw juts forward
        0x0300, //  ......##........  maw open, hinge at the back
        0x7F00, //  .#######........  lower jaw juts forward
        0x0E20, //  ....###...#.....  neck, wing tip behind
        0x1F20, //  ...#####..#.....  shoulders + wing
        0x0F60, //  ....####.##.....  body + wing
        0x0FF0, //  ....########....  wing folds against the back
        0x0FE0, //  ....#######.....
        0x0F80, //  ....#####.......
        0x0700, //  .....###........  waist
        0x0700, //  .....###........
        0x0500, //  .....#.#........  legs braced
        0x0D80  //  ....##.##.......  feet
    ])

    // Flame-humanoid mouth-open (native left), built on the sideWalk
    // profile: the jaws jut FORWARD into a wide maw while the hinge at
    // the back stays solid. Crown flame, swinging arm, and braced legs
    // match the new side-profile stance.
    private static let pyrekinMouthWide = SpriteFrame(rows: [
        0x0500, //  .....#.#........  flame tips
        0x0A80, //  ....#.#.#.......  flame trails back
        0x1F00, //  ...#####........  flame base
        0x2F00, //  ..#.####........  eye
        0xFF00, //  ########........  upper jaw juts forward
        0x0300, //  ......##........  maw open, hinge at the back
        0x3F00, //  ..######........  lower jaw juts forward
        0x1FA0, //  ...######.#.....  shoulders + wing wisp
        0x37E0, //  ..##.######.....  arm + wing on the back
        0x2780, //  ..#..####.......  fist + torso
        0x0780, //  .....####.......  torso
        0x0700, //  .....###........  hips
        0x0700, //  .....###........
        0x0500, //  .....#.#........  legs braced
        0x0500, //  .....#.#........
        0x0D80  //  ....##.##.......  feet
    ])

    // Dotkin opens a mouth at the front (blob attack).
    private static let dotkinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x0000, //  ................
        0x0300, //  ......##........  horn
        0x0500, //  .....#.#........
        0x03C0, //  ......####......
        0x0FF0, //  ....########....
        0x3FF0, //  ..##########....
        0x37E0, //  ..##.######.....  one eye + mouth
        0x1FE0, //  ...########.....
        0x3FF0, //  ..##########....
        0x1FF8, //  ...##########...
        0x0FF0, //  ....########....
        0x03C0, //  ......####......
        0x0000, //  ................
        0x0000, //  ................
        0x0000  //  ................
    ])

    // Teddy muzzle-open (native left), built on the sideWalk profile:
    // the muzzle juts FORWARD, hinge solid at the back. Ear, tail nub,
    // and braced waddle legs match the new stance.
    private static let plushkinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x3C00, //  ..####..........  big ear
        0x7E00, //  .######.........
        0x3F00, //  ..######........  head
        0x6F80, //  .##.#####.......  eye
        0xFF80, //  #########.......  upper muzzle juts forward
        0x0180, //  .......##.......  maw open, hinge at the back
        0x7F80, //  .########.......  lower jaw juts forward
        0x1F80, //  ...######.......  chin
        0x3FD8, //  ..########.##...  body + tail nub
        0x7FF8, //  .############...  body + tail
        0x7FE0, //  .##########.....
        0x7FE0, //  .##########.....
        0x3FC0, //  ..########......
        0x0CC0, //  ....##..##......  legs braced
        0x1CE0  //  ...###..###.....  feet
    ])

    // Orbkin (bird) opens its beak to blow a gust — wind attack.
    private static let orbkinMouthWide = SpriteFrame(rows: [
        0x0000, //  ................
        0x0000, //  ................
        0x03C0, //  ......####......
        0x07E0, //  .....######.....
        0x1FF0, //  ...#########....
        0x35F8, //  ..##.#.######...  upper beak open
        0x05F8, //  .....#.######...  beak gap (blow)
        0x3DF8, //  ..####.######...  lower beak
        0x0FF0, //  ....########....
        0x1FF8, //  ...##########...  body
        0x1FFC, //  ...###########..  tail
        0x1FFE, //  ...############.
        0x1FF8, //  ...##########...
        0x0FF0, //  ....########....
        0x0480, //  .....#..#.......
        0x0CC0  //  ....##..##......
    ])

    private static let marshkinMouthWide = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0400, //  .....#..........
            0x0E00, //  ....###.........
            0x1F00, //  ...#####........
            0x3F80, //  ..#######.......
            0x1980, //  ...##..##.......
            0x7FC0, //  .#########......
            0x7FC0, //  .#########......
            0x3FE0, //  ..#########.....
            0x1FF0, //  ...#########....
            0x0FF8, //  ....#########...
            0x1240, //  ...#..#..#......
            0x0000, //  ................
            0x0000 //  ................
        ])
}

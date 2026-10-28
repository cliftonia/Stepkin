# Sprite Tooling

Pipeline for authoring the game's 16×16 1-bit sprites with real pixel-art
tools instead of hand-typing hex. Sprites are stored as `[UInt16]` rows in
`SpriteFrame` (MSB = leftmost pixel) — see
`Packages/StepkinKit/Sources/StepkinSprites/Rendering/SpriteFrame.swift`.

## sprite2swift.py — PNG → SpriteFrame

Converts a PNG (or a sprite-sheet grid of cells) into ready-to-paste Swift
`SpriteFrame(rows: [...])` declarations, complete with ASCII-art comments
matching the codebase style.

```bash
# Single 16×16 sprite
python3 Tools/sprite2swift.py mysprite.png --name sideWalk1

# Animation strip / sheet of 16×16 cells
python3 Tools/sprite2swift.py walk_strip.png --cell 16 --name walk

# Light sprite on a dark cell
python3 Tools/sprite2swift.py cell.png --name idle1 --invert --threshold 100
```

Options: `--cell N` (cell size, default 16), `--threshold 0-255`,
`--invert` (light pixels are "on"), `--name`, `--no-ascii`.

Requires Pillow (`pip3 install Pillow`). Validated by round-trip: rendering a
known `[UInt16]` sprite to PNG and converting back reproduces the exact hex.

## swift2png.py — SpriteFrame → PNG (the reverse)

Exports existing sprites out to editable PNGs so you can refine a clean version
over the current one, completing the round-trip.

```bash
# One named constant
python3 Tools/swift2png.py "Packages/StepkinKit/Sources/StepkinSprites/Pets/SpriteCatalog+Hopkin.swift" \
    --const sideWalk1 --out /tmp/sprites

# Every SpriteFrame in a file (e.g. all projectiles)
python3 Tools/swift2png.py "Packages/StepkinKit/Sources/StepkinSprites/Catalog/SpriteCatalog+Projectiles.swift" \
    --all --out /tmp/sprites
```

Rendered black-on-white, scaled up (`--scale`, default 16) for editing.

## Working set

`Tools/sprites_png/` (git-ignored) holds PNGs exported from the Swift source,
ready to edit — regenerate any time with `swift2png.py`.

## Recommended workflow (round-trip)

1. **Export** the sprite(s) you want to change with `swift2png.py`, or start a
   new PNG from scratch.
2. **Draw / refine** a clean 1-bit version in a pixel editor — Aseprite or the
   free web tool Piskel. Pure black-on-white gives the cleanest result.
3. **Export** as PNG (or a horizontal strip for multi-frame animations).
4. **Convert** with `sprite2swift.py` and paste into the species file under
   `Packages/StepkinKit/Sources/StepkinSprites/Pets/SpriteCatalog+<Species>.swift` (side profiles)
   or `Packages/StepkinKit/Sources/StepkinSprites/Catalog/SpriteCatalog+Projectiles.swift`.
5. **Build & run** on the Apple Watch Ultra 3 sim and eyeball it.

## Source quality matters

The converter only thresholds — it can't invent detail. Feed it **clean 1-bit
(black/white) art**. Shaded/anti-aliased colour art thresholds into noisy,
speckled silhouettes — flatten to 1-bit and clean it up first.

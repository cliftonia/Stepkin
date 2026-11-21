#!/usr/bin/env python3
"""Render Stepkin app-icon concepts from our REAL 16x16 sprites on the LCD screen.

Authentic, simple, and our own art — black pixels on the olive-green LCD
(matching LCDPixelOn / LCDBackground in the asset catalog). 1024x1024 masters.
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "icon-concepts-lcd")
SIZE = 1024

# LCD palette (from Assets.xcassets)
GREEN = (0x8B, 0xAC, 0x6E)          # LCDBackground
BLACK = (0x00, 0x00, 0x00)          # LCDPixelOn
OFF = (0x80, 0xA0, 0x64)            # faint unlit pixel (slightly darker green)
NIGHT_BG = (18, 20, 16)
NIGHT_FG = (235, 240, 230)
BEZEL = (28, 30, 26)

EGG = [0x0000, 0x0000, 0x0000, 0x03C0, 0x0FF0, 0x1FF8, 0x3FFC, 0x3FFC,
       0x3FFC, 0x3FFC, 0x1FF8, 0x0FF0, 0x03C0, 0x0000, 0x0000, 0x0000]
DOTKIN = [0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x03C0, 0x0FF0,
          0x1FF8, 0x37B8, 0x3FF8, 0x3FF8, 0x1FF8, 0x0FF0, 0x03C0, 0x0000]
# Speckle holes punched into the egg body for a "spotted" egg
SPOTS = [(6, 6), (9, 7), (7, 9), (10, 9), (8, 11), (11, 6)]


def on(sprite, x, y):
    return (sprite[y] >> (15 - x)) & 1 == 1


def render(sprite, name, bg=GREEN, fg=BLACK, grid=False, bezel=False,
           spots=False, cell=52):
    img = Image.new("RGB", (SIZE, SIZE), bg)
    d = ImageDraw.Draw(img)

    inset = 0
    if bezel:
        d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=180, fill=BEZEL)
        inset = 96
        d.rounded_rectangle([inset, inset, SIZE - 1 - inset, SIZE - 1 - inset],
                            radius=110, fill=bg)

    # Centre on the sprite's lit bounding box, not the full 16x16 grid, so
    # bottom-weighted creatures sit in the middle of the icon.
    lit_cells = [(x, y) for y in range(16) for x in range(16) if on(sprite, x, y)]
    xs = [x for x, _ in lit_cells]
    ys = [y for _, y in lit_cells]
    cx = (min(xs) + max(xs) + 1) / 2
    cy = (min(ys) + max(ys) + 1) / 2
    ox = round(SIZE / 2 - cx * cell)
    oy = round(SIZE / 2 - cy * cell)

    spotset = set(SPOTS) if spots else set()
    grid_cells = lit_cells if not grid else [(x, y) for y in range(16) for x in range(16)]
    for (x, y) in grid_cells:
        lit = on(sprite, x, y) and (x, y) not in spotset
        color = fg if lit else (OFF if grid else None)
        if color is None:
            continue
        px, py = ox + x * cell, oy + y * cell
        d.rectangle([px, py, px + cell - 1, py + cell - 1], fill=color)

    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name))
    print("wrote", name)


def main():
    render(EGG, "lcd_egg_plain.png")
    render(EGG, "lcd_egg_grid.png", grid=True)
    render(EGG, "lcd_egg_spots.png", spots=True)
    render(EGG, "lcd_egg_spots_grid.png", spots=True, grid=True)
    render(EGG, "lcd_egg_bezel.png", bezel=True)
    render(EGG, "lcd_egg_night.png", bg=NIGHT_BG, fg=NIGHT_FG)
    render(DOTKIN, "lcd_dotkin_plain.png")
    render(DOTKIN, "lcd_dotkin_grid.png", grid=True)
    render(DOTKIN, "lcd_dotkin_bezel.png", bezel=True)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""A hand-drawn TALL egg with consistent step run-lengths (no-jaggies rule),
mirror-symmetric like the artist's sprites. Renders the silhouette plus a
filled-bottom / outline-top / crack treatment. 1024x1024 black-on-LCD-green."""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "icon-concepts-lcd")
SIZE = 1024
GREEN = (0x8B, 0xAC, 0x6E)
BLACK = (0x00, 0x00, 0x00)

GW = 16
# half-width per row; runs grow 1,1,1,1,2,2,5 toward the widest -> smooth curve.
HALF = [1, 2, 3, 4, 5, 5, 6, 6, 7, 7, 7, 7, 7, 6, 6, 5, 4, 2]
GH = len(HALF)
CENTER_L, CENTER_R = 7, 8


def spans():
    out = []
    for hw in HALF:
        out.append((CENTER_L - (hw - 1), CENTER_R + (hw - 1)))
    return out


def egg_cells():
    s = spans()
    return {(x, y) for y, (lo, hi) in enumerate(s) for x in range(lo, hi + 1)}, s


def render(name, cells, footprint, bg=GREEN, fg=BLACK):
    xs = [x for x, _ in footprint]; ys = [y for _, y in footprint]
    cx = (min(xs) + max(xs) + 1) / 2
    cy = (min(ys) + max(ys) + 1) / 2
    cell = int(SIZE * 0.66 / GH)
    ox = round(SIZE / 2 - cx * cell)
    oy = round(SIZE / 2 - cy * cell)
    img = Image.new("RGB", (SIZE, SIZE), bg)
    d = ImageDraw.Draw(img)
    for (x, y) in cells:
        px, py = ox + x * cell, oy + y * cell
        d.rectangle([px, py, px + cell - 1, py + cell - 1], fill=fg)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name))
    print("wrote", name)


def main():
    egg, s = egg_cells()

    # 1. plain silhouette (sanity check the shape is clean)
    render("clean_solid.png", set(egg), egg)

    # 2. filled + dashed crack (artist eggCrack1 style) on the tall egg
    crack_row = 9
    dashed = set(egg)
    lo, hi = s[crack_row]
    for x in range(lo, hi + 1):
        if (x - lo) % 3 != 1:                      # remove pixels -> dashed crack
            dashed.discard((x, crack_row))
    render("clean_crack.png", dashed, egg)

    # 3. outline top, filled bottom, green crack gap
    def border(x, y):
        return any((x + dx, y + dy) not in egg
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    treat = set()
    for (x, y) in egg:
        if y > crack_row:
            treat.add((x, y))
        elif y < crack_row and border(x, y):
            treat.add((x, y))
    render("clean_filledbottom.png", treat, egg)
    render("clean_crack_night.png", dashed, egg, bg=(18, 20, 16), fg=(235, 240, 230))


if __name__ == "__main__":
    main()

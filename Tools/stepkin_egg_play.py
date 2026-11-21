#!/usr/bin/env python3
"""Riff on the clean tall egg: crack styles (dashed, jagged, diagonal, lightning,
branch) x backdrops (plain, grid, radar). 1024x1024 black-on-LCD-green."""
import math
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "icon-concepts-lcd")
SIZE = 1024
GREEN = (0x8B, 0xAC, 0x6E)
BLACK = (0x00, 0x00, 0x00)
LINE = (0x76, 0x97, 0x58)      # faint darker-green for grid/radar
SWEEP = (0x9C, 0xBE, 0x7C)     # slightly brighter for the radar sweep

GW = 16
HALF = [1, 2, 3, 4, 5, 5, 6, 6, 7, 7, 7, 7, 7, 6, 6, 5, 4, 2]
GH = len(HALF)
CL, CR = 7, 8
CRACK = 9


def spans():
    return [(CL - (h - 1), CR + (h - 1)) for h in HALF]


def egg_set():
    s = spans()
    return {(x, y) for y, (lo, hi) in enumerate(s) for x in range(lo, hi + 1)}, s


def carve(egg, s, style):
    cells = set(egg)
    lo, hi = s[CRACK]
    if style == "dashed":
        for x in range(lo, hi + 1):
            if (x - lo) % 3 != 1:
                cells.discard((x, CRACK))
    elif style == "jagged":
        saw = [0, 1, 0, -1]
        for x in range(lo, hi + 1):
            cells.discard((x, CRACK + saw[(x - lo) % 4]))
    elif style == "diagonal":
        for i, x in enumerate(range(lo, hi + 1)):
            y = CRACK - 2 + round(i * 4.0 / (hi - lo))
            cells.discard((x, y))
    elif style == "lightning":
        bolt = [0, 0, 1, 1, 0, -1, -1, 0, 1, 0]
        for y in range(3, GH - 2):
            x = (CL + 1) + bolt[y % len(bolt)]
            if (x, y) in cells:
                cells.discard((x, y))
    elif style == "branch":
        for x in range(lo, hi + 1):
            if (x - lo) % 3 != 1:
                cells.discard((x, CRACK))
        for y in range(CRACK + 1, CRACK + 4):
            cells.discard((CL + 1, y))
    return cells


def backdrop(d, style):
    cxc = cyc = SIZE / 2
    if style == "grid":
        step = SIZE // 12
        for i in range(0, SIZE + 1, step):
            d.line([(i, 0), (i, SIZE)], fill=LINE, width=2)
            d.line([(0, i), (SIZE, i)], fill=LINE, width=2)
    elif style == "radar":
        for r in (0.46, 0.34, 0.22, 0.10):
            rr = SIZE * r
            d.ellipse([cxc - rr, cyc - rr, cxc + rr, cyc + rr], outline=LINE, width=3)
        d.line([(0, cyc), (SIZE, cyc)], fill=LINE, width=2)
        d.line([(cxc, 0), (cxc, SIZE)], fill=LINE, width=2)
        # ticks on the outer ring
        for ang in range(0, 360, 30):
            a = math.radians(ang)
            r1, r2 = SIZE * 0.46, SIZE * 0.49
            d.line([(cxc + r1 * math.cos(a), cyc + r1 * math.sin(a)),
                    (cxc + r2 * math.cos(a), cyc + r2 * math.sin(a))], fill=LINE, width=3)
        # sweep line
        a = math.radians(-50)
        d.line([(cxc, cyc), (cxc + SIZE * 0.46 * math.cos(a), cyc + SIZE * 0.46 * math.sin(a))],
               fill=SWEEP, width=4)


def render(name, crack="dashed", bg="plain"):
    egg, s = egg_set()
    cells = carve(egg, s, crack)
    xs = [x for x, _ in egg]; ys = [y for _, y in egg]
    cx = (min(xs) + max(xs) + 1) / 2
    cy = (min(ys) + max(ys) + 1) / 2
    cell = int(SIZE * 0.58 / GH)
    ox = round(SIZE / 2 - cx * cell)
    oy = round(SIZE / 2 - cy * cell)
    img = Image.new("RGB", (SIZE, SIZE), GREEN)
    d = ImageDraw.Draw(img)
    backdrop(d, bg)
    for (x, y) in cells:
        px, py = ox + x * cell, oy + y * cell
        d.rectangle([px, py, px + cell - 1, py + cell - 1], fill=BLACK)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name))
    print("wrote", name)


if __name__ == "__main__":
    for crack in ("dashed", "jagged", "diagonal", "lightning", "branch"):
        render(f"play_{crack}_radar.png", crack, "radar")
    for crack in ("jagged", "diagonal", "lightning"):
        render(f"play_{crack}_grid.png", crack, "grid")
    render("play_jagged_plain.png", "jagged", "plain")
    render("play_diagonal_plain.png", "diagonal", "plain")

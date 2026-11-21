#!/usr/bin/env python3
"""Final LCD egg icon: the approved egg2 ovoid, with a hollow outline top, a
green zigzag crack, and a solid-filled bottom (optional peeking eyes + a
lightning crack into the shell). 1-bit black-on-LCD-green, crisp at 1024x1024."""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "icon-concepts-lcd")
SIZE = 1024
GREEN = (0x8B, 0xAC, 0x6E)
BLACK = (0x00, 0x00, 0x00)

# --- The approved egg2 silhouette (asymmetric ovoid) ---
W, H = 20, 24
A, B, K = 0.34, 0.42, 0.40


def egg_inside(x, y):
    cx, cy = W / 2.0, H / 2.0
    hits = 0
    ss = 6
    for sy in range(ss):
        for sx in range(ss):
            px = x + (sx + 0.5) / ss
            py = y + (sy + 0.5) / ss
            v = (py - cy) / (B * H)
            aeff = A * W * (1 + K * v)
            u = (px - cx) / aeff
            if u * u + v * v <= 1.0:
                hits += 1
    return hits > (ss * ss) // 2


def build(eyes=True, lightning=True):
    inside = {(x, y) for y in range(H) for x in range(W) if egg_inside(x, y)}

    def border(x, y):
        return any((x + dx, y + dy) not in inside
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))

    base = int(H * 0.50)
    saw = [0, 1, 1, 0, -1, -1]                     # gentle zigzag crack
    crack = {x: base + saw[x % len(saw)] for x in range(W)}

    cells = set()
    for (x, y) in inside:
        cy = crack[x]
        if y > cy:
            cells.add((x, y))                      # solid filled bottom
        elif y < cy and border(x, y):
            cells.add((x, y))                      # hollow outline top
        # y == cy -> green crack gap

    if lightning:                                  # green lightning into the shell
        cx = W // 2
        for c in [(cx, base + 1), (cx, base + 2), (cx + 1, base + 3),
                  (cx + 1, base + 4), (cx, base + 5)]:
            cells.discard(c)

    if eyes:                                       # two eyes peeking over the rim
        for ex in (W // 2 - 4, W // 2 + 2):
            for dx in range(2):
                for dy in range(2):
                    cells.discard((ex + dx, base + 2 + dy))
    return inside, cells


def render(name, eyes=True, lightning=True, bg=GREEN, fg=BLACK):
    inside, cells = build(eyes, lightning)
    xs = [x for x, _ in inside]; ys = [y for _, y in inside]
    cx = (min(xs) + max(xs) + 1) / 2
    cy = (min(ys) + max(ys) + 1) / 2
    cell = int(SIZE * 0.78 / H)
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


if __name__ == "__main__":
    render("eggF_plain.png", eyes=False, lightning=False)
    render("eggF_lightning.png", eyes=False, lightning=True)
    render("eggF_eyes.png", eyes=True, lightning=False)
    render("eggF_eyes_lightning.png", eyes=True, lightning=True)
    render("eggF_eyes_night.png", eyes=True, lightning=False,
           bg=(18, 20, 16), fg=(235, 240, 230))

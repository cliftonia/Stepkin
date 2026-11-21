#!/usr/bin/env python3
"""Render the REAL hand-drawn egg sprites (from SharedSprites.swift) as LCD
icons, plus a clean 'outline-top / filled-bottom / crack' treatment derived from
the artist's clean oval (no procedural jaggies). 1024x1024, black-on-LCD-green."""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "icon-concepts-lcd")
SIZE = 1024
GREEN = (0x8B, 0xAC, 0x6E)
BLACK = (0x00, 0x00, 0x00)

# Exact bitmaps from Packages/StepkinKit/Sources/StepkinSprites/Shared/SharedSprites.swift
EGG_STILL = [0x0000, 0x0000, 0x0000, 0x03C0, 0x0FF0, 0x1FF8, 0x3FFC, 0x3FFC,
             0x3FFC, 0x3FFC, 0x1FF8, 0x0FF0, 0x03C0, 0x0000, 0x0000, 0x0000]
EGG_CRACK1 = [0x0000, 0x0000, 0x0000, 0x03C0, 0x0FF0, 0x1FF8, 0x3FFC, 0x2814,
              0x3FFC, 0x3FFC, 0x1FF8, 0x0FF0, 0x03C0, 0x0000, 0x0000, 0x0000]
EGG_CRACK2 = [0x0000, 0x0000, 0x0000, 0x03C0, 0x0FF0, 0x1818, 0x3FFC, 0x2004,
              0x3FFC, 0x1818, 0x1FF8, 0x0FF0, 0x03C0, 0x0000, 0x0000, 0x0000]
EGG_CRACK3 = [0x1008, 0x0810, 0x0000, 0x0240, 0x0C30, 0x1818, 0x1818, 0x0000,
              0x0000, 0x1818, 0x1818, 0x0C30, 0x0240, 0x0000, 0x0810, 0x1008]


def lit(sprite):
    return {(x, y) for y in range(16) for x in range(16)
            if (sprite[y] >> (15 - x)) & 1}


def treat(sprite, crack_row=8):
    """Hollow outline above the crack, solid fill below, on the artist's oval."""
    inside = lit(sprite)

    def border(x, y):
        return any((x + dx, y + dy) not in inside
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))

    cells = set()
    for (x, y) in inside:
        if y >= crack_row:
            cells.add((x, y))            # filled bottom
        elif y < crack_row - 1 and border(x, y):
            cells.add((x, y))            # outline top (leave row crack_row-1 as the green crack)
    return inside, cells


def render(name, cells, footprint=None, bg=GREEN, fg=BLACK):
    fp = footprint or cells
    xs = [x for x, _ in fp]; ys = [y for _, y in fp]
    cx = (min(xs) + max(xs) + 1) / 2
    cy = (min(ys) + max(ys) + 1) / 2
    cell = int(SIZE * 0.62 / 16)
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
    render("real_still.png", lit(EGG_STILL))
    render("real_crack1.png", lit(EGG_CRACK1))
    render("real_crack2.png", lit(EGG_CRACK2))
    render("real_crack3.png", lit(EGG_CRACK3))
    ins, cells = treat(EGG_STILL)
    render("real_filledbottom.png", cells, footprint=ins)
    render("real_crack1_night.png", lit(EGG_CRACK1), bg=(18, 20, 16), fg=(235, 240, 230))

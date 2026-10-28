#!/usr/bin/env python3
"""Export SpriteFrame [UInt16] sprites from Swift source into editable PNGs.

The reverse of sprite2swift.py — completes the round-trip so you can open an
existing sprite in a pixel editor (Aseprite/Piskel), refine a clean 1-bit
version over it, then convert back with sprite2swift.py.

Export one named constant:
    python3 Tools/swift2png.py "Packages/StepkinKit/Sources/StepkinSprites/Pets/SpriteCatalog+Hopkin.swift" \\
        --const sideWalk1 --out /tmp/sprites

Export every SpriteFrame constant in a file (e.g. all projectiles):
    python3 Tools/swift2png.py "Packages/StepkinKit/Sources/StepkinSprites/Catalog/SpriteCatalog+Projectiles.swift" \\
        --all --out /tmp/sprites

Rendered black-on-white and scaled up (--scale, default 16) for easy editing.
"""
import argparse
import re
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: pip3 install Pillow")

SIZE = 16
CONST_RE = re.compile(
    r"let\s+(\w+)\s*=\s*SpriteFrame\(rows:\s*\[(.*?)\]\s*\)",
    re.DOTALL,
)
HEX_RE = re.compile(r"0x[0-9A-Fa-f]{1,4}")


def parse_constants(source):
    """Yield (name, [16 row ints]) for each SpriteFrame literal found."""
    for match in CONST_RE.finditer(source):
        name = match.group(1)
        values = [int(h, 16) for h in HEX_RE.findall(match.group(2))]
        if len(values) == SIZE:
            yield name, values


def render(rows, scale):
    img = Image.new("RGB", (SIZE * scale, SIZE * scale), (255, 255, 255))
    px = img.load()
    for y, value in enumerate(rows):
        for x in range(SIZE):
            if (value >> (15 - x)) & 1:
                for dy in range(scale):
                    for dx in range(scale):
                        px[x * scale + dx, y * scale + dy] = (0, 0, 0)
    return img


def main():
    parser = argparse.ArgumentParser(description="SpriteFrame -> PNG")
    parser.add_argument("swift")
    parser.add_argument("--const", help="Name of a single constant to export")
    parser.add_argument("--all", action="store_true", help="Export every sprite")
    parser.add_argument("--scale", type=int, default=16)
    parser.add_argument("--out", default=".")
    args = parser.parse_args()

    source = open(args.swift, encoding="utf-8").read()
    sprites = dict(parse_constants(source))
    if not sprites:
        sys.exit("No SpriteFrame constants found.")

    if args.all:
        targets = sprites.items()
    elif args.const:
        if args.const not in sprites:
            sys.exit(f"Constant '{args.const}' not found. "
                     f"Available: {', '.join(sprites)}")
        targets = [(args.const, sprites[args.const])]
    else:
        sys.exit("Pass --const NAME or --all.")

    for name, rows in targets:
        path = f"{args.out.rstrip('/')}/{name}.png"
        render(rows, args.scale).save(path)
        print(f"wrote {path}")


if __name__ == "__main__":
    main()

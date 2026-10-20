#!/usr/bin/env python3
"""Rasterize the ZXL squircle icon and the 无限远程 wordmarks.

The 16px image is a hand-tuned pixel monogram. Larger sizes come from
res/wuxian-icon.svg so the letters stay geometric instead of blurred.
"""

import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "res" / "wuxian-icon.svg"
FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
# Noto Sans CJK TTC: 0 JP, 1 KR, 2 SC, 3 TC, 4 HK
FONT_INDEX = 2
BG = (8, 14, 26, 255)
INK = (244, 254, 255, 255)


def render_svg(size: int) -> Image.Image:
    out = Path(f"/tmp/wuxian-icon-{size}.png")
    subprocess.check_call(
        ["rsvg-convert", "-w", str(size), "-h", str(size), str(SVG), "-o", str(out)]
    )
    return Image.open(out).convert("RGBA")


def pixel_16() -> Image.Image:
    g = [
        "................",
        "................",
        "................",
        "..###.#.#.#.....",
        "..###.#.#.#.....",
        "....#.#.#.#.....",
        "...#...#..#.....",
        "..#....#..#.....",
        "..#....#..#.....",
        "..###.#.#.###...",
        "..###.#.#.###...",
        "..###.#.#.###...",
        "................",
        "................",
        "................",
        "................",
    ]
    im = Image.new("RGBA", (16, 16), BG)
    px = im.load()
    for y in range(16):
        for x in range(16):
            corner = (x + y) < 2 or (15 - x + y) < 2 or (x + 15 - y) < 2 or ((15 - x) + (15 - y)) < 2
            if corner:
                px[x, y] = (0, 0, 0, 0)
            elif g[y][x] == "#":
                px[x, y] = INK
    return im


def save_ico(path: Path, images):
    # The primary image must be the largest: Pillow skips any size bigger than it.
    largest = max(images, key=lambda im: im.width)
    rest = [im for im in images if im is not largest]
    largest.save(
        path,
        format="ICO",
        sizes=[(im.width, im.height) for im in images],
        append_images=rest,
    )


def wordmark(dark: bool) -> Image.Image:
    text = "无限远程"
    fill = (231, 240, 255, 255) if dark else (8, 14, 26, 255)
    im = Image.new("RGBA", (640, 128), (0, 0, 0, 0))
    icon = render_svg(96)
    im.paste(icon, (8, 16), icon)
    draw = ImageDraw.Draw(im)
    font = ImageFont.truetype(FONT, 64, index=FONT_INDEX)
    draw.text((120, 24), text, font=font, fill=fill)
    return im


def main():
    sizes = {
        16: pixel_16(),
        24: render_svg(24),
        32: render_svg(32),
        48: render_svg(48),
        64: render_svg(64),
        128: render_svg(128),
        256: render_svg(256),
    }
    ordered = [sizes[s] for s in (16, 24, 32, 48, 64, 128, 256)]
    ico_targets = [
        ROOT / "res" / "icon.ico",
        ROOT / "res" / "tray-icon.ico",
        ROOT / "flutter" / "windows" / "runner" / "resources" / "app_icon.ico",
    ]
    for target in ico_targets:
        save_ico(target, ordered)
    sizes[256].save(ROOT / "res" / "icon.png")
    sizes[32].save(ROOT / "res" / "32x32.png")
    sizes[64].save(ROOT / "res" / "64x64.png")
    sizes[128].save(ROOT / "res" / "128x128.png")
    sizes[256].save(ROOT / "res" / "128x128@2x.png")
    sizes[256].save(ROOT / "flutter" / "assets" / "icon.png")
    shutil.copyfile(SVG, ROOT / "flutter" / "assets" / "icon.svg")
    shutil.copyfile(SVG, ROOT / "res" / "logo.svg")
    wordmark(True).save(ROOT / "flutter" / "assets" / "logo.png")
    wordmark(True).save(ROOT / "flutter" / "assets" / "logo_dark.png")
    wordmark(False).save(ROOT / "flutter" / "assets" / "logo_light.png")
    sheet = Image.new("RGB", (16 * 8 + 32 * 4 + 256 + 48, 280), (12, 16, 28))
    x = 16
    for s, scale in ((16, 8), (32, 4), (256, 1)):
        tile = sizes[s].resize((s * scale, s * scale), Image.Resampling.NEAREST if s < 64 else Image.Resampling.LANCZOS)
        sheet.paste(tile, (x, 24), tile)
        x += tile.width + 16
    out = Path("/opt/cursor/artifacts/wuxian-icon-preview.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    sizes[256].save("/opt/cursor/artifacts/wuxian-icon-256.png")
    print("wrote", out)


if __name__ == "__main__":
    main()

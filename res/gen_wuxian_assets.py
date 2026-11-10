#!/usr/bin/env python3
"""Rasterize the charcoal tile and the interlocking-band mark.

res/wuxian-icon.svg is a geometric redraw. The selected concept image has a
white margin and a soft bevel, so it is not copied into an ico or png.
Each size is rendered from the vector at that pixel size. Nothing here is a
downsample of the 256px bitmap.
"""

import shutil
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "res" / "wuxian-icon.svg"
MARK = ROOT / "res" / "wuxian-mark.svg"


def render_svg(svg: Path, size: int) -> Image.Image:
    out = Path(f"/tmp/wuxian-render-{svg.stem}-{size}.png")
    subprocess.check_call(
        ["rsvg-convert", "-w", str(size), "-h", str(size), str(svg), "-o", str(out)]
    )
    return Image.open(out).convert("RGBA")


def save_ico(path: Path, images):
    largest = max(images, key=lambda im: im.width)
    rest = [im for im in images if im is not largest]
    largest.save(
        path,
        format="ICO",
        sizes=[(im.width, im.height) for im in images],
        append_images=rest,
    )


def composite_wordmark(path: Path, icon: Image.Image) -> None:
    if not path.exists():
        return
    im = Image.open(path).convert("RGBA")
    cleared = im.copy()
    # The previous tile sat in the left slot; keep the existing wordmark text.
    blank = Image.new("RGBA", (112, im.height), (0, 0, 0, 0))
    cleared.paste(blank, (0, 0))
    tile = icon.resize((96, 96), Image.Resampling.LANCZOS)
    cleared.paste(tile, (8, (im.height - 96) // 2), tile)
    cleared.save(path)


# 16px optical drawing of the two hooks. Larger tray sizes are integer
# nearest-neighbor scales of this grid, not a blur of the 256px tile.
_GLYPH_16 = [
    "................",
    "................",
    "................",
    "................",
    "..######........",
    "..##..##........",
    "..##..######....",
    "..##..##..##....",
    "..######..##....",
    "......##..##....",
    "......######....",
    "................",
    "................",
    "................",
    "................",
    "................",
]


def _glyph16(color):
    image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    px = image.load()
    for y, row in enumerate(_GLYPH_16):
        for x, ch in enumerate(row):
            if ch == "#":
                px[x, y] = color
    return image


def pixel_glyph(size, color):
    base = _glyph16(color)
    if size == 16:
        return base
    if size == 24:
        canvas = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        canvas.paste(base, (4, 4), base)
        return canvas
    if size % 16 != 0:
        raise ValueError(size)
    return base.resize((size, size), Image.Resampling.NEAREST)


def _in_round_rect(x, y, size, radius):
    if radius <= 0:
        return True
    corners = (
        (radius - 1, radius - 1),
        (size - radius, radius - 1),
        (radius - 1, size - radius),
        (size - radius, size - radius),
    )
    for cx, cy in corners:
        if (x < radius and y < radius and (cx, cy) == corners[0]) or (
            x >= size - radius and y < radius and (cx, cy) == corners[1]
        ) or (x < radius and y >= size - radius and (cx, cy) == corners[2]) or (
            x >= size - radius and y >= size - radius and (cx, cy) == corners[3]
        ):
            if (x - cx) ** 2 + (y - cy) ** 2 > radius * radius:
                return False
    return True


def plated_tray(size):
    """Charcoal plate plus cream hooks. Visible on light and dark taskbars.

    32 is an exact 2x of the 16px plate. 24 keeps that 16px plate centered
    so the stroke stays on whole pixels.
    """
    if size == 32:
        return plated_tray(16).resize((32, 32), Image.Resampling.NEAREST)
    if size == 24:
        canvas = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        plate = plated_tray(16)
        canvas.paste(plate, (4, 4), plate)
        return canvas
    glyph = _glyph16((244, 240, 230, 255))
    plate = (44, 46, 50, 255)
    image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    px = image.load()
    src = glyph.load()
    for y in range(16):
        for x in range(16):
            if not _in_round_rect(x, y, 16, 3):
                continue
            px[x, y] = src[x, y] if src[x, y][3] > 16 else plate
    return image


def opaque_ratio(image: Image.Image) -> float:
    pixels = list(image.getdata())
    return sum(1 for px in pixels if px[3] > 16) / float(len(pixels) or 1)


def main():
    full = {}
    for size in (16, 24, 32, 48, 64, 128, 256, 1024):
        full[size] = render_svg(SVG, size)
    black = (0, 0, 0, 255)
    mac_glyph = {s: pixel_glyph(s, black) for s in (16, 32, 64)}
    win_glyph = {s: plated_tray(s) for s in (16, 24, 32)}
    for image in mac_glyph.values():
        ratio = opaque_ratio(image)
        if ratio > 0.45:
            raise SystemExit(f"macOS tray glyph is too opaque ({ratio:.2%})")

    exe_sizes = [full[s] for s in (16, 24, 32, 48, 64, 128, 256)]
    for target in (
        ROOT / "res" / "icon.ico",
        ROOT / "flutter" / "windows" / "runner" / "resources" / "app_icon.ico",
    ):
        save_ico(target, exe_sizes)
    save_ico(
        ROOT / "res" / "tray-icon.ico",
        [win_glyph[s] for s in (16, 24, 32)],
    )

    full[256].save(ROOT / "res" / "icon.png")
    full[32].save(ROOT / "res" / "32x32.png")
    full[64].save(ROOT / "res" / "64x64.png")
    full[128].save(ROOT / "res" / "128x128.png")
    full[256].save(ROOT / "res" / "128x128@2x.png")
    full[256].save(ROOT / "flutter" / "assets" / "icon.png")
    win_glyph[32].save(ROOT / "flutter" / "assets" / "tray_icon.png")
    mac_glyph[64].save(ROOT / "flutter" / "assets" / "tray_glyph.png")
    full[1024].save(ROOT / "res" / "mac-icon.png")
    mac_glyph[64].save(ROOT / "res" / "mac-tray-dark-x2.png")
    shutil.copyfile(SVG, ROOT / "flutter" / "assets" / "icon.svg")
    shutil.copyfile(SVG, ROOT / "res" / "logo.svg")
    for name in ("logo.png", "logo_dark.png", "logo_light.png"):
        composite_wordmark(ROOT / "flutter" / "assets" / name, full[256])

    # Actual Windows/Linux frames on white and near-black, nearest-neighbor
    # enlarged so the 16px grid stays visible.
    contrast = Image.new("RGB", (16 * 8 * 3 + 80, 16 * 8 * 2 + 48), (80, 80, 80))
    for row, bg in enumerate(((255, 255, 255), (22, 22, 24))):
        x = 16
        for size in (16, 24, 32):
            scale = 128 // size
            tile = win_glyph[size].resize(
                (size * scale, size * scale), Image.Resampling.NEAREST
            )
            cell = Image.new("RGB", tile.size, bg)
            cell.paste(tile, mask=tile.split()[-1])
            contrast.paste(cell, (x, 16 + row * (128 + 16)))
            x += 128 + 16
    contrast_path = Path("/opt/cursor/artifacts/tray-icon-contrast.png")
    contrast.save(contrast_path)
    print("wrote", contrast_path)
    Path("/opt/cursor/artifacts").mkdir(parents=True, exist_ok=True)
    full[256].save("/opt/cursor/artifacts/wuxian-icon-256.png")


if __name__ == "__main__":
    main()

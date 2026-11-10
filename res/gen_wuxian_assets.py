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


def main():
    full = {}
    for size in (16, 24, 32, 48, 64, 128, 256, 1024):
        full[size] = render_svg(SVG, size)
    mark = {}
    for size in (16, 24, 32, 48, 60):
        mark[size] = render_svg(MARK, size)

    exe_sizes = [full[s] for s in (16, 24, 32, 48, 64, 128, 256)]
    for target in (
        ROOT / "res" / "icon.ico",
        ROOT / "flutter" / "windows" / "runner" / "resources" / "app_icon.ico",
    ):
        save_ico(target, exe_sizes)
    save_ico(ROOT / "res" / "tray-icon.ico", [full[s] for s in (16, 24, 32)])

    full[256].save(ROOT / "res" / "icon.png")
    full[32].save(ROOT / "res" / "32x32.png")
    full[64].save(ROOT / "res" / "64x64.png")
    full[128].save(ROOT / "res" / "128x128.png")
    full[256].save(ROOT / "res" / "128x128@2x.png")
    full[256].save(ROOT / "flutter" / "assets" / "icon.png")
    full[32].save(ROOT / "flutter" / "assets" / "tray_icon.png")
    full[1024].save(ROOT / "res" / "mac-icon.png")
    mark[60].save(ROOT / "res" / "mac-tray-dark-x2.png")
    mark[48].save(ROOT / "res" / "mac-tray-light-x2.png")
    shutil.copyfile(SVG, ROOT / "flutter" / "assets" / "icon.svg")
    shutil.copyfile(SVG, ROOT / "res" / "logo.svg")
    for name in ("logo.png", "logo_dark.png", "logo_light.png"):
        composite_wordmark(ROOT / "flutter" / "assets" / name, full[256])

    sheet = Image.new("RGB", (1100, 320), (24, 24, 26))
    x = 16
    for size, scale in ((16, 8), (24, 6), (32, 4), (256, 1)):
        tile = full[size].resize(
            (size * scale, size * scale), Image.Resampling.NEAREST
        )
        sheet.paste(tile, (x, 24), tile)
        x += tile.width + 16
    preview = Path("/opt/cursor/artifacts/wuxian-icon-preview.png")
    preview.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(preview)
    full[256].save("/opt/cursor/artifacts/wuxian-icon-256.png")
    full[32].save("/opt/cursor/artifacts/wuxian-icon-32.png")
    full[16].save("/opt/cursor/artifacts/wuxian-icon-16.png")
    print("wrote", preview)


if __name__ == "__main__":
    main()

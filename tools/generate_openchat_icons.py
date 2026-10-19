"""Generate OpenChat launcher icons (Android, iOS, Web).

Run from the repository root:
    python tools/generate_openchat_icons.py
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024
BG_TOP = (7, 26, 43)
BG_BOTTOM = (14, 116, 144)
ACCENT = (34, 211, 238)
BUBBLE = (248, 250, 252)
INNER = (11, 37, 54)


def background(size: int = SIZE) -> Image.Image:
    image = Image.new("RGB", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / (size - 1)
        color = tuple(round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3))
        for x in range(size):
            pixels[x, y] = color
    return image


def draw_mark(draw: ImageDraw.ImageDraw, scale: float, dx: float = 0, dy: float = 0) -> None:
    def p(value: float) -> float:
        return value * scale + dx

    def q(value: float) -> float:
        return value * scale + dy

    draw.rounded_rectangle(
        (p(190), q(300), p(760), q(650)), radius=p(100), fill=BUBBLE
    )
    draw.polygon(
        [(p(300), q(600)), (p(300), q(760)), (p(450), q(650))], fill=BUBBLE
    )
    draw.rounded_rectangle((p(285), q(405), p(665), q(455)), radius=p(25), fill=INNER)
    draw.rounded_rectangle((p(285), q(510), p(580), q(560)), radius=p(25), fill=INNER)
    draw.ellipse((p(690), q(300), p(790), q(400)), fill=ACCENT)


def master() -> Image.Image:
    image = background()
    draw_mark(ImageDraw.Draw(image), 1.0)
    return image


def foreground() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_mark(ImageDraw.Draw(image), 0.78, dx=112, dy=112)
    return image


def write_png(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.LANCZOS).save(path, "PNG", optimize=True)


def android(base: Image.Image, fg: Image.Image) -> None:
    density = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for name, size in density.items():
        write_png(base, ROOT / "android/app/src/main/res" / f"mipmap-{name}" / "ic_launcher.png", size)
    write_png(fg, ROOT / "android/app/src/main/res/drawable/ic_launcher_foreground.png", 432)
    anydpi = ROOT / "android/app/src/main/res/mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""
    (anydpi / "ic_launcher.xml").write_text(xml, encoding="utf-8")
    (anydpi / "ic_launcher_round.xml").write_text(xml, encoding="utf-8")


def ios(base: Image.Image) -> None:
    folder = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((folder / "Contents.json").read_text(encoding="utf-8"))
    for item in contents["images"]:
        size = float(item["size"].split("x")[0])
        scale = int(item["scale"].rstrip("x"))
        write_png(base, folder / item["filename"], round(size * scale))


def web(base: Image.Image) -> None:
    folder = ROOT / "web/icons"
    write_png(base, folder / "Icon-192.png", 192)
    write_png(base, folder / "Icon-512.png", 512)
    masked = Image.new("RGB", (SIZE, SIZE), BG_TOP)
    masked.paste(base.resize((820, 820), Image.LANCZOS), (102, 102))
    write_png(masked, folder / "Icon-maskable-192.png", 192)
    write_png(masked, folder / "Icon-maskable-512.png", 512)
    write_png(base, ROOT / "web/favicon.png", 32)


def main() -> None:
    base = master()
    fg = foreground()
    android(base, fg)
    ios(base)
    web(base)
    write_png(base, ROOT / "assets/app_icon.png", 1024)
    print("OpenChat icons generated.")


if __name__ == "__main__":
    main()

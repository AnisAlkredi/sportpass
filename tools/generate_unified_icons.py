#!/usr/bin/env python3
"""Generate a single SportPass app icon and sync it across app/web/landing."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]


def _rounded_rect(draw: ImageDraw.ImageDraw, box, radius: int, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def build_master_icon(size: int = 1024) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(canvas)
    scale = size / 1024

    # Outer deep-blue gradient.
    top = (5, 16, 44)
    bottom = (7, 33, 76)
    for y in range(size):
        t = y / (size - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,)
        draw.line([(0, y), (size, y)], fill=color)

    # Neon radial glow.
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse(
        (
            int(160 * scale),
            int(120 * scale),
            int(size - 160 * scale),
            int(size - 120 * scale),
        ),
        fill=(17, 229, 185, 76),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(int(65 * scale)))
    canvas.alpha_composite(glow)

    # Main app tile.
    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile_draw = ImageDraw.Draw(tile)
    inset = int(170 * scale)
    radius = int(150 * scale)
    tile_box = (inset, inset, size - inset, size - inset)

    # Tile gradient.
    tile_grad = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tg = ImageDraw.Draw(tile_grad)
    tile_top = (19, 240, 182, 255)
    tile_bottom = (4, 145, 186, 255)
    for y in range(tile_box[1], tile_box[3]):
        t = (y - tile_box[1]) / max(1, (tile_box[3] - tile_box[1] - 1))
        color = tuple(int(tile_top[i] * (1 - t) + tile_bottom[i] * t) for i in range(4))
        tg.line([(tile_box[0], y), (tile_box[2], y)], fill=color)

    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle(tile_box, radius=radius, fill=255)
    tile_grad.putalpha(mask)

    # Tile shadow.
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (
            tile_box[0] + int(6 * scale),
            tile_box[1] + int(14 * scale),
            tile_box[2] + int(6 * scale),
            tile_box[3] + int(14 * scale),
        ),
        radius=radius,
        fill=(0, 0, 0, 110),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(18 * scale)))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(tile_grad)

    # Top gloss strip.
    tile_draw.rounded_rectangle(
        (
            tile_box[0] + int(40 * scale),
            tile_box[1] + int(36 * scale),
            tile_box[2] - int(40 * scale),
            tile_box[1] + int(98 * scale),
        ),
        radius=int(42 * scale),
        fill=(255, 255, 255, 55),
    )
    canvas.alpha_composite(tile)

    # Brand mark: clean white check/pass glyph.
    mark = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    m = ImageDraw.Draw(mark)
    stroke = int(86 * scale)
    m.line(
        (
            int(355 * scale),
            int(560 * scale),
            int(470 * scale),
            int(675 * scale),
            int(690 * scale),
            int(435 * scale),
        ),
        fill=(245, 255, 255, 255),
        width=stroke,
        joint="curve",
    )
    # Accent dot to keep sporty character.
    dot_r = int(34 * scale)
    cx, cy = int(350 * scale), int(420 * scale)
    m.ellipse((cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r), fill=(245, 255, 255, 255))

    mark_shadow = mark.filter(ImageFilter.GaussianBlur(int(8 * scale)))
    mark_shadow = Image.eval(mark_shadow, lambda p: int(p * 0.35))
    canvas.alpha_composite(mark_shadow)
    canvas.alpha_composite(mark)

    return canvas


def save_png(base: Image.Image, size: int, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    out = base.resize((size, size), Image.Resampling.LANCZOS)
    out.save(path, format="PNG")


def save_ico(base: Image.Image, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    base.save(path, format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])


def main():
    base = build_master_icon(1024)

    # Source-of-truth icon asset.
    save_png(base, 1024, ROOT / "assets/branding/sportpass-app-icon.png")

    # Android launcher icons.
    android_targets = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for density, size in android_targets.items():
        save_png(base, size, ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png")

    # iOS AppIcon set.
    ios_targets = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for filename, size in ios_targets.items():
        save_png(base, size, ios_dir / filename)

    # Flutter web icons.
    save_png(base, 32, ROOT / "web/favicon.png")
    save_png(base, 192, ROOT / "web/icons/Icon-192.png")
    save_png(base, 512, ROOT / "web/icons/Icon-512.png")
    save_png(base, 192, ROOT / "web/icons/Icon-maskable-192.png")
    save_png(base, 512, ROOT / "web/icons/Icon-maskable-512.png")

    # Landing app icon assets.
    save_ico(base, ROOT / "landing-next/app/favicon.ico")
    save_png(base, 192, ROOT / "landing-next/public/brand/sportpass-icon-192.png")
    save_png(base, 512, ROOT / "landing-next/public/brand/sportpass-icon-512.png")
    save_png(base, 180, ROOT / "landing-next/public/apple-touch-icon.png")

    # Windows desktop icon.
    save_ico(base, ROOT / "windows/runner/resources/app_icon.ico")

    print("Unified SportPass icons generated successfully.")


if __name__ == "__main__":
    main()

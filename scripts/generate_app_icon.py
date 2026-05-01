#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Coherence" / "Assets.xcassets" / "AppIcon.appiconset" / "icon-1024.png"

SIZE = 1024
CENTER = (SIZE / 2, SIZE / 2)
RADIUS = 362
ACCENT = (123, 168, 170)


def mix(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * max(0.0, min(1.0, t)))


def normalize(v: tuple[float, float, float]) -> tuple[float, float, float]:
    mag = math.sqrt(sum(c * c for c in v))
    return tuple(c / mag for c in v)


def build_background() -> Image.Image:
    cx, cy = CENTER
    pixels: list[tuple[int, int, int]] = []
    max_d = math.hypot(cx, cy)

    for y in range(SIZE):
        for x in range(SIZE):
            d = math.hypot(x - cx, y - cy) / max_d
            vignette = 1.0 - min(1.0, d)
            teal = max(0.0, 1.0 - abs(d - 0.42) * 2.4)
            r = 6 + round(3 * vignette)
            g = 7 + round(7 * vignette + 5 * teal)
            b = 7 + round(7 * vignette + 5 * teal)
            pixels.append((r, g, b))

    image = Image.new("RGB", (SIZE, SIZE))
    image.putdata(pixels)
    return image


def build_orb() -> Image.Image:
    cx, cy = CENTER
    light = normalize((-0.52, -0.66, 0.54))
    orb = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pixels = orb.load()

    for y in range(round(cy - RADIUS) - 2, round(cy + RADIUS) + 3):
        for x in range(round(cx - RADIUS) - 2, round(cx + RADIUS) + 3):
            dx = (x - cx) / RADIUS
            dy = (y - cy) / RADIUS
            d2 = dx * dx + dy * dy
            if d2 > 1:
                continue

            d = math.sqrt(d2)
            z = math.sqrt(max(0.0, 1.0 - d2))
            lambert = max(0.0, dx * light[0] + dy * light[1] + z * light[2])
            facing = max(0.0, z)
            edge = max(0.0, (d - 0.86) / 0.14)
            rim = max(0.0, (d - 0.952) / 0.048)

            light_amount = 0.035 + 0.13 * lambert + 0.05 * facing
            light_amount *= 1.0 - 0.38 * edge

            r = mix(3, ACCENT[0], light_amount)
            g = mix(5, ACCENT[1], light_amount)
            b = mix(5, ACCENT[2], light_amount)

            shadow = max(0.0, dx * 0.55 + dy * 0.65)
            r = round(r * (1.0 - 0.22 * shadow))
            g = round(g * (1.0 - 0.20 * shadow))
            b = round(b * (1.0 - 0.20 * shadow))

            if rim > 0:
                rim_light = 0.62 + 0.30 * lambert
                r = mix(r, ACCENT[0], rim * rim_light)
                g = mix(g, ACCENT[1], rim * rim_light)
                b = mix(b, ACCENT[2], rim * rim_light)

            alpha = 245 if d < 0.99 else round(245 * (1.0 - (d - 0.99) / 0.01))
            pixels[x, y] = (r, g, b, max(0, min(255, alpha)))

    return orb.filter(ImageFilter.GaussianBlur(0.35))


def add_soft_lighting(image: Image.Image) -> Image.Image:
    cx, cy = CENTER

    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (cx - RADIUS - 18, cy - RADIUS - 16, cx + RADIUS + 18, cy + RADIUS + 20),
        fill=(ACCENT[0], ACCENT[1], ACCENT[2], 24),
    )
    image = Image.alpha_composite(image.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(42)))

    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(
        (cx - RADIUS + 28, cy - RADIUS + 34, cx + RADIUS + 28, cy + RADIUS + 34),
        fill=(0, 0, 0, 128),
    )
    image = Image.alpha_composite(image, shadow.filter(ImageFilter.GaussianBlur(28)))

    orb = build_orb()
    image = Image.alpha_composite(image, orb)

    highlight = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    h = Image.new("RGBA", (270, 126), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(h)
    h_draw.ellipse((12, 20, 258, 106), fill=(232, 255, 255, 38))
    h = h.filter(ImageFilter.GaussianBlur(16)).rotate(-23, expand=True, resample=Image.Resampling.BICUBIC)
    highlight.alpha_composite(h, (330, 234))

    clip = Image.new("L", (SIZE, SIZE), 0)
    clip_draw = ImageDraw.Draw(clip)
    clip_draw.ellipse((cx - RADIUS, cy - RADIUS, cx + RADIUS, cy + RADIUS), fill=255)
    highlight.putalpha(Image.composite(highlight.getchannel("A"), Image.new("L", (SIZE, SIZE), 0), clip))
    image = Image.alpha_composite(image, highlight)

    rim = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim)
    bbox = (cx - RADIUS, cy - RADIUS, cx + RADIUS, cy + RADIUS)
    rim_draw.ellipse(bbox, outline=(ACCENT[0], ACCENT[1], ACCENT[2], 190), width=7)
    rim_draw.arc(bbox, 205, 315, fill=(216, 247, 247, 190), width=9)
    image = Image.alpha_composite(image, rim.filter(ImageFilter.GaussianBlur(0.2)))

    return image.convert("RGB")


def main() -> None:
    icon = add_soft_lighting(build_background())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUT, optimize=True)


if __name__ == "__main__":
    main()

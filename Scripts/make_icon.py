#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageFilter
import math
import random

ROOT = Path(__file__).resolve().parents[1]
ICONSET = ROOT / "Resources" / "AppIcon.iconset"
ICONSET.mkdir(parents=True, exist_ok=True)

SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}

def lerp(a, b, t):
    return int(a + (b - a) * t)

def radial_blob(size, cx, cy, radius, color, alpha):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    for y in range(size):
        for x in range(size):
            dx = (x - cx) / radius
            dy = (y - cy) / radius
            d = math.sqrt(dx * dx + dy * dy)
            if d < 1:
                falloff = (1 - d) ** 2.25
                px[x, y] = (*color, int(alpha * falloff))
    return img

def make_base(size):
    img = Image.new("RGBA", (size, size), (3, 5, 16, 255))
    px = img.load()
    for y in range(size):
        for x in range(size):
            gx = x / max(size - 1, 1)
            gy = y / max(size - 1, 1)
            t = (gx * 0.65 + (1 - gy) * 0.35)
            px[x, y] = (
                lerp(3, 5, t),
                lerp(5, 26, t),
                lerp(16, 44, t),
                255,
            )
    return img

def make_icon(size):
    random.seed(4819)
    scale = size / 1024
    img = make_base(size)
    blobs = [
        (0.32, 0.38, 0.58, (24, 106, 255), 190),
        (0.66, 0.44, 0.52, (104, 72, 255), 165),
        (0.52, 0.72, 0.42, (0, 196, 214), 112),
        (0.18, 0.74, 0.36, (118, 43, 205), 108),
    ]
    for cx, cy, radius, color, alpha in blobs:
        layer = radial_blob(size, cx * size, cy * size, radius * size, color, alpha)
        layer = layer.filter(ImageFilter.GaussianBlur(radius=max(1, int(30 * scale))))
        img = Image.alpha_composite(img, layer)

    vignette = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    vpx = vignette.load()
    for y in range(size):
        for x in range(size):
            dx = (x / size - 0.5) * 1.55
            dy = (y / size - 0.5) * 1.55
            d = min(1, math.sqrt(dx * dx + dy * dy))
            vpx[x, y] = (0, 0, 0, int(190 * (d ** 2.1)))
    img = Image.alpha_composite(img, vignette)

    mask = Image.new("L", (size, size), 0)
    mpx = mask.load()
    radius = int(size * 0.215)
    for y in range(size):
        for x in range(size):
            dx = min(x, size - 1 - x)
            dy = min(y, size - 1 - y)
            if dx >= radius or dy >= radius:
                mpx[x, y] = 255
            else:
                dist = math.sqrt((radius - dx) ** 2 + (radius - dy) ** 2)
                mpx[x, y] = 255 if dist <= radius else 0
    img.putalpha(mask)
    return img

for name, size in SIZES.items():
    make_icon(size).save(ICONSET / name)

print(f"Wrote {len(SIZES)} icon images to {ICONSET}")

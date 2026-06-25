# VoidX Gradient

VoidX Gradient is a SwiftUI macOS app for generating dark ambient mesh gradient wallpapers. It renders layered radial light blobs over a near-black navy base, then applies strong blur, vignette, and subtle seeded noise before exporting high-resolution PNG or JPEG files.

## Run

```bash
swift run VoidXGradient
```

## Build a macOS app bundle

```bash
chmod +x Scripts/build_app.sh Scripts/make_icon.py
Scripts/build_app.sh
open "build/VoidX Gradient.app"
```

## Current controls

- 1 to 4 selected colors
- Ambient, Horizon, Nebula, Orbit, and Veil composition patterns
- Random seed and one-click random generation
- Default 1920 x 1080 canvas plus custom width and height
- Blob count, blur, brightness, color intensity, vignette, and noise
- PNG and JPEG export

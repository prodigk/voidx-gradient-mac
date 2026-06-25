# Setup

## Requirements

- macOS 14 or later
- Xcode command line tools
- Python 3 with Pillow for app icon generation

## Development

Run the SwiftUI app directly:

```bash
swift run VoidXGradient
```

Create a release app bundle:

```bash
chmod +x Scripts/build_app.sh Scripts/make_icon.py
Scripts/build_app.sh
```

The app bundle is written to `build/VoidX Gradient.app`.

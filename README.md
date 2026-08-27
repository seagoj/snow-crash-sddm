# Snow Crash SDDM theme

A minimal static SDDM theme for Plasma/SDDM, built around the "Snow Crash" wallpaper by TehAnon.

This theme is a fork of [an original SDDM theme by Jason Sackett](https://www.opendesktop.org/p/2355277) — the login UI is the same Qt 6 layout, with only the bundled artwork and theme identity changed. See `LICENSE` for upstream attribution.

## Files

- `Main.qml`: main theme layout and login UI
- `metadata.desktop`: SDDM theme metadata
- `theme.conf`: editable defaults
- `snow-crash.png`: bundled wallpaper
- `preview.png`: preview image for theme pickers / store listings (identical to `snow-crash.png`)
- `PKGBUILD`: simple Arch/CachyOS package recipe
- `LICENSE`: MIT license text covering the theme code

## Local install

```bash
sudo mkdir -p /usr/share/sddm/themes/snow-crash
sudo cp -r ./* /usr/share/sddm/themes/snow-crash/
```

Then select it in System Settings > Colors & Themes > Login Screen (SDDM), or set:

```ini
[Theme]
Current=snow-crash
```

in `/etc/sddm.conf`.

## Test before switching

```bash
sddm-greeter-qt6 --test-mode --theme "$PWD"
```

If your system only has the Qt5 greeter, use:

```bash
sddm-greeter --test-mode --theme "$PWD"
```

## Build the package

Put `PKGBUILD` and `snow-crash-sddm.tar.gz` in the same directory, then run:

```bash
makepkg -si
```

## Wallpaper attribution

- **Image**: "Snow Crash" — Original Content by [TehAnon](https://www.reddit.com/user/TehAnon/)
- **Source post**: [r/wallpapers, 2013-10-29](https://www.reddit.com/r/wallpapers/comments/1pfzqp/snow_crash_1920x1080_oc/)
- **Original file**: <https://i.imgur.com/AkibqqB.png>
- **License**: Posted as [OC] on Reddit (i.e. shared with permission to redistribute with attribution)

The image bundled in this theme is byte-for-byte equivalent to the source (PNG, 1920×1200). The bundled copy is preserved at original quality; the local file in `~/Projects/nix-config/main/assets/wallpapers/snow-crash.png` is the canonical copy on this machine.

## Theme code license

The theme code (`Main.qml`, `theme.conf`, `metadata.desktop`, `PKGBUILD`) is MIT licensed. See [`LICENSE`](./LICENSE) for the full text. The original theme code is Copyright (c) 2014 Jason Sackett; modifications for the Snow Crash fork are Copyright (c) 2026 Jeremy.

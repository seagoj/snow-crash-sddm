# Proposal: Snow Crash SDDM theme fork

## Why

Fork the upstream `artemisii-moon-eclipse` SDDM theme so it ships the "Snow Crash" wallpaper by TehAnon (originally posted to r/wallpapers in 2013 as [OC]) instead of the NASA lunar-eclipse image, and rebrand the package for distribution under a distinct identity.

## What Changes

- **Add** `snow-crash.png` — bundled wallpaper copied from `~/Projects/nix-config/main/assets/wallpapers/snow-crash.png` (1920×1200, 1.05 MB, PNG)
- **Delete** `background.jpg` — replaced
- **Modify** `Main.qml` — `Image.source` updated to `"snow-crash.png"`
- **Modify** `theme.conf` — `background` key and `title` updated
- **Modify** `metadata.desktop` — `Name`, `Description`, `Author`, `Theme-Id`, `Version` updated for the new identity
- **Modify** `PKGBUILD` — `pkgname`, `pkgdesc`, `source` tarball name, and install paths updated
- **Modify** `preview.png` — replaced with a copy of `snow-crash.png` so the SDDM theme picker preview matches the installed wallpaper
- **Modify** `README.md` — new branding, install commands, and a wallpaper attribution block
- **Add** `LICENSE` — MIT license text with copyright attribution to Jason Sackett (original theme author)

The theme code in `Main.qml` is otherwise unchanged: panel layout, login flow, config keys, error handling, and keybindings all carry over verbatim from the upstream theme.

## Capabilities

### New Capabilities

- `snow-crash-theme`: defines the identity, bundled wallpaper, attribution, packaging metadata, and licensing of the snow-crash SDDM theme distribution.

### Modified Capabilities

None. The theme has no existing specs (this is the first OpenSpec change in the repo), and the upstream theme's behavior is carried over unchanged.

## Impact

- 8 files modified (Main.qml, theme.conf, metadata.desktop, PKGBUILD, preview.png, README.md, and the change to background.jpg → snow-crash.png)
- 1 file added (LICENSE)
- 1 file deleted (background.jpg)
- No dependency changes — `Main.qml` continues to use only the SDDM/Qt 6 APIs already declared (`QtQuick 2.15`)
- No runtime behavior changes — the only behavioral effect is that the greeter shows the Snow Crash wallpaper at login instead of the NASA lunar-eclipse image
- The branch this change lands on (`swap-wallpaper`) is a worktree branch off `main`; merging it into `main` is a separate future concern
- Wiring this theme into `~/Projects/nix-config/main/profiles/nixos/linux-desktop.nix` (currently set to `sddm-astronaut-theme`) is intentionally **out of scope** and deferred to a follow-up change

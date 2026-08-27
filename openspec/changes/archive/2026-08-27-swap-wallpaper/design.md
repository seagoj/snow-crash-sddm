# Design: Snow Crash SDDM theme fork

## Context

This repo is a fresh fork of the upstream `artemisii-moon-eclipse` SDDM theme by Jason Sackett (MIT-licensed, hosted at https://www.opendesktop.org/p/2355277). The repo is set up as a git worktree under `/home/jeremy/Projects/snow-crash-sddm/.bare/`, currently checked out on branch `swap-wallpaper` with `main` as the only other branch. The working tree is clean.

The upstream theme bundles a NASA lunar-eclipse image (`background.jpg`) and ships a minimal Qt 6 login UI. The desired outcome is a distributable fork that ships TehAnon's "Snow Crash" wallpaper (originally posted to r/wallpapers in 2013 as [OC], hosted at https://i.imgur.com/AkibqqB.png) instead, under a distinct theme identity.

Stakeholders:

- **Jason Sackett** — original theme code author. Code is MIT; fork redistribution is permitted provided the copyright notice is preserved.
- **TehAnon (Reddit)** — wallpaper author. Posted as [OC] on Reddit (2013-10-29), which on Reddit functions as a community signal granting redistribution with attribution. Reddit account is still active (link karma 17,360) and the original imgur URL is still live as of this writing.
- **The maintainer of this fork** — assumes responsibility for keeping the wallpaper attribution intact, the LICENSE file present, and the theme metadata coherent.

Constraints:

- SDDM themes are installed into a fixed directory (`/usr/share/sddm/themes/<name>/`), so any reference to an external path on the user's filesystem breaks portability. The wallpaper must be bundled.
- The Qt 6 `Image` element loads PNG natively, so no format conversion is required.
- The user explicitly opted for the bundled PNG (1.05 MB) over a re-encoded JPG to preserve image quality.

## Goals / Non-Goals

**Goals:**

- Ship a self-contained, installable SDDM theme under the `snow-crash` identity.
- Bundle the wallpaper at the source quality (no re-encoding).
- Properly attribute the wallpaper to TehAnon with a stable link.
- Comply with MIT by retaining the LICENSE file with attribution to Jason Sackett.
- Keep the upstream theme code unchanged so this fork remains a clean wallpaper/identity swap.

**Non-Goals:**

- Refactoring or improving the upstream `Main.qml` code (panel layout, login flow, config keys, error handling all carry over verbatim).
- Wiring this theme into `~/Projects/nix-config/main/profiles/nixos/linux-desktop.nix` (currently set to `sddm-astronaut-theme`). This is a separate future change.
- Submitting to the AUR or opendesktop.org store as part of this change. The theme will be in a distributable state, but listings are a separate effort.
- Re-encoding the wallpaper to a smaller format (the maintainer has explicitly chosen the bundled PNG at original quality).

## Decisions

### Bundle the wallpaper instead of referencing the source path

The wallpaper is copied from `~/Projects/nix-config/main/assets/wallpapers/snow-crash.png` into the theme root as `snow-crash.png`.

- **Rationale**: SDDM themes install to a fixed directory, so any absolute path on the developer's filesystem breaks portability. Bundling makes the theme installable on any machine.
- **Alternatives considered**:
  - External reference in `theme.conf`: rejected because `Main.qml` does not consume the `theme.conf` `background` key — it has a hardcoded `Image.source: "background.jpg"` line. Changing only `theme.conf` would be silently ignored.
  - Nix-store-path injection: rejected because it requires a Nix module in `nix-config`, which is deferred to a follow-up change. The theme should be distributable as plain files regardless of how the user installs it.

### Name the bundled asset `snow-crash.png`, not `background.png`

The original `background.jpg` generic name is preserved as a convention in some SDDM themes but loses the visual identifier when wallpapers are swapped. A descriptive name makes the file's role self-evident and makes the wallpaper swap obvious to anyone inspecting the theme directory.

- **Rationale**: The `snow-crash` filename matches both the wallpaper title (per TehAnon's Reddit post) and the theme identity, which keeps the swap self-documenting.
- **Alternative considered**: Keep the `background.jpg` filename with a `.png` extension change (`background.png`). Rejected because the name no longer describes the content, and the file would silently become a misnamed PNG.

### Bump version from 0.1.0 to 0.2.0

The theme code is unchanged, but the visual identity is. A minor version bump signals this to SDDM theme pickers / store listings that check the version field.

- **Rationale**: SemVer treats a wallpaper/identity change as a backwards-compatible enhancement.
- **Alternative considered**: Keep 0.1.0 since the API surface is unchanged. Rejected because the version field exists in `metadata.desktop` specifically to communicate visual identity changes to theme pickers.

### Single capability `snow-crash-theme`

The change is small enough that splitting it into multiple capability specs (e.g. separate specs for wallpaper attribution, theme identity, packaging) would create more file overhead than documentation value. One capability covers all the requirements coherently.

- **Rationale**: All requirements relate to the same artifact — the distributable theme identity — so they belong together.
- **Alternative considered**: Separate specs for `wallpaper-asset`, `theme-identity`, `theme-licensing`. Rejected as over-decomposition for a change of this size.

### Add a `LICENSE` file (MIT)

The upstream repo references "Code license: MIT" in the README but does not ship an actual `LICENSE` file. For distribution, MIT specifically requires the license text to accompany the code.

- **Rationale**: Without a LICENSE file, downstream packagers (Arch PKGBUILD reviewers, store moderators) cannot verify the license claim. Adding it removes ambiguity.
- **Alternative considered**: Leave the LICENSE reference in the README only. Rejected because the README statement alone is not a legally sufficient notice for MIT.

### `preview.png` is a copy of `snow-crash.png`

The theme picker preview should show what users will see. The cleanest way is to make `preview.png` and `snow-crash.png` byte-identical (or at least visually identical at the same dimensions).

- **Rationale**: Avoids any re-encoding, preserves quality, and removes the risk of the preview drifting from the wallpaper.
- **Alternative considered**: Generate a smaller preview (e.g., 800px wide) for picker thumbnails. Rejected because the maintainer has explicitly chosen to ship at full quality without separate thumbnails.

## Risks / Trade-offs

- **TehAnon Reddit account becomes inactive or deleted** → The Reddit URL still resolves via old.reddit.com (the post is preserved regardless of account status) and the imgur URL `https://i.imgur.com/AkibqqB.png` is the canonical reference for the image itself. Both attribution links will remain stable.
- **Imgur URL eventually rots** → The wallpaper is now bundled in the repo, so the theme does not depend on the imgur URL at runtime. The URL is included only as attribution reference.
- **The bundled PNG is larger than the original JPG (1.05 MB vs 480 KB)** → Acknowledged and explicitly accepted by the maintainer. SDDM themes ship small (the entire upstream theme was ~1.6 MB; this fork will be ~2.1 MB), so the size delta is well within norms.
- **`theme.conf`'s `background` key remains orphaned** → The upstream theme defines `background=background.jpg` in `theme.conf` but `Main.qml` does not read it. We update the value to `snow-crash.png` for consistency, but this is documentation hygiene, not a behavior change. If the upstream theme ever starts consuming this key, our `theme.conf` will already be in sync.
- **`preview.png` and `snow-crash.png` are byte-identical** → Slightly wasteful (the same image lives under two names) but trivially correct. If the wallpaper is ever updated, both files must be updated together. Acceptable for the current scope.
- **The fork relies on the upstream theme code staying stable** → If the upstream theme changes substantially, this fork may diverge. Out of scope for this change; future rebases are a separate effort.

## Migration Plan

This change lives on the existing `swap-wallpaper` worktree branch off `main`. Apply steps:

1. Apply the file changes per `tasks.md`.
2. Run `sddm-greeter-qt6 --test-mode --theme "$PWD"` (from the theme root) to verify the greeter renders with the new wallpaper. The original README documents this verification command; we preserve it.
3. Inspect the resulting greeter window — confirm `snow-crash.png` is the background and the panel layout is unchanged.

Rollback: revert the commit on `swap-wallpaper` (or delete the branch) — no migrations of installed state are involved because the change is not yet wired into `nix-config` or installed system-wide.

Out of scope for this migration: merging `swap-wallpaper` into `main`, publishing an AUR package, listing on opendesktop.org, or installing system-wide.

## Open Questions

- Should the `LICENSE` file use the calendar year the upstream theme was first published (2014, per the original PKGBUILD `pkgver=0.1.0` context) or the current year (2026)? Both are defensible; the standard practice is to use the year of publication and add years for substantial changes. Recommendation: use the year the fork was created (2026) with a "Copyright (c) 2014 Jason Sackett; modifications copyright (c) 2026 [maintainer]" header.
- Should the theme submit to AUR / opendesktop.org as part of this change or in a separate one? Recommendation: separate change, since store submission has its own metadata and review workflow distinct from the theme content.
- Should `theme.conf.user` be touched? It is currently an SDDM runtime override file with `showClock=true` and `type=image`, neither of which is consumed by `Main.qml` (this theme does not render a clock). Recommendation: leave untouched — it is the user's personal override, not part of the distributable theme.

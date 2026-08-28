# Proposal: Nix packaging for the Snow Crash SDDM theme

## Why

The Snow Crash SDDM theme currently ships as a directory of assets installable only via manual `cp -r` into `/usr/share/sddm/themes/snow-crash/` or the bundled Arch `PKGBUILD`. There is no declarative, reproducible way to install or configure the theme from a Nix expression. The maintainer runs NixOS on `anvil` and `hammer` via `nix-config`, where SDDM is currently pinned to `sddm-astronaut-theme`. Switching to this theme and managing its appearance (panel dimensions, colors, opacities, clock visibility, etc.) from `configuration.nix` requires a Nix package plus a typed options surface — neither exists today.

Two spike investigations backed this proposal (full details in `design.md`):

1. **`pkgs.formats.ini` produces valid INI for SDDM.** Theme files regenerated via `formats.ini` (a default config and a stress-test config with `false` booleans, larger integers, and unusual hex colors) were loaded by `sddm-greeter-qt6 --test-mode --theme ...`. `strace` confirmed `metadata.desktop`, `theme.conf`, `theme.conf.user`, and `Main.qml` were opened in sequence with no parse errors; the process proceeded to the Qt Quick rendering stage before the test-mode timeout.
2. **Float precision differences (`0.30` vs `0.300000`) are bit-identical at parse time.** `ThemeConfig.cpp` in SDDM 0.21.0 routes both files through `QSettings(IniFormat)` and the type-coercion methods (`toBool`, `toInt`, `toReal`, `toString`) — all of which use `strtod` / `QString::toDouble` under the hood. Empirically verified via Python: `0.30` and `0.300000` parse to `0x1.3333333333333p-2` (same IEEE 754 bits). No SDDM code path compares float values as strings; the QML only does `> 0` and `!== ""` checks. The cosmetic diff in the generated INI cannot affect runtime behavior.

The nixpkgs convention for SDDM themes was surveyed: `catppuccin-sddm`, `elegant-sddm`, `sddm-astronaut`, `sddm-chili-theme`, `sddm-sugar-dark`, and `where-is-my-sddm-theme` all ship as pure packages with a `themeConfig ? null` override argument; none expose `nixosModules.*`. This change matches that convention for the package and adds a typed NixOS module on top — a deliberate divergence, documented in `design.md`.

## What Changes

- **Add** `flake.nix` — exposes `packages.<system>.default` and `nixosModules.default` for `x86_64-linux` and `aarch64-linux`, pinned to `nixpkgs/nixos-unstable`
- **Add** `package.nix` — `stdenvNoCC.mkDerivation` accepting a `themeConfig ? null` argument; produces `$out/share/sddm/themes/snow-crash/` with all theme assets; writes `theme.conf` from `themeConfig` via `formats.ini` when provided, otherwise copies the bundled file
- **Add** `nixosModules/default.nix` — NixOS module exposing 21 typed options under `services.displayManager.sddm.snow-crash.*` and wiring SDDM automatically when enabled

No existing theme files are modified. The Arch `PKGBUILD`, the manual `cp -r` install path documented in `README.md`, the bundled `theme.conf`, and the bundled `theme.conf.user` all continue to work unchanged.

## Capabilities

### New Capabilities

None. Nix packaging is an additional distribution channel for the same `snow-crash-theme` capability, not a new capability.

### Modified Capabilities

- `snow-crash-theme`: adds requirements covering the Nix flake shape, the Nix package derivation, and the NixOS module's typed options + SDDM wiring. The existing identity/wallpaper/attribution/licensing/self-contained-distribution/preview/upstream-code requirements remain unchanged.

## Impact

- 3 files added (flake.nix, package.nix, nixosModules/default.nix)
- 0 theme files modified
- 0 dependencies added — the package builds from the existing repo contents using only `stdenvNoCC` and `formats` from nixpkgs
- 21 typed NixOS options added under `services.displayManager.sddm.snow-crash.*`
- Surface area: the package interface (`themeConfig ? null`) matches the nixpkgs convention exactly; the module's typed-options layer is a deliberate addition not seen in any nixpkgs SDDM theme
- Out of scope (separate concerns):
  - Updating `~/Projects/nix-config/main/` to consume the flake — separate change in a different repo
  - Removing `sddm-astronaut` from `nix-config`'s `environment.systemPackages` — depends on user preference
  - Publishing the flake to a git remote for `nix run github:user/...` consumption — local `nix build .#` works without it
  - Upstreaming the package to nixpkgs — possible future change once the local surface stabilizes
## 1. Flake scaffold

- [ ] 1.1 Create `flake.nix` at the repo root with `description`, `inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"`, and an `outputs` function that exposes `packages.<system>.default` (via `pkgs.callPackage ./package.nix { }`) and `nixosModules.default = ./nixosModules/default.nix` for `x86_64-linux` and `aarch64-linux`
- [ ] 1.2 Add a `nixosModules.snow-crash = self.nixosModules.default` alias so users can import by either name

## 2. Package derivation

- [ ] 2.1 Create `package.nix` at the repo root as a `stdenvNoCC.mkDerivation` with `pname = "snow-crash-sddm"`, `version = "0.2.0"`, `src = ./.;`, and `dontConfigure = true; dontBuild = true;`
- [ ] 2.2 Accept `themeConfig ? null` as a function argument; when non-null, write `$out/share/sddm/themes/snow-crash/theme.conf` from `(formats.ini { }).generate "theme.conf" { General = themeConfig; }` (mirror the `where-is-my-sddm-theme` package's pattern); when null, copy the bundled `theme.conf` from `src` as-is
- [ ] 2.3 In `installPhase`, `mkdir -p $out/share/sddm/themes/snow-crash`, `cp -r $src/* $out/share/sddm/themes/snow-crash/`, then `chmod -R u+w` to allow the `theme.conf` write step to overwrite the read-only source copy
- [ ] 2.4 Always copy the bundled `theme.conf.user` from `src` unchanged (non-Nix users keep their `showClock=true` + `type=image` override); the Nix module handles overrides via `themeConfig`
- [ ] 2.5 Add `meta` with `description`, `license = lib.licenses.mit;`, and `platforms = lib.platforms.linux;`

## 3. NixOS module — options

- [ ] 3.1 Create `nixosModules/default.nix` as a NixOS module function accepting `{ config, lib, pkgs, ... }`
- [ ] 3.2 Declare `options.services.displayManager.sddm.snow-crash.enable = lib.mkEnableOption "Snow Crash SDDM theme"`
- [ ] 3.3 Declare 6 integer options: `panelWidth` (default 420), `panelHeight` (340), `panelMargin` (120), `panelRadius` (18), `fieldHeight` (46), `buttonHeight` (46) — each `lib.types.int` with a description referencing the QML usage
- [ ] 3.4 Declare 3 float options: `panelOpacity` (0.30), `accentOpacity` (0.10), `borderOpacity` (0.18) — each `lib.types.numbers.between 0.0 1.0`
- [ ] 3.5 Declare 5 string color options: `textColor` (#f4f4f5), `mutedTextColor` (#b9bdc5), `accentColor` (#ffffff), `borderColor` (#ffffff), `errorColor` (#f38ba8) — each `lib.types.str` with a description noting the value is parsed by QML's `property color`
- [ ] 3.6 Declare 2 string text options: `title` ("Snow Crash"), `subtitle` ("Sign in") — each `lib.types.str`
- [ ] 3.7 Declare 3 boolean/toggle options: `showPowerButtons` (true), `showClock` (true, from `theme.conf.user`), plus the string `type` ("image", from `theme.conf.user`)
- [ ] 3.8 Declare 1 background option: `background` ("snow-crash.png") — `lib.types.str` with a description noting it can be a filename relative to the theme directory or an absolute path; validation is the QML's responsibility at render time

## 4. NixOS module — wiring

- [ ] 4.1 Build the `themeConfig` attrset from the module's options under a local `let` binding, of shape `{ General = { ... }; }`, including `showClock` and `type` (the values that previously lived only in `theme.conf.user`)
- [ ] 4.2 In `config = lib.mkIf cfg.enable`, set `services.displayManager.sddm.theme = lib.mkDefault "snow-crash"` (so explicit user overrides still win)
- [ ] 4.3 In the same `mkIf` block, set `services.displayManager.sddm.extraPackages = [ (pkgs.snow-crash-sddm.override { themeConfig = ...; }) ]` using the attrset from 4.1
- [ ] 4.4 Add a `lib.mkIf (!config.services.displayManager.sddm.enable)` warning via `lib.warn` when `cfg.enable = true` but SDDM is not enabled — surfaces the misconfiguration without failing evaluation

## 5. Verification

- [ ] 5.1 Run `nix flake check` from the repo root and confirm zero errors on `x86_64-linux` and `aarch64-linux`
- [ ] 5.2 Run `nix build .#default` and confirm the output contains `share/sddm/themes/snow-crash/{Main.qml,metadata.desktop,theme.conf,theme.conf.user,snow-crash.png,preview.png,LICENSE,README.md}`
- [ ] 5.3 Inspect the built `theme.conf` and confirm it is valid INI with all 21 keys under `[General]` (alphabetical ordering and float precision are expected and harmless per the spike evidence)
- [ ] 5.4 Run `sddm-greeter-qt6 --test-mode --theme "$(nix build .#default --print-out-paths)/share/sddm/themes/snow-crash"` and confirm via `strace -e openat` that `metadata.desktop`, `theme.conf`, `theme.conf.user`, and `Main.qml` open without errors
- [ ] 5.5 Build with `nix build .#default --override-input nixpkgs github:nixos/nixpkgs/nixos-unstable` to confirm the flake input is wired correctly
- [ ] 5.6 Run `openspec validate add-nix-flake` from the repo root and confirm the change validates (proposal, design, tasks, spec delta all consistent)
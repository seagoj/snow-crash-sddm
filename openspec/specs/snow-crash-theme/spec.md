# snow-crash-theme Specification

## Purpose

The `snow-crash-theme` is a minimal static SDDM theme that ships the "Snow Crash" wallpaper by TehAnon (originally posted to r/wallpapers in 2013 as [OC]) instead of the upstream `artemisii-moon-eclipse` lunar-eclipse image. It bundles a single Qt 6 login panel (carried over unchanged from the upstream theme by Jason Sackett, MIT) and three distribution paths:

1. **Manual install** — `sudo cp -r ./* /usr/share/sddm/themes/snow-crash/`
2. **Arch package** — `makepkg -si` against the bundled `PKGBUILD`
3. **Nix** — the standalone `flake.nix` at the repo root, exposing both a package and a NixOS module for declarative configuration

The Nix path is the focus of the `add-nix-flake` change; the other two paths remain functional and unchanged.
## Requirements
### Requirement: Bundled wallpaper

The theme MUST bundle a file named `snow-crash.png` at the theme root directory, and `Main.qml` MUST reference it via the Qt `Image` element as the background source.

#### Scenario: Greeter renders with bundled wallpaper

- **WHEN** the SDDM greeter starts and loads the theme
- **THEN** the background displays the bundled `snow-crash.png` from the theme directory

#### Scenario: Wallpaper file present in repo

- **WHEN** the theme directory is listed
- **THEN** a file named `snow-crash.png` exists at the theme root

#### Scenario: Main.qml references snow-crash.png

- **WHEN** `Main.qml` is inspected
- **THEN** the `Image` element's `source` property is the literal string `snow-crash.png`

### Requirement: Wallpaper attribution in README

The theme's `README.md` MUST include an attribution block crediting TehAnon as the wallpaper author with a link to the original r/wallpapers post and a fallback link to the imgur source.

#### Scenario: Attribution block present

- **WHEN** `README.md` is rendered
- **THEN** a section titled "Wallpaper attribution" appears containing:
  - the author name "TehAnon"
  - the URL `https://www.reddit.com/r/wallpapers/comments/1pfzqp/snow_crash_1920x1080_oc/`
  - the URL `https://i.imgur.com/AkibqqB.png`

### Requirement: Theme identity

The theme MUST identify as `snow-crash` consistently across its packaging metadata. `metadata.desktop` MUST declare `Theme-Id=snow-crash`, `PKGBUILD` MUST declare `pkgname=sddm-theme-snow-crash`, and install paths MUST use the `snow-crash` directory name.

#### Scenario: metadata.desktop Theme-Id

- **WHEN** `metadata.desktop` is inspected
- **THEN** the `Theme-Id` field is `snow-crash`

#### Scenario: PKGBUILD pkgname

- **WHEN** `PKGBUILD` is inspected
- **THEN** the `pkgname` field is `sddm-theme-snow-crash`

#### Scenario: PKGBUILD install directory

- **WHEN** `PKGBUILD` is inspected
- **THEN** the install and `cp` commands reference `/usr/share/sddm/themes/snow-crash/` as the install target

#### Scenario: No upstream identifiers remain

- **WHEN** the theme files are searched for `artemisii` or `artemisii-moon-eclipse`
- **THEN** zero matches appear in `metadata.desktop`, `PKGBUILD`, `Main.qml`, `theme.conf`, `README.md`, and `LICENSE`

### Requirement: MIT license file present

The theme MUST include a `LICENSE` file at the theme root containing the MIT license text and a copyright attribution line crediting Jason Sackett as the original theme code author.

#### Scenario: LICENSE file exists

- **WHEN** the theme directory is listed
- **THEN** a file named `LICENSE` exists at the theme root

#### Scenario: LICENSE contains MIT text

- **WHEN** `LICENSE` is read
- **THEN** the standard MIT license grant text is present (the line "Permission is hereby granted, free of charge" or equivalent canonical MIT language)

#### Scenario: LICENSE credits original author

- **WHEN** `LICENSE` is read
- **THEN** a copyright line containing "Jason Sackett" appears

### Requirement: Self-contained distribution

The theme MUST be installable on any Linux system with SDDM by copying the theme directory contents to a target path under `/usr/share/sddm/themes/snow-crash/`, with no external filesystem dependencies on the developer's machine.

#### Scenario: Manual install command in README

- **WHEN** `README.md` is consulted for installation
- **THEN** the install command copies files into `/usr/share/sddm/themes/snow-crash/`

#### Scenario: No absolute filesystem references

- **WHEN** the theme files are searched for absolute path literals (e.g. `/home/`, `~/`)
- **THEN** zero matches appear in `Main.qml`, `theme.conf`, `metadata.desktop`, or `PKGBUILD`

### Requirement: Preview image matches wallpaper

The theme MUST ship a `preview.png` that is visually identical to `snow-crash.png` so the SDDM theme picker shows what users will see at login.

#### Scenario: preview.png present

- **WHEN** the theme directory is listed
- **THEN** a file named `preview.png` exists at the theme root

#### Scenario: preview dimensions match wallpaper

- **WHEN** `preview.png` and `snow-crash.png` are inspected
- **THEN** both have dimensions of 1920×1200 (the wallpaper's native dimensions)

### Requirement: Upstream code carried over unchanged

The theme's `Main.qml` MUST be functionally equivalent to the upstream artemisii-moon-eclipse `Main.qml` aside from the single `Image.source` line. Panel layout, login flow, config keys, error handling, and keybindings MUST remain identical to upstream behavior.

#### Scenario: Only one Image.source change in Main.qml

- **WHEN** `Main.qml` is diffed against the upstream version
- **THEN** the only diff is the `source: "background.jpg"` line, now reading `source: "snow-crash.png"`

### Requirement: Nix flake exposes package and NixOS module

The theme MUST ship a `flake.nix` at the repo root that exposes both a Nix package and a NixOS module, so the theme can be consumed declaratively from any Nix flake input.

#### Scenario: Flake provides the theme package

- **WHEN** the repo's `flake.nix` is evaluated
- **THEN** it exposes `packages.<system>.default` for `x86_64-linux` and `aarch64-linux`, where each `default` is the theme derivation

#### Scenario: Flake provides a NixOS module

- **WHEN** the repo's `flake.nix` is evaluated
- **THEN** it exposes `nixosModules.default` (also aliased as `nixosModules.snow-crash`) that is a valid NixOS module importable via `imports = [ inputs.snow-crash-sddm.nixosModules.default; ]`

#### Scenario: Flake pins a nixpkgs input

- **WHEN** the repo's `flake.nix` is inspected
- **THEN** a `nixpkgs` input is declared pointing at `github:nixos/nixpkgs/nixos-unstable`

### Requirement: Nix package builds theme directory

The Nix package MUST produce an output containing a directory at `$out/share/sddm/themes/snow-crash/` with every asset required by SDDM to load the theme.

#### Scenario: Package output contains all theme assets

- **WHEN** `nix build .#default` succeeds
- **THEN** the output directory contains `share/sddm/themes/snow-crash/Main.qml`, `share/sddm/themes/snow-crash/metadata.desktop`, `share/sddm/themes/snow-crash/theme.conf`, `share/sddm/themes/snow-crash/theme.conf.user`, `share/sddm/themes/snow-crash/snow-crash.png`, `share/sddm/themes/snow-crash/preview.png`, `share/sddm/themes/snow-crash/LICENSE`, and `share/sddm/themes/snow-crash/README.md`

#### Scenario: Package is Linux-only

- **WHEN** the package's `meta.platforms` is inspected
- **THEN** it contains only `lib.platforms.linux`

#### Scenario: Package is MIT licensed

- **WHEN** the package's `meta.license` is inspected
- **THEN** it is `lib.licenses.mit`

### Requirement: Nix package accepts themeConfig override

The Nix package MUST accept an optional `themeConfig` argument. When provided, it MUST be used to generate `theme.conf` so that all appearance knobs can be controlled without rebuilding the theme code.

#### Scenario: themeConfig null uses bundled theme.conf

- **WHEN** the package is built with `themeConfig = null`
- **THEN** the output's `theme.conf` is byte-identical to the bundled `theme.conf` from the repo source

#### Scenario: themeConfig attrset generates theme.conf

- **WHEN** the package is built with `themeConfig = { panelWidth = 600; accentColor = "#ff00ff"; showPowerButtons = false; ... }`
- **THEN** the output's `theme.conf` contains `[General]` followed by keys derived from the attrset, with values serialized by `pkgs.formats.ini` (booleans as `true`/`false`, integers as decimal, floats as decimals, strings unquoted)

#### Scenario: themeConfig.user is not affected by themeConfig

- **WHEN** the package is built with `themeConfig = { ... }` (non-null)
- **THEN** the output's `theme.conf.user` is byte-identical to the bundled `theme.conf.user` from the repo source (Nix overrides go through `theme.conf`, the `.user` file remains a non-Nix user-override surface)

#### Scenario: Greeter accepts generated theme.conf

- **WHEN** `sddm-greeter-qt6 --test-mode --theme <pkg-store-path>/share/sddm/themes/snow-crash` is invoked against a package built with `themeConfig` provided
- **THEN** the greeter opens `theme.conf` and `theme.conf.user` without parse errors and proceeds to load `Main.qml`

### Requirement: NixOS module exposes typed theme options

The NixOS module MUST expose every key from `theme.conf` and `theme.conf.user` as a typed option under `services.displayManager.sddm.snow-crash.*`, so configuration is type-checked and documented.

#### Scenario: Enable option exists

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.enable` is a `mkEnableOption` boolean

#### Scenario: Panel-dimension integer options exist

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.panelWidth`, `panelHeight`, `panelMargin`, `panelRadius`, `fieldHeight`, and `buttonHeight` exist as `types.int` options with the bundled defaults (420, 340, 120, 18, 46, 46 respectively)

#### Scenario: Opacity float options exist with bounds

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.panelOpacity`, `accentOpacity`, and `borderOpacity` exist as `types.numbers.between 0.0 1.0` options with the bundled defaults (0.30, 0.10, 0.18 respectively)

#### Scenario: Color string options exist

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.textColor`, `mutedTextColor`, `accentColor`, `borderColor`, and `errorColor` exist as `types.str` options with the bundled hex defaults (#f4f4f5, #b9bdc5, #ffffff, #ffffff, #f38ba8)

#### Scenario: Text string options exist

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.title` ("Snow Crash") and `subtitle` ("Sign in") exist as `types.str` options

#### Scenario: Toggle boolean options exist

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.showPowerButtons` and `showClock` exist as `types.bool` options (both default `true`)

#### Scenario: SDDM-system options exist

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.type` exists as a `types.str` option with default `"image"` (this key originated in the bundled `theme.conf.user`)

#### Scenario: Background option exists

- **WHEN** the module is imported
- **THEN** `services.displayManager.sddm.snow-crash.background` exists as a `types.str` option with default `"snow-crash.png"` and a description noting the value may be a filename relative to the theme directory or an absolute path

### Requirement: NixOS module wires SDDM when enabled

The NixOS module MUST configure SDDM and the system environment so
the Nix-built theme is available at
`/run/current-system/sw/share/sddm/themes/snow-crash/` when
`services.displayManager.sddm.snow-crash.enable = true`, without
requiring the user to set anything in `services.displayManager.sddm`
or `environment.systemPackages` manually.

#### Scenario: Enable sets theme with mkDefault priority

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true` and the user has not explicitly set `services.displayManager.sddm.theme`
- **THEN** `services.displayManager.sddm.theme` is `"snow-crash"` (the bare name resolves via the nixpkgs SDDM module's `ThemeDir` lookup against the package's `share/sddm/themes/snow-crash/` directory in the system closure)

#### Scenario: Enable sets theme with mkForce priority

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true` and the user has explicitly set `services.displayManager.sddm.theme` to a different value
- **THEN** the user's explicit value wins (the module uses `lib.mkDefault` so explicit overrides take precedence)

#### Scenario: Enable adds theme package to extraPackages

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true`
- **THEN** `services.displayManager.sddm.extraPackages` contains the
  Nix package built with `themeConfig = { General = ...all module
  options...; }`, putting the package into the SDDM wrapper's runtime
  closure (the wrapper consumes `extraPackages` as `buildInputs` for
  QML plugin / Qt runtime propagation; this is NOT the mechanism by
  which the theme directory reaches `/run/current-system/sw/share/sddm/themes/`)

#### Scenario: Enable adds theme package to environment.systemPackages

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true`
- **THEN** `environment.systemPackages` contains the Nix package
  built with `themeConfig = { General = ...all module options...; }`,
  so that its `share/sddm/themes/snow-crash/` is symlinked into
  `/run/current-system/sw/share/sddm/themes/snow-crash/` via the
  NixOS SDDM module's `pathsToLink = [ "/share/sddm" ]`. This is the
  mechanism by which SDDM's `ThemeDir` resolution (bare-name lookup
  under `/run/current-system/sw/share/sddm/themes`) actually finds
  the theme; the `extraPackages` entry alone is not sufficient because
  the nixpkgs SDDM wrapper produces a `$out` that is a pure
  symlink-farm of `sddm-unwrapped` and does NOT include any
  `share/sddm/themes/<theme>/` from the extras.

#### Scenario: Both entries share the same customized derivation

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true` and
  the user has overridden one or more module options (e.g.
  `services.displayManager.sddm.snow-crash.panelWidth = 600`)
- **THEN** `services.displayManager.sddm.extraPackages` and
  `environment.systemPackages` both contain the SAME derivation — the
  single `pkgs.snow-crash-sddm.override { themeConfig = themeConfigAttrset; }`
  built with the user's customized option values — so the customized
  `theme.conf` is reachable from both the SDDM wrapper's runtime
  closure and the system path. The user MUST NOT end up with a
  customized `theme.conf` in one location and the bundled `theme.conf`
  in the other.

#### Scenario: Enable is off by default

- **WHEN** the module is imported but `services.displayManager.sddm.snow-crash.enable` is not set
- **THEN** it defaults to `false` and the module's `config` block is inert (no SDDM changes, no `environment.systemPackages` additions)

#### Scenario: Warn when SDDM is not enabled

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true` and `services.displayManager.sddm.enable != true`
- **THEN** evaluation emits a `lib.warn` message indicating the snow-crash theme is enabled but SDDM is not

### Requirement: Non-Nix install path remains functional

The addition of Nix packaging MUST NOT modify the bundled `theme.conf`, `theme.conf.user`, `metadata.desktop`, `Main.qml`, or `PKGBUILD`. Non-Nix consumers who install via `cp -r` or `makepkg -si` continue to receive a working theme.

#### Scenario: Bundled theme.conf is unchanged

- **WHEN** the repo is cloned fresh and `theme.conf` is read
- **THEN** its contents match what was committed before this change was applied (no formatting, key order, or value changes)

#### Scenario: PKGBUILD still builds

- **WHEN** `makepkg -si` is run against the unchanged `PKGBUILD`
- **THEN** the package builds and installs to `/usr/share/sddm/themes/snow-crash/` with the same files as before this change

#### Scenario: Manual cp -r install still works

- **WHEN** the manual install command from `README.md` is run (`sudo cp -r ./* /usr/share/sddm/themes/snow-crash/`)
- **THEN** the theme renders identically to the pre-change behavior


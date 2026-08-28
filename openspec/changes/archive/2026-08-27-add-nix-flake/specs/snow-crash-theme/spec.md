## ADDED Requirements

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

When `services.displayManager.sddm.snow-crash.enable = true`, the module MUST configure the SDDM service to use the Nix-built theme without requiring the user to set `theme` or `extraPackages` manually.

#### Scenario: Enable sets theme with mkDefault priority

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true` and the user has not explicitly set `services.displayManager.sddm.theme`
- **THEN** `services.displayManager.sddm.theme` is `"snow-crash"` (the bare name resolves via the nixpkks SDDM module's `ThemeDir` lookup against the package's `extraPackages` closure)

#### Scenario: Enable sets theme with mkForce priority

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true` and the user has explicitly set `services.displayManager.sddm.theme` to a different value
- **THEN** the user's explicit value wins (the module uses `lib.mkDefault` so explicit overrides take precedence)

#### Scenario: Enable adds theme package to extraPackages

- **WHEN** `services.displayManager.sddm.snow-crash.enable = true`
- **THEN** `services.displayManager.sddm.extraPackages` contains the Nix package built with `themeConfig = { General = ...all module options...; }`, so the built theme's `share/sddm/themes/snow-crash/` is in the SDDM runtime closure

#### Scenario: Enable is off by default

- **WHEN** the module is imported but `services.displayManager.sddm.snow-crash.enable` is not set
- **THEN** it defaults to `false` and the module's `config` block is inert (no SDDM changes)

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
## MODIFIED Requirements

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

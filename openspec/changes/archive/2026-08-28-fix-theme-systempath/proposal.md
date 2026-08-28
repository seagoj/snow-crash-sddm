# Proposal: wire the theme package into environment.systemPackages too

## Why

The NixOS module added by `2026-08-27-add-nix-flake` only puts the
`snow-crash-sddm` derivation into
`services.displayManager.sddm.extraPackages` when enabled. Live deploy
of the consuming change in `~/Projects/nix-config/main/`
(`openspec/changes/consume-snow-crash-sddm-flake`) on `anvil` showed
that this is not sufficient: `sddm.conf.d/00-nixos.conf` correctly
emits `Current=snow-crash` but `/run/current-system/sw/share/sddm/themes/`
only contains the three bundled sddm-unwrapped themes (`elarun`,
`maldives`, `maya`), and the greeter silently falls back. Root cause:
the nixpkgs SDDM wrapper (`pkgs/applications/display-managers/sddm/default.nix`)
consumes `extraPackages` purely as `buildInputs` and the wrapper `$out`
is a symlink-farm of `sddm-unwrapped` only — no
`share/sddm/themes/<theme>/` from the extras ever lands in it. NixOS
surfaces `/run/current-system/sw/share/sddm/themes/` from
`environment.systemPackages` via the SDDM module's
`pathsToLink = [ "/share/sddm" ]`. The theme package therefore has to
be in `systemPackages` for SDDM to find it.

The original `design.md` claimed `extraPackages` would propagate the
theme directory into the system closure — that claim is wrong against
the current nixpkgs SDDM wrapper, and the add-nix-flake spec baked
the same incorrect reasoning into the "Enable adds theme package to
extraPackages" scenario.

## What Changes

- **Modify** `nixosModules/default.nix` to also set
  `environment.systemPackages = [ themePkg ];` in the same
  `config = lib.mkIf cfg.enable { ... }` block that sets
  `services.displayManager.sddm.extraPackages`. Both entries MUST
  point at the same derivation (the same `pkgs.snow-crash-sddm.override`
  with the module's `themeConfigAttrset`) so a customized
  `theme.conf` reaches SDDM whichever path it discovers the theme by.
- **Update** the `NixOS module wires SDDM when enabled` requirement in
  `openspec/specs/snow-crash-theme/spec.md`:
  - Replace the misleading clause in the `Enable adds theme package to
    extraPackages` scenario ("so the built theme's `share/sddm/themes/snow-crash/`
    is in the SDDM runtime closure") with an accurate description of
    what `extraPackages` actually does (the SDDM wrapper's runtime
    closure for QML plugin propagation).
  - **Add** a new `Enable adds theme package to environment.systemPackages`
    scenario covering the actual mechanism by which the theme
    directory reaches `/run/current-system/sw/share/sddm/themes/`.
  - **Add** a new `Both entries share the same customized derivation`
    scenario asserting that overriding any module option produces
    one derivation consumed by both `extraPackages` and
    `systemPackages` (so the user cannot end up with a customized
    `theme.conf` in one location and the bundled `theme.conf` in the
    other).
- **Update** the add-nix-flake `design.md` "Module wiring: theme name +
  extraPackages" decision block to correct the `extraPackages`-only
  claim. The decision heading should be renamed to mention
  `systemPackages`.

No new files. No package/flake/theme-file changes. No new options.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `snow-crash-theme`: the `NixOS module wires SDDM when enabled`
  requirement is amended (new scenario, revised scenario text) so
  consumers do not have to add `pkgs.snow-crash-sddm` to
  `environment.systemPackages` themselves. The 21 typed options, the
  package derivation, and the flake shape are unchanged.

## Impact

- `nixosModules/default.nix` — one new line of `environment.systemPackages = [ themePkg ];`
  inside the existing `mkIf cfg.enable` block; one local `let` binding
  introduced to share the derivation between `extraPackages` and
  `systemPackages` (avoids re-evaluating `pkgs.snow-crash-sddm.override`
  twice with the same `themeConfigAttrset`)
- `openspec/specs/snow-crash-theme/spec.md` — three scenario changes
  (one revised text, two new scenarios under the existing
  `NixOS module wires SDDM when enabled` requirement)
- `openspec/changes/archive/2026-08-27-add-nix-flake/design.md` —
  correct the false `extraPackages` claim in the rationale/decision
  block
- `~/Projects/nix-config/main/` — the workaround added in the
  consumer change (`pkgs.snow-crash-sddm` in
  `environment.systemPackages`) becomes redundant once this fix
  lands and the consumer is rebuilt against the new module. The
  consumer change's OpenSpec follow-up should drop the extra entry.
  Out of scope for this change; the consumer side handles the
  cleanup.
- No dependency changes
- No new options / no removed options
- No package / flake / theme-file changes

# Design: Nix packaging for the Snow Crash SDDM theme

## Context

The Snow Crash SDDM theme ships as a plain directory of files (Main.qml, theme.conf, snow-crash.png, etc.) with an Arch `PKGBUILD` for distribution on Arch/CachyOS. The current installation model is a manual `cp -r` into `/usr/share/sddm/themes/snow-crash/` or `makepkg -si`. There is no declarative, reproducible way to install or configure the theme from a Nix expression.

The theme is consumed today by the personal NixOS configurations (`~/Projects/nix-config/main/`, hosts `anvil` and `hammer`) via `services.displayManager.sddm.theme = "sddm-astronaut-theme"` — i.e. a different theme. The maintainer wants to swap to this theme and manage its appearance declaratively through Nix.

Two spike investigations were run during exploration and verified the load-bearing assumptions:

1. **`pkgs.formats.ini` produces valid INI for SDDM.** Both the bundled `theme.conf` (defaults) and the `theme.conf.user` (clock + background-type overrides) were regenerated via `formats.ini`, dropped into a copy of the theme, and `sddm-greeter-qt6 --test-mode --theme ...` opened `metadata.desktop`, `theme.conf`, `theme.conf.user`, and `Main.qml` in sequence with no parse warnings. The QML proceeded to the Qt Quick / NVIDIA rendering stage before the test-mode timeout killed it.
2. **Float precision (`0.30` vs `0.300000`) is bit-identical at the IEEE 754 level.** `ThemeConfig.cpp` in SDDM 0.21.0 routes both files through `QSettings(IniFormat)` and the type-coercion methods (`toBool`, `toInt`, `toReal`, `toString`) — all of which use `strtod`/`QString::toDouble`/`QString::toInt` under the hood, identical to Python's `float()`. The QML only compares numeric values with `> 0` and string values with `!== ""`. No code path compares float values as strings. The cosmetic diff in the generated INI (Nix writes `0.300000`, the bundled file has `0.30`) is therefore purely cosmetic and cannot affect runtime behavior.

Surveyed the nixpkgs convention for SDDM themes (`catppuccin-sddm`, `elegant-sddm`, `sddm-astronaut`, `sddm-chili-theme`, `sddm-sugar-dark`, `where-is-my-sddm-theme`). **None of them expose `nixosModules.*`** — they are all pure packages that accept a `themeConfig` arg and write it to `theme.conf.user` via `ln -sf`. The nixpkgs module option `services.displayManager.sddm.theme` is `types.str` and accepts either a bare theme name (e.g. `"sddm-astronaut-theme"`) or a full store path (e.g. `"${pkgs.where-is-my-sddm-theme}/share/sddm/themes/where_is_my_sddm_theme_qt5"`).

Stakeholders:

- **The maintainer of this fork** — wants declarative installation + configuration from NixOS hosts in `nix-config`.
- **Jason Sackett** — original theme code author (MIT). The Nix package ships the same code, no upstream-visible change.
- **TehAnon** — wallpaper author. Attribution already in `README.md`; the Nix package ships the same bundled PNG.

Constraints:

- The theme must remain installable as plain files (Arch `PKGBUILD` path must keep working). The Nix flake is additive, not a replacement for the existing distribution story.
- `metadata.desktop` declares `Theme-Id=snow-crash`, `QtVersion=6`, `MainScript=Main.qml`, `ConfigFile=theme.conf`. The Nix package must preserve these so `services.displayManager.sddm.theme = "snow-crash"` works by bare name (the `ThemeDir` resolution in nixpkgs's `services.displayManager.sddm` module looks up by name under `/run/current-system/sw/share/sddm/themes`).
- The NixOS module must not collide with the existing `services.displayManager.sddm.theme` option — the module sets `theme = lib.mkDefault "snow-crash"` so explicit user overrides still win.

## Goals / Non-Goals

**Goals:**

- Add a standalone flake to this repo exposing:
  - `packages.<system>.default` — the theme as a Nix derivation
  - `nixosModules.default` — a NixOS module with typed options for every `theme.conf` and `theme.conf.user` key (21 options total)
- Match the nixpkgs package convention (`themeConfig ? null` override arg, `formats.ini` serialization to `theme.conf`) so future upstreaming stays straightforward.
- Exceed the nixpkgs convention by adding a typed NixOS module that wires the package into `services.displayManager.sddm` automatically when enabled.
- Document the spike findings and the rationale for non-conventional choices in this `design.md` so future maintainers understand the divergence.
- Keep the existing Arch `PKGBUILD`, manual `cp -r` install, and bundled `theme.conf`/`theme.conf.user` files untouched — the Nix path is additive.

**Non-Goals:**

- Upstreaming the package to nixpkgs. The package is fine to upstream later, but the maintainer is the only consumer today and the OpenSpec change targets local consumption.
- Submitting a sddm-astronaut-style override for the `sddm-greeter-qt6` package's `propagatedBuildInputs`. The theme doesn't depend on any extra Qt modules beyond what SDDM already ships with — the QML uses only `QtQuick 2.15` (per the existing `Main.qml` import line).
- Re-implementing or improving the upstream `Main.qml`. Theme code is unchanged.
- Re-encoding the wallpaper to a smaller format. The bundled PNG at 1920×1200 / 1.05 MB is intentional (per the prior change's rationale).
- Replacing the bundled `theme.conf.user`. It stays in the repo for non-Nix users (`cp -r` installs). The Nix package just doesn't write it.

## Decisions

### Standalone flake in this repo (not in `nix-config`)

The flake lives at `snow-crash-sddm/flake.nix` and exposes both `packages.<system>.default` and `nixosModules.default`. `nix-config` consumes both via a flake input.

- **Rationale**: Keeps the theme self-contained and potentially publishable. Mirrors the nixpkgs package-module split, which is the dominant pattern for NixOS ecosystem projects (agenix, sops-nix, etc.). Avoids cluttering `nix-config`'s `packages/` directory with theme internals.
- **Alternatives considered**:
  - **In `nix-config` only**: Rejected because it confuses `nix-config` ownership boundaries (the theme isn't part of the system config repo; it's a separate artifact).
  - **Hybrid (flake for package, module in `nix-config`)**: Rejected because the module's logic is specific to this theme, so it belongs with the theme. Path C from the exploration discussion.

### Package interface: `themeConfig ? null` (nixpkgs convention)

The package accepts a single argument:

```nix
{ lib, stdenvNoCC, formats }:

stdenvNoCC.mkDerivation {
  pname = "snow-crash-sddm";
  version = "0.2.0";
  src = ./.;
  themeConfig ? null,   # Attrset; matches nixpkgs pattern
  ...
}
```

When `themeConfig == null`, the bundled `theme.conf` and `theme.conf.user` are copied as-is. When `themeConfig != null`, the package writes `theme.conf` from `themeConfig` via `formats.ini`, and leaves `theme.conf.user` as the bundled file (non-Nix user override surface preserved).

- **Rationale**: Matches `elegant-sddm`, `where-is-my-sddm-theme`, `sddm-chili-theme`, `sddm-sugar-dark`. Future upstreaming reduces to "rename package, fix src fetch, open PR".
- **Alternatives considered**:
  - **Always-regenerate with a default attrset**: Rejected because it removes the bundled-file fallback. Users who `nix-build` without overriding get the exact same theme as `cp -r` users.
  - **Two separate args (`themeConfig` for `theme.conf`, `themeUserConfig` for `theme.conf.user`)**: Rejected because no nixpkgs SDDM theme does this. The bundled `theme.conf.user` only has 2 keys (`showClock=true`, `type=image`) which are already in the module's default attrset, so they're effectively always written into `theme.conf` under the module path anyway.

### Single themeConfig attrset → both files (Decision 1, Option A from exploration)

Under the NixOS module, both `theme.conf` and `theme.conf.user` are generated from the same attrset. The bundled `theme.conf.user` (which contains `showClock=true` + `type=image`) is included in the module's default attrset so both files contain identical content. SDDM reads `theme.conf` first, then `theme.conf.user` overrides per-key — but with identical content, the second read is a no-op.

- **Rationale**: Single source of truth in the module. Spike confirmed `theme.conf.user` only overrides when the value is non-empty (`!userSettings.value(key).toString().isEmpty()`), so identical files are safe.
- **Alternatives considered**:
  - **Generate `theme.conf` from options, leave `theme.conf.user` alone (Option B)**: Rejected because it makes `showClock` and `type` unconfigurable from Nix — those keys live in the file the user can't override.
  - **Write to `theme.conf.user` only, leave `theme.conf` alone (Option C variant)**: Rejected because it inverts the convention. `theme.conf` is the theme's defaults; the user file is the override. Putting the module's output in the override file means a non-Nix `cp -r` install wouldn't get the Nix-configured values.

### Skip writing `theme.conf.user` in the Nix package output

The package writes `theme.conf` only when `themeConfig != null`. The bundled `theme.conf.user` is shipped as-is from `src`.

- **Rationale**: All 21 keys (including `showClock` and `type` from the original `theme.conf.user`) live in the module's `themeConfig` attrset. They end up in `theme.conf`. The `theme.conf.user` would be redundant. Leaving the bundled file in `src` ensures non-Nix users (`cp -r`) still get the clock enabled — they only lose the override surface if they install via Nix, but the override surface is the NixOS module in that case.
- **Trade-off accepted**: A user who installs via Nix AND wants to manually edit `theme.conf.user` outside of Nix has to know about the convention. The NixOS module's `programs.snow-crash-sddm.enable = true` is the override mechanism; manual `theme.conf.user` edits are no longer the supported path.

### Namespace: `services.displayManager.sddm.snow-crash`

The NixOS module exposes options under the existing SDDM tree rather than a new top-level `programs.snow-crash-sddm` namespace.

```nix
options.services.displayManager.sddm.snow-crash = {
  enable  = lib.mkEnableOption "Snow Crash SDDM theme";
  panelWidth   = lib.mkOption { ... };
  panelOpacity = lib.mkOption { ... };
  # ... 19 more keys
};
```

- **Rationale**: Hangs off the existing SDDM option tree, so anyone configuring SDDM already discovers it via tab completion. Clear ownership (`snow-crash.*` cannot collide with future upstream nixpkgs SDDM options). `mkDefault` on `services.displayManager.sddm.theme` lets the user override the theme name explicitly without fighting the module.
- **Alternatives considered**:
  - **`programs.snow-crash-sddm.*`**: Rejected because the convention `programs.<name>` implies user-env installation (e.g. `home.packages`), but this configures SDDM system-wide. The semantic mismatch is confusing.
  - **`services.snow-crash-sddm.*`**: Rejected because it's not a service. There's no `services.snow-crash-sddm.enable` daemon to manage; the option just wires the SDDM service differently.
  - **`services.displayManager.sddm.themeSettings.*`**: Rejected because the name is too generic and could collide with a future nixpkgs option. `services.displayManager.sddm.snow-crash.*` is namespaced by the theme.

### 21 options, types from the QML usage

Each `theme.conf` and `theme.conf.user` key gets a typed `mkOption`. Types mirror the QML's consumption:

| Option | Type | Notes |
|--------|------|-------|
| `background` | `types.str` | Filename relative to theme dir, or absolute path. Validated via description, not type (the file may live in another package's store path). |
| `panelWidth`, `panelHeight`, `panelMargin`, `panelRadius`, `fieldHeight`, `buttonHeight` | `types.int` | No bound checks (SDDM itself doesn't reject weird values; the QML handles them at render time). |
| `panelOpacity`, `accentOpacity`, `borderOpacity` | `types.numbers.between 0.0 1.0` | Bounded — opacities outside this range are nonsensical. |
| `textColor`, `mutedTextColor`, `accentColor`, `borderColor`, `errorColor` | `types.str` | Hex strings. No regex check — same value is consumed by QML's `property color`, which parses any QML-accepted color spec. |
| `title`, `subtitle` | `types.str` | Display text. |
| `showPowerButtons`, `showClock` | `types.bool` | Toggle. |
| `type` | `types.str` | SDDM-system background type. SDDM accepts `image` / `color` / `animation`; validated by description, not type. |

- **Rationale**: Type as narrowly as possible without making the module fragile to upstream SDDM changes. Floats get range checks (opacities are bounded by definition). Colors stay as `str` (regex validation is brittle; the QML is the validator at runtime).
- **Alternatives considered**:
  - **All keys as `types.str`**: Rejected because we lose the type info that catches typos (`paneWidth=42` would silently fail). The point of the module is to provide types where they exist.
  - **Strict types everywhere (e.g. `types.enum` for `type`)**: Rejected because SDDM may add new values; `types.str` future-proofs without rejecting valid inputs.

### Module wiring: theme name + extraPackages

```nix
config = lib.mkIf cfg.enable {
  services.displayManager.sddm = {
    theme = lib.mkDefault "snow-crash";   # user can override
    extraPackages = [
      (pkgs.snow-crash-sddm.override { themeConfig = cfgToConfig cfg; })
    ];
  };
};
```

The `extraPackages` mechanism is how the nixpkgs SDDM module injects packages into the greeter's runtime closure — see `nixos/modules/services/display-managers/sddm.nix` line 16:

```nix
extraPackages = old.extraPackages or [] ++ ... ++ cfg.extraPackages;
```

This pulls the theme's `share/sddm/themes/snow-crash/` into `/run/current-system/sw/share/sddm/themes/snow-crash/`, where SDDM's `ThemeDir` resolution finds it by `Theme-Id`.

- **Rationale**: Matches nixpkgs convention exactly. No custom SDDM module logic. The theme attribute name (`snow-crash`) matches `metadata.desktop`'s `Theme-Id`.
- **Alternatives considered**:
  - **Override `services.displayManager.sddm.package`**: Rejected because that's a much heavier hammer (replaces the entire SDDM package). `extraPackages` is the documented extension point.
  - **Set `theme = "${pkg}/share/sddm/themes/snow-crash"` (full path)**: Rejected because the bare-name form works once `extraPackages` is wired correctly. Bare name is more idiomatic and matches what `sddm-astronaut` does.

### Flake shape

```nix
{
  description = "Snow Crash SDDM theme — Nix package and NixOS module";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in { default = pkgs.callPackage ./package.nix { }; });

      nixosModules.default = ./nixosModules/default.nix;
      nixosModules.snow-crash = self.nixosModules.default;
    };
}
```

- **Rationale**: Two-name `nixosModules.default` + `nixosModules.snow-crash` matches the agenix / sops-nix convention and lets users pick the import style they prefer.
- **Alternatives considered**:
  - **flake-parts**: Rejected for a single-package flake — pure `flake.nix` is simpler.
  - **Per-system package attrs only (no `default`)**: Rejected — `default` is the convention and `nix run` / `nix build` without a name needs it.

## Spike Evidence

The following artifacts were produced during exploration and live under `/tmp/snow-crash-spike/` (not in this repo):

- `gen.nix` — Nix expression generating `theme.conf` + `theme.conf.user` via `formats.ini` for both default and stress-test configs.
- `theme-default/` and `theme-weird/` — copies of the theme with the bundled `theme.conf` / `theme.conf.user` replaced by the generated ones.
- `sddm-strace.log` — `strace` of `sddm-greeter-qt6 --test-mode --theme ...` showing the theme files opened in sequence with no errors.
- Verification via `ThemeConfig.cpp` (SDDM 0.21.0 source at `/nix/store/wbvyill5wxvd6m3jzc7wv10anipdpd4p-v0.21.0.tar.gz/src/common/ThemeConfig.cpp`) — the actual parser logic.

The spike artifacts are intentionally kept outside the repo (in `/tmp/`) because they include intermediate builds and the SDDM source for inspection only.

## Risks / Trade-offs

- **The module exceeds the nixpkgs convention.** No nixpkgs SDDM theme exposes `nixosModules.*`. Future maintainers may be surprised that this theme does. Mitigation: this `design.md` documents the reasoning and the convention comparison. The package itself follows the convention; only the module diverges.
- **The Nix-generated `theme.conf` will differ cosmetically from the bundled file.** `formats.ini` alphabetizes keys and writes floats with full Nix precision (`0.300000` vs `0.30`). Spike confirmed these are bit-identical at parse time and no SDDM code path compares them as strings. The diff is invisible at runtime but visible in `/nix/store/`.
- **`theme.conf.user` becomes effectively redundant under Nix.** It's still shipped from `src` (so `cp -r` users get the clock), but the module doesn't write it. A user who manually edits `theme.conf.user` after a Nix install will see their edits silently overridden by `theme.conf` for any key the module also writes. Mitigation: document that `programs.snow-crash-sddm.*` is the override mechanism; `theme.conf.user` is a non-Nix concept.
- **`panelOpacity = 0` would silently fall back to the QML's built-in default.** The QML guard `config.realValue("panelOpacity") > 0 ? ... : 0.30` treats `0` as missing. Setting `panelOpacity = 0` from Nix would produce the same behavior as omitting it. The module cannot prevent this without breaking the existing semantics. Mitigation: document the guard in the option description.
- **The flake depends on `nixos-unstable`.** If `nix-config`'s flake.lock pins a different nixpkgs revision, the flake input here must use `inputs.nixpkgs.follows` to align them. Mitigation: add `inputs.nixpkgs.follows = "nixpkgs";` to the flake's nixpkgs input once nix-config consumes it.
- **The package's `src = ./.` works for `nix build .#default` but not for `nix run github:user/snow-crash-sddm`.** Future publishing (if desired) would need a `fetchFromGitHub` source or a flake-parts-style source-detection. Out of scope for this change.

## Migration Plan

This change adds three files (`flake.nix`, `package.nix`, `nixosModules/default.nix`) and modifies none of the existing theme files. Apply steps:

1. Add `flake.nix`, `package.nix`, `nixosModules/default.nix` per `tasks.md`.
2. Run `nix flake check` from the repo root to verify the flake evaluates cleanly on `x86_64-linux` and `aarch64-linux`.
3. Run `nix build .#default` to verify the package builds and the output directory contains `share/sddm/themes/snow-crash/` with all expected files.
4. Run `sddm-greeter-qt6 --test-mode --theme "$(nix build .#default --print-out-paths)/share/sddm/themes/snow-crash"` to verify the Nix-built theme renders identically to the manually-installed one.
5. From the `nix-config` repo (separate change), add `snow-crash-sddm` as a flake input, import `inputs.snow-crash-sddm.nixosModules.default`, and set `services.displayManager.sddm.snow-crash.enable = true` in `profiles/nixos/linux-desktop.nix`. This swaps the active theme from `sddm-astronaut-theme`.

Rollback: delete the three new files. No existing theme files are modified; the Arch `PKGBUILD` path continues to work.

Out of scope for this migration:
- Updating `nix-config` to consume the new flake (separate change, lives in the other repo).
- Removing `sddm-astronaut` from `nix-config`'s `environment.systemPackages` and `services.displayManager.sddm.extraPackages` (depends on user preference; can stay installed harmlessly).
- Publishing the flake to a git remote (only needed for `nix run github:user/...` consumption; not needed for local `nix build .#` use).

## Open Questions

- **Should the module namespace be `services.displayManager.sddm.snow-crash.*` (current recommendation) or `programs.snow-crash-sddm.*`?** The former hangs off the existing SDDM tree; the latter is more "standalone". Recommendation: `services.displayManager.sddm.snow-crash.*` for discoverability, but flag for user decision before implementation.
- **Should the package's `themeConfig` arg accept a partial attrset (e.g. only `{ background = "..."; }`) or require all 21 keys?** Recommendation: partial — the module always passes the full attrset, but ad-hoc users of `pkgs.snow-crash-sddm.override` may pass partial attrsets that merge with bundled defaults. **This is a behavior decision**: with the current design, passing partial attrsets *replaces* `theme.conf` rather than *merging into* it (the same way `formats.ini` works). If merge semantics are wanted, the package would need to read the bundled `theme.conf` and deep-merge first — extra complexity for unclear benefit. Recommendation: document as "replaces", let ad-hoc users copy the full default attrset if they want a clean override.
- **Should the flake include a `devShells.default` with the theme and an interactive `nix develop` that runs `sddm-greeter-qt6 --test-mode`?** Nice-to-have but not in the critical path. Defer.
- **Should the package's `meta` field include `mainProgram` or `broken`?** No — the package is a directory of assets, not a single executable. `meta.mainProgram` is omitted (nixpkgs convention).
- **Should we add a `passthru.updateScript` like `nix-update-script`?** Useful if the flake ever points at a git source. Out of scope since `src = ./.` is used.
- **Should the module add the theme to `environment.systemPackages` (so `sddm-greeter-qt6 --test-mode --theme $(which snow-crash)` works in a dev shell)?** No — `services.displayManager.sddm.extraPackages` already handles the runtime case, and `sddm-greeter-qt6 --test-mode --theme <store-path>` works directly against the built derivation.
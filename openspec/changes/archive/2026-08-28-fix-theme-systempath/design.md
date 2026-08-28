# Design: wire the theme package into environment.systemPackages too

## Context

The NixOS module added in `2026-08-27-add-nix-flake` exposes
`services.displayManager.sddm.snow-crash.enable` and, when set, wires:

```nix
config = lib.mkIf cfg.enable {
  services.displayManager.sddm = {
    theme = lib.mkDefault "snow-crash";
    extraPackages = [
      (pkgs.snow-crash-sddm.override { themeConfig = themeConfigAttrset; })
    ];
  };
  warnings = ...;
};
```

The original `design.md` ("Module wiring: theme name + extraPackages"
decision) stated:

> "The `extraPackages` mechanism is how the nixpkgs SDDM module
> injects packages into the greeter's runtime closure … This pulls
> the theme's `share/sddm/themes/snow-crash/` into
> `/run/current-system/sw/share/sddm/themes/snow-crash/`, where
> SDDM's `ThemeDir` resolution finds it by `Theme-Id`."

That claim is wrong against the current nixpkgs SDDM wrapper. The
chain is:

1. `nixos/modules/services/display-managers/sddm.nix` calls
   `sddm = cfg.package.override (old: { extraPackages = ... ++ cfg.extraPackages; });`.
2. `pkgs/applications/display-managers/sddm/default.nix` (nixpkgs)
   consumes `extraPackages` purely as `buildInputs` in the wrapper
   derivation:
   ```nix
   runCommand "sddm-wrapped" {
     buildInputs = sddm-unwrapped.buildInputs ++ extraPackages;
     ...
   } ''
     mkdir -p $out/bin
     cd ${sddm-unwrapped}
     for i in *; do
       if [ "$i" == "bin" ]; then continue; fi
       ln -s ${sddm-unwrapped}/$i $out/$i
     done
     ...
   ''
   ```
3. The wrapper `$out` is therefore a symlink-farm of `sddm-unwrapped`
   only. Nothing from `extraPackages` reaches `$out`. (Inspection of
   `/nix/store/cdnfbgidd7ni56gh7pyh5s4va1r2c0my-sddm-unwrapped-0.21.0`
   on a live deploy confirms the wrapper has `share/` symlinked to
   `sddm-unwrapped`'s `share/`, which contains only the bundled
   `elarun`/`maldives`/`maya` themes.)
4. NixOS only symlinks `/share/sddm` from each `environment.systemPackages`
   entry into `/run/current-system/sw/share/sddm/` (the SDDM module's
   `pathsToLink = [ "/share/sddm" ]`). The system closure therefore
   surfaces `share/sddm/themes/` only from packages in
   `environment.systemPackages`, not from `extraPackages`.

Live deploy confirmed: on `anvil` after rebuild,
`/run/current-system/sw/share/sddm/themes/` contained
`{elarun, maldives, maya}` — no `snow-crash/` — even though
`sddm.conf.d/00-nixos.conf` correctly emitted `Current=snow-crash`.
The greeter fell back to `maya` silently. The downstream consumer
in `~/Projects/nix-config/main/` worked around it by adding
`pkgs.snow-crash-sddm` to `environment.systemPackages` in
`profiles/nixos/linux-desktop.nix` (see
`openspec/changes/consume-snow-crash-sddm-flake/`).

Stakeholders:

- **The maintainer of this fork** — wants the module to be a one-liner
  import (`inputs.snow-crash-sddm.nixosModules.default`) that just
  works, without consumers having to know about the `extraPackages`
  vs `systemPackages` distinction.
- **The `nix-config` maintainer** — wants the workaround entry in
  `profiles/nixos/linux-desktop.nix` to be removable once the module
  is fixed.
- **The nixpkgs SDDM module** — unchanged by this fix; the fix
  accommodates the current nixpkgs behavior.

Constraints:

- The fix must not add new options or change existing ones — the 21
  typed options are already covered by the add-nix-flake change and
  consumers should not have to learn a new option.
- The fix must produce the SAME `theme.conf` whether SDDM loads it
  from the system path (via `ThemeDir`) or from the SDDM wrapper's
  runtime closure (via `XDG_DATA_DIRS`). Mismatched `theme.conf`
  content between the two locations would cause subtle visual bugs
  (e.g. a customized `panelWidth` that the QML picks up via one path
  but not the other).
- The fix must not introduce any new flake input, dependency, or
  build phase change in `package.nix`. The package derivation is
  unchanged.

## Goals / Non-Goals

**Goals:**

- `services.displayManager.sddm.snow-crash.enable = true;` causes the
  theme package to be installed at `/run/current-system/sw/share/sddm/themes/snow-crash/`
  with no other consumer-side configuration.
- The fix preserves the existing `extraPackages` entry so that the
  SDDM wrapper's runtime closure (which is what the original
  `extraPackages` mechanism actually populates) still contains the
  package — useful for users who want `sddm-greeter-qt6 --test-mode --theme $(which snow-crash)`
  to work against the wrapper's runtime closure.
- Both entries (extraPackages and systemPackages) MUST point at the
  same derivation so customized `theme.conf` content is consistent
  across both paths.

**Non-Goals:**

- Modifying the nixpkgs SDDM wrapper or NixOS SDDM module. The fix
  accommodates the current nixpkgs behavior; fixing the upstream
  modules is out of scope.
- Changing the package derivation, the flake shape, or any of the 21
  typed options.
- Removing the existing `extraPackages` entry entirely. Removing it
  would change the SDDM wrapper's runtime closure (a behavioral
  change beyond what's required) and the deduplication is harmless.
- Forcing consumers to migrate. The downstream workaround in
  `nix-config` continues to work; it's just redundant after this
  fix. Consumer cleanup is a separate follow-up.
- Adding a CI / `nix flake check` assertion that
  `/run/current-system/sw/share/sddm/themes/snow-crash/` is
  reachable, since this flake is a theme, not a NixOS configuration.

## Decisions

### Add to both `extraPackages` AND `environment.systemPackages`

Inside the existing `mkIf cfg.enable` block, set:

```nix
environment.systemPackages = [ themePkg ];
```

where `themePkg` is the same `pkgs.snow-crash-sddm.override
{ themeConfig = themeConfigAttrset; }` already passed to
`extraPackages`. Both lists therefore contain the same derivation,
built with the same `themeConfigAttrset`.

- **Rationale**: `extraPackages` populates the SDDM wrapper's runtime
  closure (useful for QML plugin propagation and for users running
  `sddm-greeter-qt6 --test-mode` against the wrapper). `systemPackages`
  is what NixOS symlinks into `/run/current-system/sw/share/sddm/themes/`,
  which is the path SDDM's `ThemeDir` resolution actually consults.
  Adding to both costs nothing (Nix deduplicates the resulting
  derivation hash) and matches the principle of "put the package
  wherever SDDM looks for it".
- **Alternatives considered**:
  - **Drop `extraPackages`, add only `systemPackages`**: Rejected
    because it changes the SDDM wrapper's runtime closure (a
    behavioral change beyond what's required) and removes the
    package from the closure that the original `extraPackages`
    mechanism actually populates. Users who test the theme via
    `sddm-greeter-qt6 --test-mode` from a `nix-shell` with the
    module enabled would lose that capability.
  - **Drop both `extraPackages` and `systemPackages`, override
    `services.displayManager.sddm.package`**: Rejected as a much
    heavier hammer (replaces the entire SDDM package) and unrelated
    to the bug.
  - **Document the gotcha and require consumers to add the package
    to `systemPackages` themselves**: Rejected because the whole
    point of a NixOS module is to encapsulate this kind of wiring.
    Consumers shouldn't have to know that NixOS symlinks `share/sddm`
    only from `systemPackages`.

### Single shared `let` binding for the overridden derivation

Bind `themePkg` once at the top of the `let`:

```nix
let
  cfg = config.services.displayManager.sddm.snow-crash;
  themeConfigAttrset = { General = { ... }; };
  themePkg = pkgs.snow-crash-sddm.override { themeConfig = themeConfigAttrset; };
  ...
in {
  ...
  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      theme = lib.mkDefault "snow-crash";
      extraPackages = [ themePkg ];
    };
    environment.systemPackages = [ themePkg ];
    warnings = ...;
  };
}
```

- **Rationale**: Two literals `pkgs.snow-crash-sddm.override { ... }`
  would evaluate the same derivation twice (Nix would dedup the
  result, but the duplication in source is noise). A shared `let`
  binding makes the "both entries MUST match" requirement visible at
  the source level.
- **Alternatives considered**:
  - **Use the same `themeConfigAttrset` attrset literal in both
    places**: Rejected for the same reason — the requirement is
    "same derivation", not "same config"; a shared binding enforces
    it.

### No new options, no new module attributes

The fix uses only the existing `services.displayManager.sddm.snow-crash.enable`
gate. No new `mkOption`, no `environment.etc.*` entry, no
`systemd.*` entry.

- **Rationale**: The fix is a single one-line addition; adding a
  new option (e.g. `services.displayManager.sddm.snow-crash.systemPackages`)
  would inflate the API surface for no benefit. The `enable` option
  is the existing user-facing toggle; consumers already understand
  "enable the module" without knowing what it does under the hood.
- **Alternatives considered**:
  - **Expose `addToSystemPackages = true` as an option with
    default `true`**: Rejected for the same reason. If a consumer
    wants the package in `systemPackages`, they enable the module.
    The toggle is the module itself.
  - **Always add to `systemPackages` regardless of `enable`**:
    Rejected because it would change the package set of any host
    that imports the module but doesn't want the theme. The `mkIf
    cfg.enable` gate keeps the change opt-in.

### Update the existing spec scenario text (not remove + replace)

The `Enable adds theme package to extraPackages` scenario is REVISED
in place: the misleading clause ("so the built theme's `share/sddm/themes/snow-crash/`
is in the SDDM runtime closure") is replaced with an accurate
description of what `extraPackages` actually does. A new scenario
`Enable adds theme package to environment.systemPackages` is ADDED
to document the mechanism that actually surfaces the theme
directory. A third scenario `Both entries share the same customized
derivation` is ADDED to prevent regression.

- **Rationale**: The `extraPackages` entry is still useful (it puts
  the package into the SDDM wrapper's runtime closure for QML plugin
  propagation). The scenario was just describing the wrong effect.
  Revising in place keeps the spec consistent with what the code
  actually does; the new scenarios add the requirements that were
  missing.
- **Alternatives considered**:
  - **Remove `Enable adds theme package to extraPackages` entirely**:
    Rejected because the `extraPackages` entry is still required
    (see "Add to both `extraPackages` AND `environment.systemPackages`"
    decision above). Removing the scenario would imply the entry can
    be removed.
  - **Split into two separate requirements**: Rejected because the
    "wires SDDM when enabled" requirement is the right scope for
    both entries — splitting would scatter related behavior.

### Update the add-nix-flake `design.md` "Module wiring" decision

The `add-nix-flake/openspec/changes/archive/2026-08-27-add-nix-flake/design.md`
"Module wiring: theme name + extraPackages" decision block contains
the same incorrect claim about `extraPackages`. After this change
lands, the archived `design.md` will be wrong; the spec is corrected
by this change, but the archived rationale will still misdescribe
the mechanism.

- **Rationale**: Archived `design.md` files are historical records
  of decisions made at the time; editing them post-archive loses
  the audit trail. The correct action is to leave the archive alone
  and reference this change in the consumer-side documentation.
- **Alternatives considered**:
  - **Edit the archived `design.md` to add a "Correction" note**:
    Acceptable but not done in this change. The downstream consumer
    change (`consume-snow-crash-sddm-flake/design.md`) already has a
    Risks note pointing to this upstream change as the source of
    truth.

## Risks / Trade-offs

- **Consumers who already added `pkgs.snow-crash-sddm` to
  `environment.systemPackages` (e.g. the `nix-config` workaround)
  end up with a redundant entry.** The downstream consumer change
  is documented as having a follow-up to drop the workaround once
  this fix lands. The redundancy is harmless — Nix deduplicates the
  package in the system closure, so the user does not see any
  payload or evaluation cost increase. Mitigation: document the
  cleanup path in the downstream change.

- **Adding to `environment.systemPackages` makes the package show
  up in `nix-env -q` for root and in `$PATH` / `$XDG_DATA_DIRS` for
  the system profile.** The package has no `bin/` output (only
  `share/sddm/themes/snow-crash/`), so it adds no commands to the
  shell. The `share/sddm/themes/snow-crash/` becomes reachable via
  `/run/current-system/sw/share/sddm/themes/snow-crash/` for any
  process — which is the intended effect. Mitigation: none needed.

- **The change assumes that `environment.systemPackages` is the
  intended destination for theme packages.** If a future nixpkgs
  SDDM module release changes `pathsToLink` to symlink additional
  paths from `extraPackages`, the `systemPackages` entry becomes
  redundant. At that point the fix can be simplified back to
  `extraPackages`-only. Mitigation: the fix is a single-line
  addition; reverting is trivial.

- **The `extraPackages` entry duplicates the derivation hash in
  the system closure's input set.** With both `extraPackages` and
  `systemPackages` containing the same `pkgs.snow-crash-sddm.override
  { ... }`, Nix produces one derivation hash (Nix deduplicates by
  hash), but the toplevel input set lists it twice. No evaluation
  cost or build cost increases. Mitigation: not needed.

- **The fix does not verify that SDDM can find the theme at
  runtime.** `nix flake check` only evaluates Nix expressions; it
  does not boot SDDM and check the rendered greeter. The consumer
  side (`nix-config`) is expected to verify with a live deploy. The
  downstream `consume-snow-crash-sddm-flake` change's live-deploy
  tasks (7.2, 8.2) exercise this end-to-end.

## Migration Plan

Apply steps:

1. Edit `nixosModules/default.nix`:
   - Move the `pkgs.snow-crash-sddm.override { themeConfig = themeConfigAttrset; }`
     expression into a `let` binding named `themePkg`.
   - Replace the inline override in `services.displayManager.sddm.extraPackages`
     with `themePkg`.
   - Add `environment.systemPackages = [ themePkg ];` inside the
     same `config = lib.mkIf cfg.enable { ... }` block.
2. Update `openspec/specs/snow-crash-theme/spec.md` per the
   spec-delta file in this change.
3. Run `nix flake check` from the repo root and confirm zero errors
   on `x86_64-linux` and `aarch64-linux`.
4. Run `nix build .#default` and confirm the output is unchanged
   (same store path as before, since `package.nix` is not touched).
5. Run `openspec validate fix-theme-systempath` from the repo root
   and confirm the change validates (proposal, design, tasks, spec
   delta all consistent).
6. Commit per the repo's conventional-commits style as
   `fix(nixos-module): also add theme package to environment.systemPackages`.

Rollback:

- Revert the commit. The module goes back to `extraPackages`-only,
  and the theme stops loading at the system path (consumers that
  relied on the workaround continue to work; consumers that didn't
  see the silent fallback return). The `extraPackages`-only state
  matches the add-nix-flake change's documented behavior, so a
  rollback is in-policy.

Verification (consumer side, not in this change):

- Consumer rebuild (`sudo nixos-rebuild switch --flake .#anvil` in
  `~/Projects/nix-config/main/`) followed by reboot should show the
  Snow Crash theme. The consumer's `nix flake check` already runs
  against the new upstream input.

## Open Questions

- **Should the consumer-side workaround entry
  (`pkgs.snow-crash-sddm` in `environment.systemPackages` in
  `nix-config/profiles/nixos/linux-desktop.nix`) be removed as
  part of this change, or in a separate consumer-side follow-up?**
  Recommendation: separate follow-up in `nix-config`. This change
  is upstream-only and consumers can migrate at their own pace.
  The redundancy is harmless in the meantime.

- **Should the module add a `services.displayManager.sddm.snow-crash.enableAssertSystemPath`
  option that asserts the theme directory is reachable at
  `/run/current-system/sw/share/sddm/themes/snow-crash/` after
  evaluation?** Tempting for catching future nixpkgs changes that
  might break the wiring, but `nix flake check` already runs
  `nixos-rebuild` evaluation against the test VM in some setups, and
  adding more assertions adds complexity. Recommendation: skip;
  rely on consumer-side live deploy for end-to-end verification.

- **Should `flake.nix` add a `checks.<system>.sddm-theme-systempath`
  derivation that builds a minimal NixOS test VM importing the
  module and asserts the theme directory exists in the system
  closure?** Rejected — out of scope for a theme flake. nixpkgs's
  own SDDM tests cover the wrapper behavior; our flake is downstream
  and the live deploy catches regressions faster than a test VM.

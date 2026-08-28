## 1. Module wiring

- [x] 1.1 Open `nixosModules/default.nix` and locate the existing
      `config = lib.mkIf cfg.enable { ... }` block (currently sets
      `services.displayManager.sddm.theme = lib.mkDefault "snow-crash";`
      and `services.displayManager.sddm.extraPackages = [ (pkgs.snow-crash-sddm.override { themeConfig = themeConfigAttrset; }) ];`)
- [x] 1.2 Introduce a `let` binding `themePkg = pkgs.snow-crash-sddm.override { themeConfig = themeConfigAttrset; };`
      inside the existing `let` block so the overridden derivation is
      named once and reused
- [x] 1.3 Replace the inline `pkgs.snow-crash-sddm.override { ... }` in
      `services.displayManager.sddm.extraPackages` with the `themePkg`
      binding: `extraPackages = [ themePkg ];`
- [x] 1.4 Add `environment.systemPackages = [ themePkg ];` inside the
      same `config = lib.mkIf cfg.enable { ... }` block, immediately
      after the `services.displayManager.sddm` attrset
- [x] 1.5 Confirm `nixosModules/default.nix` still compiles: the
      `themePkg` binding is in scope for both `extraPackages` and
      `environment.systemPackages`, the `mkIf cfg.enable` gate still
      wraps both, and the `warnings` block is unchanged

## 2. Spec delta

- [x] 2.1 Verify the spec delta at
      `openspec/changes/fix-theme-systempath/specs/snow-crash-theme/spec.md`
      contains exactly one `### Requirement:` block (the
      `NixOS module wires SDDM when enabled` requirement, MODIFIED)
      with the following scenarios in order:
      - `Enable sets theme with mkDefault priority` (text unchanged)
      - `Enable sets theme with mkForce priority` (text unchanged)
      - `Enable adds theme package to extraPackages` (revised text —
        the "so the built theme's share/sddm/themes/snow-crash/ is in
        the SDDM runtime closure" clause is replaced with an
        accurate description of what `extraPackages` actually does)
      - `Enable adds theme package to environment.systemPackages` (NEW
        scenario — documents the new wiring)
      - `Both entries share the same customized derivation` (NEW
        scenario — regression guard against re-evaluating the override
        twice with mismatched attrs)
      - `Enable is off by default` (text unchanged)
      - `Warn when SDDM is not enabled` (text unchanged)
- [x] 2.2 Confirm every scenario uses `####` (four hashtags) — three
      hashtags or bullets fail validation silently

## 3. Verification

- [x] 3.1 Run `nix flake check` from the repo root and confirm zero
      errors on `x86_64-linux` and `aarch64-linux`
- [x] 3.2 Run `nix build .#default` and confirm the output store path
      is unchanged from the previous build (`package.nix` was not
      touched, so the hash should match)
- [x] 3.3 Run `nix build .#default` against both `x86_64-linux` and
      `aarch64-linux` and confirm both produce the same package
      output as before (no architecture-specific surprises in the
      new `systemPackages` entry — `pkgs.snow-crash-sddm` is
      `lib.platforms.linux` only and the module is only imported
      under NixOS)
- [x] 3.4 Run `openspec validate fix-theme-systempath` from the repo
      root and confirm the change validates (proposal, design,
      tasks, spec delta all consistent with each other and with the
      `openspec/specs/snow-crash-theme/spec.md` archive target)
- [x] 3.5 (Manual, consumer-side, NOT in this change) The downstream
      `~/Projects/nix-config/main/` consumer is expected to rebuild
      and verify the theme appears at login after reboot. That
      verification lives in
      `openspec/changes/consume-snow-crash-sddm-flake/tasks.md` task
      7.2 / 8.2, not here.
- [x] 3.6 (Local NixOS test config, in this change) Build a minimal
      `pkgs.nixos { ... }` that imports `flake.nixosModules.default`,
      enables `services.displayManager.sddm.snow-crash.enable`, sets
      `snow-crash.panelWidth = 600` and `snow-crash.subtitle = "Sign
      in to test"`, and verify that `config.system.path` contains
      `share/sddm/themes/snow-crash/theme.conf` with `panelWidth=600`
      and `subtitle=Sign in to test`, and that
      `services.displayManager.sddm.extraPackages` and
      `environment.systemPackages` resolve to the SAME derivation
      hash. Confirmed via `.test-snow-crash-module.nix` (removed
      after verification).

## 4. Commit and archive

- [x] 4.1 Stage and commit the implementation as a single
      `fix(nix): also add theme package to environment.systemPackages`
      commit touching only `nixosModules/default.nix` (commit
      `36cd306`)
- [x] 4.2 Run `openspec archive fix-theme-systempath` from the repo
      root to move the change directory into
      `openspec/changes/archive/2026-08-27-fix-theme-systempath/` and
      sync the spec delta into `openspec/specs/snow-crash-theme/spec.md`
- [ ] 4.3 Push the commit + archive to `origin/main`

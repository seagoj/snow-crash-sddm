# SPDX-License-Identifier: MIT
#
# NixOS module for the Snow Crash SDDM theme.
#
# Exposes 21 typed options under `services.displayManager.sddm.snow-crash.*`
# — one per `theme.conf` and `theme.conf.user` key. When enabled, builds
# the theme package with the module's options passed as `themeConfig` and
# adds it to `services.displayManager.sddm.extraPackages`.
#
# The `theme` option is set with `lib.mkDefault` so an explicit user-set
# theme name still wins.
#
# See `openspec/changes/add-nix-flake/design.md` for the rationale
# behind each option's type and the nixpkgs convention comparison.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.displayManager.sddm.snow-crash;
  # Shape passed to the package's `themeConfig` arg: matches the
  # `where-is-my-sddm-theme` package's `{ General = { ... }; }`
  # convention. `showClock` and `type` originate from the bundled
  # `theme.conf.user` and are now colocated with the rest of the
  # theme config — see design.md Decision "Single themeConfig attrset".
  themeConfigAttrset = {
    General = {
      background       = cfg.background;
      panelWidth       = cfg.panelWidth;
      panelHeight      = cfg.panelHeight;
      panelMargin      = cfg.panelMargin;
      panelRadius      = cfg.panelRadius;
      fieldHeight      = cfg.fieldHeight;
      buttonHeight     = cfg.buttonHeight;
      panelOpacity     = cfg.panelOpacity;
      accentOpacity    = cfg.accentOpacity;
      borderOpacity    = cfg.borderOpacity;
      textColor        = cfg.textColor;
      mutedTextColor   = cfg.mutedTextColor;
      accentColor      = cfg.accentColor;
      borderColor      = cfg.borderColor;
      errorColor       = cfg.errorColor;
      title            = cfg.title;
      subtitle         = cfg.subtitle;
      showPowerButtons = cfg.showPowerButtons;
      showClock        = cfg.showClock;
      type             = cfg.type;
    };
  };
in
{
  options.services.displayManager.sddm.snow-crash = {
    enable = lib.mkEnableOption "Snow Crash SDDM theme";

    # ── Panel dimensions (QML: config.intValue(...)) ──
    panelWidth = lib.mkOption {
      type = lib.types.int;
      default = 420;
      description = "Width of the login panel in pixels. Consumed by Main.qml as config.intValue(\"panelWidth\").";
    };
    panelHeight = lib.mkOption {
      type = lib.types.int;
      default = 340;
      description = "Height of the login panel in pixels. Consumed by Main.qml as config.intValue(\"panelHeight\").";
    };
    panelMargin = lib.mkOption {
      type = lib.types.int;
      default = 120;
      description = "Margin around the login panel in pixels. Consumed by Main.qml as config.intValue(\"panelMargin\").";
    };
    panelRadius = lib.mkOption {
      type = lib.types.int;
      default = 18;
      description = "Corner radius of the login panel in pixels. Consumed by Main.qml as config.intValue(\"panelRadius\").";
    };
    fieldHeight = lib.mkOption {
      type = lib.types.int;
      default = 46;
      description = "Height of the username/password input fields in pixels. Consumed by Main.qml as config.intValue(\"fieldHeight\").";
    };
    buttonHeight = lib.mkOption {
      type = lib.types.int;
      default = 46;
      description = "Height of the login button in pixels. Consumed by Main.qml as config.intValue(\"buttonHeight\").";
    };

    # ── Opacities (QML: config.realValue(...)) ──
    # Bounded to [0.0, 1.0] since opacity is meaningless outside that range.
    panelOpacity = lib.mkOption {
      type = lib.types.numbers.between 0.0 1.0;
      default = 0.30;
      description = "Opacity of the login panel background. Consumed by Main.qml as config.realValue(\"panelOpacity\").";
    };
    accentOpacity = lib.mkOption {
      type = lib.types.numbers.between 0.0 1.0;
      default = 0.10;
      description = "Opacity of the accent shading on the panel. Consumed by Main.qml as config.realValue(\"accentOpacity\").";
    };
    borderOpacity = lib.mkOption {
      type = lib.types.numbers.between 0.0 1.0;
      default = 0.18;
      description = "Opacity of the panel border. Consumed by Main.qml as config.realValue(\"borderOpacity\").";
    };

    # ── Colors (QML: config.stringValue(...) → property color) ──
    # The QML's `property color` accepts any QML-parseable color spec
    # (hex, named colors, rgb()). Hex is the bundled default. No regex
    # validation here — the QML is the validator at render time.
    textColor = lib.mkOption {
      type = lib.types.str;
      default = "#f4f4f5";
      description = "Foreground text color (any QML-parseable color spec). Consumed by Main.qml as config.stringValue(\"textColor\").";
    };
    mutedTextColor = lib.mkOption {
      type = lib.types.str;
      default = "#b9bdc5";
      description = "Muted text color. Consumed by Main.qml as config.stringValue(\"mutedTextColor\").";
    };
    accentColor = lib.mkOption {
      type = lib.types.str;
      default = "#ffffff";
      description = "Accent color used for highlights and focus rings. Consumed by Main.qml as config.stringValue(\"accentColor\").";
    };
    borderColor = lib.mkOption {
      type = lib.types.str;
      default = "#ffffff";
      description = "Color of the panel border. Consumed by Main.qml as config.stringValue(\"borderColor\").";
    };
    errorColor = lib.mkOption {
      type = lib.types.str;
      default = "#f38ba8";
      description = "Color used for login error messages. Consumed by Main.qml as config.stringValue(\"errorColor\").";
    };

    # ── Display text ──
    title = lib.mkOption {
      type = lib.types.str;
      default = "Snow Crash";
      description = "Title text shown at the top of the login panel. Consumed by Main.qml as config.stringValue(\"title\").";
    };
    subtitle = lib.mkOption {
      type = lib.types.str;
      default = "Sign in";
      description = "Subtitle text shown beneath the title. Consumed by Main.qml as config.stringValue(\"subtitle\").";
    };

    # ── Toggles (QML: config.boolValue(...)) ──
    showPowerButtons = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to show power/restart buttons. Consumed by Main.qml as config.boolValue(\"showPowerButtons\").";
    };
    showClock = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to display a clock on the greeter. Originated in the bundled theme.conf.user; SDDM-system setting.";
    };

    # ── SDDM-system key (originally in theme.conf.user) ──
    # The QML does not read this key; SDDM's greeter uses it to decide
    # how to render the background. Valid values per SDDM docs include
    # \"image\", \"color\", \"animation\". Left as a free-form string so
    # future SDDM values don't require a module update.
    type = lib.mkOption {
      type = lib.types.str;
      default = "image";
      description = "Background type passed to SDDM's greeter. Originated in the bundled theme.conf.user. Common values: image, color, animation.";
    };

    # ── Background image ──
    # Main.qml's `Image.source` is hardcoded to the literal
    # \"snow-crash.png\" — this option configures the *secondary*
    # `background` key that `theme.conf` advertises. If Main.qml is
    # ever updated to consume `config.stringValue(\"background\")`,
    # this option takes effect automatically.
    background = lib.mkOption {
      type = lib.types.str;
      default = "snow-crash.png";
      description = "Background image filename (relative to the theme directory) or absolute path. Mirrors the bundled theme.conf background key.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      # mkDefault so an explicit user-set theme name still wins.
      theme = lib.mkDefault "snow-crash";
      # Bring the theme directory into the SDDM runtime closure so
      # ThemeDir resolution finds it under `/run/current-system/sw/share/sddm/themes`.
      extraPackages = [
        (pkgs.snow-crash-sddm.override { themeConfig = themeConfigAttrset; })
      ];
    };

    # Surface a configuration smell: enabling the theme without enabling
    # SDDM itself is almost certainly a misconfiguration. Warn (not throw)
    # so the user can still evaluate the system during bring-up.
    # NOTE: this attribute MUST live inside `config`, not at the
    # top level of the module — the NixOS module system rejects
    # top-level `warnings` with `error: Module ... has an
    # unsupported attribute 'warnings'. This is caused by
    # introducing a top-level 'config' or 'options' attribute.`
    # See https://github.com/NixOS/nixpkgs/issues — captured in the
    # snow-crash-sddm change log when this was fixed during the
    # nix-config consumption follow-up.
    warnings = lib.optional (cfg.enable && !config.services.displayManager.sddm.enable) ''
      services.displayManager.sddm.snow-crash.enable is true but
      services.displayManager.sddm.enable is false. The Snow Crash theme
      will not be active until SDDM itself is enabled.
    '';
  };
}
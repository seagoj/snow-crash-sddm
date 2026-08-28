# SPDX-License-Identifier: MIT
#
# Nix package for the Snow Crash SDDM theme.
#
# Mirrors the nixpkgs convention for SDDM theme packages: accepts a
# `themeConfig ? null` override argument and writes `theme.conf` from
# it via `formats.ini` when provided. The bundled `theme.conf` and
# `theme.conf.user` are shipped as-is from `src` when `themeConfig`
# is null, so ad-hoc users who want the bundled defaults can build
# the package without supplying any config.
#
# See `openspec/changes/add-nix-flake/design.md` for the rationale
# and the surveyed nixpkgs conventions this derivation follows.
{
  lib,
  stdenvNoCC,
  formats,
  # Override attrset of shape `{ <section> = { key = value; ... }; }`.
  # When null, the bundled theme.conf is copied as-is.
  # When non-null, an INI file is generated from it and written to
  # `theme.conf` in the output. The bundled `theme.conf.user` is
  # always preserved verbatim.
  themeConfig ? null,
}:

let
  isAttrs = themeConfig != null;
  iniFormat = formats.ini { };
in
stdenvNoCC.mkDerivation {
  pname = "snow-crash-sddm";
  version = "0.2.0";

  src = ./.;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sddm/themes/snow-crash
    cp -r $src/. $out/share/sddm/themes/snow-crash/
    # The cp above copies read-only sources; the theme.conf write
    # below needs write permission on the destination directory.
    chmod -R u+w $out/share/sddm/themes/snow-crash/

    ${lib.optionalString isAttrs ''
      # Generated theme.conf from the override attrset. The bundled
      # theme.conf in $src is overwritten with the Nix-derived one.
      # The bundled theme.conf.user is preserved unchanged (see 2.4).
      cp ${iniFormat.generate "theme.conf" themeConfig} \
         $out/share/sddm/themes/snow-crash/theme.conf
    ''}

    runHook postInstall
  '';

  meta = {
    description = "Minimal static SDDM theme with the Snow Crash wallpaper";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
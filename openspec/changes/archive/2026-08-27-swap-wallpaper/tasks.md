## 1. Asset preparation

- [x] 1.1 Copy `snow-crash.png` from `~/Projects/nix-config/main/assets/wallpapers/snow-crash.png` into the theme root as `snow-crash.png` (preserve bytes — no re-encoding)
- [x] 1.2 Delete the existing `background.jpg` from the theme root
- [x] 1.3 Verify `snow-crash.png` exists at the theme root and `background.jpg` is gone (e.g. `ls -la`)

## 2. Theme code updates

- [x] 2.1 In `Main.qml`, change the `Image` element's `source: "background.jpg"` to `source: "snow-crash.png"` (preserve the rest of the file verbatim)
- [x] 2.2 In `theme.conf`, change `background=background.jpg` to `background=snow-crash.png`
- [x] 2.3 In `theme.conf`, change `title=Artemis II` to `title=Snow Crash`

## 3. Theme metadata updates

- [x] 3.1 In `metadata.desktop`, set `Name=Snow Crash SDDM` (replacing the current `Name=Artemis II Moon Eclipse`)
- [x] 3.2 In `metadata.desktop`, update `Description` to describe the Snow Crash wallpaper instead of the lunar eclipse
- [x] 3.3 In `metadata.desktop`, set `Author=Jason Sackett; Snow Crash variant by Jeremy` (preserving upstream attribution per MIT)
- [x] 3.4 In `metadata.desktop`, change `Theme-Id=artemisii-moon-eclipse` to `Theme-Id=snow-crash`
- [x] 3.5 In `metadata.desktop`, change `Version=0.1.0` to `Version=0.2.0`
- [x] 3.6 In `PKGBUILD`, change `pkgname=sddm-theme-artemisii-moon-eclipse` to `pkgname=sddm-theme-snow-crash`
- [x] 3.7 In `PKGBUILD`, update `pkgdesc` to describe the Snow Crash wallpaper
- [x] 3.8 In `PKGBUILD`, change the `source` array entry to `snow-crash-sddm.tar.gz`
- [x] 3.9 In `PKGBUILD`, change the `cp -r "$srcdir/artemisii-moon-eclipse-sddm/."` source directory to `"$srcdir/snow-crash-sddm/."`
- [x] 3.10 In `PKGBUILD`, change the install target `artemisii-moon-eclipse` to `snow-crash`
- [x] 3.11 Replace `preview.png` with a byte-identical copy of `snow-crash.png` (preserve the file name `preview.png` so `metadata.desktop`'s `Screenshot=preview.png` reference still works)

## 4. Documentation and licensing

- [x] 4.1 Add a `LICENSE` file at the theme root containing the MIT license text and a copyright line crediting Jason Sackett as the original theme code author (year and maintainer name per `design.md` open question resolution)
- [x] 4.2 Rewrite the `README.md` title and opening description for the Snow Crash identity
- [x] 4.3 In `README.md`, update all install command examples to use `/usr/share/sddm/themes/snow-crash/` instead of `artemisii-moon-eclipse`
- [x] 4.4 In `README.md`, add a "Wallpaper attribution" section crediting TehAnon with links to the r/wallpapers post and the imgur source
- [x] 4.5 In `README.md`, replace the upstream "Licenses" section's NASA attribution with a "Theme code license" section pointing to the new `LICENSE` file

## 5. Verification

- [x] 5.1 Run `grep -rn "artemisii" --include="*.qml" --include="*.conf" --include="*.desktop" --include="*.md" --include="PKGBUILD" .` and confirm zero matches in theme files (excluding `openspec/` and `.git/`)
- [x] 5.2 Run `openspec validate swap-wallpaper` from the theme root and confirm the change still validates
- [x] 5.3 If `sddm-greeter-qt6` is available, run `sddm-greeter-qt6 --test-mode --theme "$PWD"` from the theme root and confirm the greeter window renders with the snow-crash wallpaper
- [x] 5.4 Confirm `snow-crash.png` and `preview.png` have the same dimensions (1920×1200) and visually identical content

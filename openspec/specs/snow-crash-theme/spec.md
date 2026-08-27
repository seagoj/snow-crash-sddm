# snow-crash-theme Specification

## Purpose
TBD - created by archiving change swap-wallpaper. Update Purpose after archive.
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


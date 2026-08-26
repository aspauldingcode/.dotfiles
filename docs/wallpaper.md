# Wallpaper (macOS + Linux)

Unified declarative wallpaper + **daily official base16** theming across nix-darwin and NixOS (**1:1**).

Scheme-first: applications get Gruvbox / Catppuccin / Tokyo Night / … palettes. lutgen-rs **recolors** the wallpaper toward that palette (Gaussian Hald CLUT) — it does not extract a scheme from the photo.

## How it works

1. **Build-time pack** (`modules/apps/_wallpaper-catalog.nix` + `_wallpaper-pack.nix`)
   - Scenic light/dark **pairs** (cityscapes, mountains, wildlife, forest, coast)
   - Theme **families** from `pkgs.base16-schemes` (plus vendored Kanagawa lotus / Dracula light)
   - Each image is normalized to PNG + `auth-blur.png`
   - Each family ships `colors-{dark,light}.toml`, lutgen palette names, and hex JSON fallback

2. **Stylix rebuild seed**
   - GTK / store packages still come from [`theme-selection.nix`](../theme-selection.nix) on `nh darwin/os switch`
   - `stylix.image` is a pack PNG for greeter/rebuild only

3. **Runtime** (`dendritic-appearance wallpaper …`)
   - Day-of-year → same **theme family** and **wallpaper pair** on every host that day
   - Host appearance (`AppleInterfaceStyle` / gsettings) selects the light vs dark pole of **both**
   - Copies that family's `colors.toml` → `~/.colors.toml`
   - `lutgen apply` tints the photo (cached under `~/.cache/dendritic/lutgen/`)
   - Desktop: **WallpaperKit** (`allDisplays` / Show on all Spaces) / **swaybg**
   - Hot layer: IDE / Ghostty / Qt / neovim / macOS tint
   - `daily` pre-converts both polarities so appearance toggle is instant

On **macOS**, `dendritic-appearance` `dlopen`s **WallpaperKit** (from
`macos-wallpaper-daemon-rse`): catalog the lutgen PNG the way System Settings
→ Wallpaper → Your Photos → Choose File… does, then write
`WallpaperUserSettings.allDisplays` so **Show on all Spaces** is on. Idle
(lock) stays the next pair via the existing Index.plist patch.

4. **Auth / lock**
   - **Linux gtkgreet + gtklock:** same image as the desktop (1:1)
   - **macOS Idle:** next pair, same polarity + theme
   - CLI: `wallpaper auth-path` / `lock-path` / `lock`

5. **Schedule**
   - launchd agent / systemd user timer at **00:05** local
   - Also runs on HM activation

## Theme vs rebuild

| Layer                                                        | When it updates                                            |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| Desktop wallpaper + `~/.colors.toml` + Ghostty/IDE/nvim/tint | **On every wallpaper/theme change** (daily / next / named) |
| Full Stylix store packages (gtk theme, etc.)                 | **On `nh darwin/os switch`** from `theme-selection.nix`    |

Rotating the daily family **does** change the live palette. It does **not** rebuild every Stylix package each morning.

## Daily pairing

Same calendar day ⇒ same family + same pair. Appearance only flips the pole:

- Daytime: `gruvbox-light-hard` + sunny harbor, lutgen'd to that palette
- Night: `gruvbox-dark-hard` + starry ridge, lutgen'd to that palette

`next` advances the **pair**, keeping today's family. Named args can be a pair id, wallpaper name, or theme family.

## CLI

```bash
dendritic-appearance wallpaper daily     # today's pair + family (both poles cached)
dendritic-appearance wallpaper next      # next pair, same family
dendritic-appearance wallpaper skyline   # named pair
dendritic-appearance wallpaper gruvbox   # named family, current pair
dendritic-appearance wallpaper auth-path
dendritic-appearance wallpaper lock-path
dendritic-appearance wallpaper lock
dendritic-appearance list-wallpapers
dendritic-appearance list-themes
dendritic-appearance status
dendritic-appearance set light|dark      # appearance + matching pole
```

See also [appearance.md](./appearance.md) for the light/dark state machine.

## Extending the pack

Drop PNGs into `./wallpapers/` (or set `extraDatabase`) named `*-light` / `*-dark` and rebuild. Unpaired files are polarity-neutral (same photo, both palettes).

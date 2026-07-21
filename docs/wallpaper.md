# Wallpaper (macOS + Linux)

Unified declarative wallpaper + daily base16 theming across nix-darwin and NixOS (**1:1**).

## How it works

1. **Build-time pack** (`modules/apps/_wallpaper-pack.nix`)
   - Merges optional local `./wallpapers/` with curated `nixos-artwork` images
   - Normalizes each image to PNG + prebuilds `auth-blur.png` for gtk auth glass
   - Runs **flavours** (`flavours generate dark|light`) → full base16 YAML + `colors-{dark,light}.toml`
   - Why flavours (not gowall)? `gowall extract` only returns ~6 pywal-style colors.
     Stylix needs a full base16 scheme; flavours is the colorthief→base16 path.
     `gowall` remains optional for manual tint/effects (`dendritic.wallpaper.gowall.enable`).

2. **Stylix seed** (`themeFromImage`, default on)
   - At rebuild, `stylix.image` + `stylix.base16Scheme` come from
     `dendritic.wallpaper.selected` (default `moonscape`)
   - That seeds packages that only theme at build time (gtk, some chrome)

3. **Runtime wallpaper change** (`dendritic-appearance wallpaper …` — pure Rust)
   - Same CLI + daily timer on **Darwin (launchd)** and **NixOS (systemd --user)**
   - Day-of-year index → same wallpaper name on every host that day
   - Sets desktop wallpaper: **macos-wallpaper** / **swaybg**
   - Copies that wallpaper’s prebuilt palette → `~/.colors.toml`
   - **Hot theme layer (follows the wallpaper, both OSes):**
     - IDE `workbench.colorCustomizations` (Cursor / VS Code / Antigravity)
     - tmux `~/.config/tmux/theme.conf`
     - Ghostty theme `~/.config/ghostty/themes/dendritic-wallpaper` + SIGUSR2
       (theme file, not `config-file` — macOS double-loads config and cycles includes)
     - macOS accent tint from `base0D`
     - neovim watches `~/.colors.toml` (mini.base16)
   - Then reconciles light/dark so layers never desync

4. **Runtime auth / lock**
   - **Linux gtkgreet + gtklock:** same image as the desktop (1:1)
   - **macOS Idle:** next pack entry ≠ desktop
   - CLI: `wallpaper auth-path` / `lock-path` / `lock`

5. **Schedule**
   - launchd agent / systemd user timer at **00:05** local
   - Also runs on HM activation

## Theme vs rebuild

| Layer                                                             | When it updates                                      |
| ----------------------------------------------------------------- | ---------------------------------------------------- |
| Desktop wallpaper + `~/.colors.toml` + Ghostty/tmux/IDE/nvim/tint | **On every wallpaper change** (daily / next / named) |
| Full Stylix store packages (gtk theme, etc.)                      | **On `nh darwin/os switch`** from `selected`         |

So: rotating wallpaper **does** change the live theme to that image’s build-time palette.
It does **not** rebuild every Stylix package derivation each morning.

## CLI

```bash
dendritic-appearance wallpaper daily     # today's desktop (+ Linux auth 1:1; macOS Idle ≠)
dendritic-appearance wallpaper next      # rotate desktop + hot theme
dendritic-appearance wallpaper nineish   # named desktop + hot theme
dendritic-appearance wallpaper auth-path
dendritic-appearance wallpaper lock-path
dendritic-appearance wallpaper lock
dendritic-appearance list-wallpapers
dendritic-appearance status
```

See also [appearance.md](./appearance.md) for the light/dark state machine.

## Extending the pack

Drop PNGs into `./wallpapers/` (or set `extraDatabase`) and rebuild — flavours regenerates schemes for every entry.

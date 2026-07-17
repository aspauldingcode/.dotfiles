# Wallpaper (macOS + Linux)

Unified declarative wallpaper + daily base16 theming across nix-darwin and NixOS.

## How it works

1. **Build-time pack** (`modules/apps/_wallpaper-pack.nix`)
   - Merges optional local `./wallpapers/` with curated `nixos-artwork` images
   - Normalizes each image to PNG + prebuilds `auth-blur.png` for gtk auth glass
   - Runs **flavours** to extract dark + light base16 YAML
2. **Stylix** (`themeFromImage`, default on)
   - `stylix.image` + `stylix.base16Scheme` come from `dendritic.wallpaper.selected`
   - Supplies Stylix chrome tokens (colors/fonts) for gtkgreet/gtklock CSS
3. **Runtime desktop** (`dendritic-appearance wallpaper …` — pure Rust)
   - Picks wallpaper by day-of-year — same day ⇒ same wallpaper on all hosts
   - Sets wallpaper: **macos-wallpaper** (Darwin) / **swaybg** (Wayland)
   - Writes `~/colors.toml` and hot-patches IDE `settings.json` (Rust, no Python)
   - Publishes desktop-current paths to `/var/lib/dendritic/auth/current.tsv` (Linux)
   - Then reconciles light/dark so layers never desync
4. **Runtime auth / lock**
   - **Linux gtkgreet + gtklock:** same image as the desktop (1:1). Wrappers
     (`gtkgreet-auth` / `gtklock-auth`) read `auth-path` or
     `/var/lib/dendritic/auth/current.tsv` and substitute CSS placeholders.
   - **macOS Idle:** next pack entry ≠ desktop (Index.plist) + `killall WallpaperAgent`
   - CLI: `dendritic-appearance wallpaper auth-path` (desktop current)
   - CLI: `dendritic-appearance wallpaper lock-path` (Linux = auth; macOS = ≠ desktop)
   - Re-apply macOS Idle only: `dendritic-appearance wallpaper lock`
5. **Schedule**
   - launchd agent / systemd user timer at **00:05** local
   - Also runs on HM activation / niri startup

When `dendritic.wallpaper.enable = true`, desktop + auth are managed from the same pack.

## CLI

```bash
dendritic-appearance wallpaper daily     # today's desktop (+ Linux auth 1:1; macOS Idle ≠)
dendritic-appearance wallpaper next      # rotate desktop
dendritic-appearance wallpaper nineish   # named desktop
dendritic-appearance wallpaper auth-path # print desktop image\tblur (gtkgreet/gtklock)
dendritic-appearance wallpaper lock-path # Linux: same as auth-path; macOS: ≠ desktop
dendritic-appearance wallpaper lock      # re-apply macOS Idle only
dendritic-appearance list-wallpapers
dendritic-appearance status
```

See also [appearance.md](./appearance.md) for the light/dark state machine.

## gowall?

**Not required for daily unique themes.** Optional: `dendritic.wallpaper.gowall.enable = true`.

## Web API?

**No.** Pack is pinned in nix (`nixos-artwork` + optional files in `./wallpapers/`). Drop PNGs into `./wallpapers/` to extend it.

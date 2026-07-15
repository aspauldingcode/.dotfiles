# Wallpaper (macOS + Linux)

Unified declarative wallpaper + daily base16 theming across nix-darwin and NixOS.

## How it works

1. **Build-time pack** (`modules/apps/_wallpaper-pack.nix`)
   - Merges local `./wallpapers/` with curated `nixos-artwork` images
   - Normalizes each image to PNG
   - Runs **flavours** to extract dark + light base16 YAML
2. **Stylix** (`themeFromImage`, default on)
   - `stylix.image` + `stylix.base16Scheme` come from `dendritic.wallpaper.selected`
3. **Runtime** (`dendritic-appearance wallpaper …` — pure Rust)
   - Picks wallpaper by day-of-year — same day ⇒ same wallpaper on all hosts
   - Sets wallpaper: **macos-wallpaper** (Darwin) / **swaybg** (Wayland)
   - Writes `~/colors.toml` and hot-patches IDE `settings.json` (Rust, no Python)
   - Then reconciles light/dark so layers never desync
4. **Schedule**
   - launchd agent / systemd user timer at **00:05** local
   - Also runs on HM activation / niri startup

## CLI

```bash
dendritic-appearance wallpaper daily     # today's wallpaper + palette
dendritic-appearance wallpaper next      # rotate
dendritic-appearance wallpaper nineish   # named entry
dendritic-appearance list-wallpapers
dendritic-appearance status
```

See also [appearance.md](./appearance.md) for the light/dark state machine.

## gowall?

**Not required for daily unique themes.** Optional: `dendritic.wallpaper.gowall.enable = true`.

## Web API?

**No.** Pack is pinned in nix (local files + `nixos-artwork`). Drop PNGs into `./wallpapers/` to extend it.

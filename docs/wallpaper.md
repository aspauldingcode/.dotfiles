# Wallpaper daemon (macOS + Linux)

Unified declarative wallpaper + daily base16 theming across nix-darwin and NixOS.

## How it works

1. **Build-time pack** (`modules/apps/_wallpaper-pack.nix`)
   - Merges local `./wallpapers/` with curated `nixos-artwork` images
   - Normalizes each image to PNG
   - Runs **flavours** to extract dark + light base16 YAML (same idea as pywal/wallust)
2. **Stylix** (`themeFromImage`, default on)
   - `stylix.image` + `stylix.base16Scheme` come from `dendritic.wallpaper.selected`
   - Replaces the static gruvbox pair from `theme-selection.nix` for themed packages
3. **Runtime** (`dendritic-wallpaper`)
   - Picks wallpaper by day-of-year (`%j % pack_size`) — same day ⇒ same wallpaper on all hosts
   - Sets wallpaper: **macos-wallpaper** (Darwin) / **swaybg** (Wayland)
   - Writes `~/colors.toml` (neovim watches this) and hot-patches IDE `settings.json`
4. **Schedule**
   - launchd agent / systemd user timer at **00:05** local
   - Also runs on HM activation / niri startup

## CLI

```bash
dendritic-wallpaper apply daily   # today's wallpaper + palette
dendritic-wallpaper apply next    # rotate
dendritic-wallpaper apply nineish # named entry
dendritic-wallpaper list
dendritic-wallpaper status
```

## gowall?

**Not required for daily unique themes.** gowall `convert` tints a wallpaper _toward_ a named theme (opposite direction). We use **flavours** for image → base16.

Optional: `dendritic.wallpaper.gowall.enable = true` installs gowall for manual `gowall effects` / convert.

## Web API?

**No.** A wallpaper-of-the-day HTTP API is impure and non-reproducible. The pack is pinned in nix (local files + `nixos-artwork`). Drop PNGs into `./wallpapers/` to extend it.

## Light vs dark

Same wallpaper image; flavours generates **two** base16 schemes. Variant comes from `dendritic.theme.variant` / `/var/lib/dendritic/appearance-variant` (specialisation sync).

## Options

```nix
dendritic.wallpaper = {
  enable = true;
  selected = "mountain-sunset"; # stylix build-time seed
  themeFromImage = true;        # inject flavours scheme into stylix
  cycle.enable = true;
  effects.enable = false;       # optional vignette
  gowall.enable = false;
};
```

## Daily Stylix without daily rebuild

Full Stylix package rebuilds can't change every midnight without `nh switch`. This stack:

- **Rebuild**: Stylix uses the _selected_ wallpaper's palette
- **Daily**: hot-reload layer (colors.toml + IDE + live wallpaper) tracks the day's image palette

That matches how most rices cycle (wallust/pywal at runtime) while keeping nix declarative for the pack and seed theme.

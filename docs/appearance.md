# Appearance sync (activation-only)

Cross-platform light/dark + wallpaper palette switching without rebuilds.

## Tool: `dendritic-appearance` (Rust)

| Command                                              | Effect                                                                             |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `detect`                                             | Host appearance (`defaults` on macOS, gsettings/state on Linux) — **no osascript** |
| `set light\|dark`                                    | Set host appearance (SkyLight on macOS) + apply matching wallpaper scheme          |
| `toggle`                                             | Flip + apply                                                                       |
| `apply --variant V --wallpaper current\|daily\|NAME` | Hot-reload palette/wallpaper only                                                  |
| `tint`                                               | macOS accent/highlight/selection from `~/colors.toml` `base0D`                     |
| `status --waybar`                                    | Waybar JSON module                                                                 |

## Light vs dark wallpaper

Each pack entry has flavours **dark** and **light** schemes. Toggle uses:

- dark mode → dark scheme + same wallpaper image
- light mode → light scheme + same wallpaper image

## No rebuild path

1. **Hot layer** (always): `colors.toml`, IDE patch, swaybg/macos-wallpaper, macOS tint
2. **Prebuilt activate** (Darwin): `/etc/dendritic-appearance-activate-prebuilt.sh` swaps cached `mba`/`mba-dark` profiles
3. **Specialisation** (NixOS): `switch-to-configuration test` under `specialisation/{light,dark}` when present

Full `nh switch` only needed to refresh prebuild cache after flake changes.

## Waybar

`custom/appearance`: click = toggle, right-click = next wallpaper.

## macOS without AppleScript

- Detect: `defaults read -g AppleInterfaceStyle`
- Set: SkyLight `SLSSetAppearanceThemeLegacy` via `libloading`
- Tint: `defaults write` accent/highlight + killall Dock/Finder/SystemUIServer
- Ghostty: `pkill -USR2`; Spotify: `pkill -x Spotify`

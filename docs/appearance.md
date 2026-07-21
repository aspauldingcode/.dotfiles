# Appearance state machine (activation-only)

Pure-Rust light/dark + wallpaper sync. Host appearance and global theme layers
must never desync.

## Tool: `dendritic-appearance`

| Command                                                        | Effect                                                      |
| -------------------------------------------------------------- | ----------------------------------------------------------- |
| `detect`                                                       | Host appearance (`defaults` / gsettings) — **no osascript** |
| `reconcile` / `sync`                                           | Observe → apply until host == colors == wallpaper variant   |
| `supervise [SECS]`                                             | Daemon: poll + reconcile forever (launchd / systemd)        |
| `set light\|dark`                                              | Force host + global apply                                   |
| `toggle`                                                       | Flip host + global apply                                    |
| `apply [--variant V] [--wallpaper current\|daily\|next\|NAME]` | Hot-reload                                                  |
| `wallpaper <daily\|next\|NAME\|current>`                       | Pack apply in Rust (replaces bash/python)                   |
| `tint`                                                         | macOS accent/highlight from `~/.colors.toml` `base0D`       |
| `status [--waybar]`                                            | Machine status / Waybar JSON                                |
| `list-wallpapers`                                              | Pack entries                                                |

## Invariant

After every reconcile:

`host == recorded == ~/.colors.toml variant == wallpaper.json variant`

Phases: `Synced` → idle; `Desynced` → `Applying` → verify (max 3) → `Synced` or `Failed`.

## Authority

- **macOS**: `AppleInterfaceStyle` / SkyLight (detect + set; no AppleScript)
- **Linux**: dendritic state + gsettings follow

## Services

- **HM launchd agent** `com.aspauldingcode.dendritic-appearance` → `supervise`
- **systemd user** `dendritic-appearance.service` → `supervise`
- **Darwin system watch** (tiny `/etc/dendritic-appearance-watch.sh` shim) → `reconcile` on GlobalPreferences flips
- Legacy bash `dendritic-appearance-sync` launchd daemon is **force-disabled**

## No rebuild path

1. **Hot layer**: `~/.colors.toml`, IDE / tmux / Ghostty live palette, swaybg / macos-wallpaper, macOS tint
2. **Prebuilt activate** (Darwin): cached light/dark profiles from postActivation
3. **Specialisation** (NixOS): when present

## Waybar

`custom/appearance`: click = toggle, right-click = next wallpaper. Desync shows `!`.

# Dendritic menubar (pass-store-tray)

Native menubar applet (macOS NSStatusItem / Linux StatusNotifier). Same binary
and launchd/systemd labels as before (`pass-store-tray`) — pass sync status is
unchanged; dendritic fleet/theme/llm/wg/android/flake status is layered on top.

## Status files

| File                               | Writer                                              |
| ---------------------------------- | --------------------------------------------------- |
| `~/.cache/pass-store-sync.status`  | `pass-store-sync` (existing)                        |
| `~/.cache/dendritic-tray.status`   | `dendritic-tray-collect` / `dendritic tray collect` |
| `~/.cache/android-converge.status` | `android-converge` (OnePlus 6T / nix-android)       |

Tray polls both ~2s. Collect runs when dendritic status is older than ~45s.
Collect also probes `adb` live and merges `android-converge.status` into the
`android` section (device reachability, converge state, lease holder).

Phone rows (only when noisy): `oneplus6t unreachable`, `… error`,
`… converging…`, `… leased by <host>`, `… status stale`.

## Menu

1. Dynamic status rows (omit healthy-ok noise)
2. Open QtPass / Open sync log
3. **Connect device** (submenu)
   - WireGuard for iPhone… — QR + `.conf` under `~/.cache/dendritic-connect-device/`
   - Pass store for iPhone… — guide (QtPass is desktop-only)
   - Setup guide… — full HTML how-to
4. **Sync flake…** — local git sync + flake update + `nh` switch (LLM changelog when Ollama is up)
5. **Switch peer…** — SSH over WireGuard to peer, pull + `nh` switch
6. Quit

See [`connect-device.md`](connect-device.md).

## CLI

```bash
dendritic tray collect
dendritic tray sync
dendritic tray switch-peer
dendritic tray connect-device -- wireguard --device iphone
# or:
dendritic-tray-collect
dendritic-tray-sync
dendritic-tray-switch-peer
dendritic-connect-device guide
```

Logs: `~/.cache/dendritic-tray-sync.log`, `~/.cache/dendritic-connect-device.log`

# Connect a 3rd-party device (iPhone)

The menubar applet exposes **Connect device** for guided setup. There is no
in-menu wizard window — each item opens a guide or generates a WireGuard QR and
updates tray job status + a desktop notification.

## Menubar

| Item                   | What it does                                                                |
| ---------------------- | --------------------------------------------------------------------------- |
| WireGuard for iPhone…  | Enroll `iphone` peer keys in pass, write `.conf` + QR PNG, refresh local WG |
| Pass store for iPhone… | Opens a short guide (QtPass is desktop-only; use Pass for iOS) + QtPass     |
| Setup guide…           | Full HTML how-to for WG + pass + pointer to nix-android                     |

CLI:

```bash
dendritic-connect-device guide
dendritic-connect-device wireguard --device iphone
dendritic-connect-device wireguard --device iphone --rotate
dendritic-connect-device pass-guide
# or:
dendritic tray connect-device -- guide
```

Artifacts land in `~/.cache/dendritic-connect-device/` (`iphone.conf`,
`iphone-wg.png`, HTML guides). Log: `~/.cache/dendritic-connect-device.log`.

## WireGuard client peers

Roster: [`home/wireguard-peers.json`](../home/wireguard-peers.json). Hosts keep
`role: host`; phones/tablets use `role: client` (e.g. `iphone` → `10.87.0.3/24`).

`dendritic-wg-ensure` on mba/sliceanddice adds a `[Peer]` for each client that
already has `WG_PUBLIC_KEY_*` in pass. After the first QR export, run ensure on
the **other** host too (or wait for pass sync + materialize).

See [`wireguard.md`](wireguard.md).

## Pass / QtPass

QtPass stays on mba/sliceanddice (**Open QtPass**). iPhone uses a Pass-compatible
client with the same GPG key + private password-store remote — never commit those
into this flake.

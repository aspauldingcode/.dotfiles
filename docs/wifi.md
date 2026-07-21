# Dendritic Wi-Fi (`dendritic.wifi`)

Declarative known networks with **PSK from pass** (never in the Nix store).
Profiles are ensured on **mba**, **sliceanddice**, and **mba-asahi** after
`pass-materialize` — no `nmtui` required.

Fleet list (SSID / UUID / pass key / priority):
[`home/wifi-networks.json`](../home/wifi-networks.json)

| SSID                    | pass key                     | Priority |
| ----------------------- | ---------------------------- | -------- |
| `Bubbles`               | `Bubbles`                    | 100      |
| `Luke Skydumper`        | `WIFI_Luke_Skydumper`        | 80       |
| `Myanmar-5G`            | `WIFI_Myanmar_5G`            | 80       |
| `Myanmar`               | `WIFI_Myanmar`               | 75       |
| `Everyday Im Buffering` | `WIFI_Everyday_Im_Buffering` | 70       |
| `Sunburst`              | `WIFI_Sunburst`              | 70       |
| `Wifi-From-Heaven`      | `WIFI_Wifi_From_Heaven`      | 70       |
| `Indaba Guest`          | `WIFI_Indaba_Guest`          | 40       |
| `Arctos Coffee`         | `WIFI_Arctos_Coffee`         | 40       |
| `BreakEspresso-5`       | `WIFI_BreakEspresso_5`       | 40       |
| `LadderCoffee_5`        | `WIFI_LadderCoffee_5`        | 40       |
| `Clyde Coffee Guest`    | `WIFI_Clyde_Coffee_Guest`    | 40       |
| `PF Guest WiFi`         | `WIFI_PF_Guest_WiFi`         | 30       |

Security: WPA2-PSK, IPv4/IPv6 DHCP, autoconnect. Eduroam stays in
[`wifi-eduroam.md`](wifi-eduroam.md).

Materialize: `~/.config/dendritic/wifi/<passKey>.psk`

## One-time: import PSKs from macOS Keychain

All listed SSIDs exist in mba `System.keychain`. Export needs an interactive
**Always Allow** click (ACL cannot be automated from this agent):

```bash
# Terminal.app / iTerm — not Cursor sandbox. Click Always Allow per dialog.
nix run .#pass-wifi-bootstrap
# or after HM switch: pass-wifi-bootstrap

pass-materialize
dendritic-wifi-ensure
```

Clipboard fallback for one SSID:

```bash
pass-wifi-bootstrap --ssid "Indaba Guest" --from-clipboard
```

## Module

[`modules/wifi.nix`](../modules/wifi.nix) — `dendritic.wifi.enable = true` on all hosts.

| Platform | How profiles are applied                                  |
| -------- | --------------------------------------------------------- |
| NixOS    | `dendritic-wifi-ensure` → `nmcli` upsert (iwd via NM)     |
| macOS    | `dendritic-wifi-ensure` → `networksetup` preferred + join |

NixOS intentionally does **not** use `ensureProfiles` during `nixos-rebuild`
(that rewrote keyfiles mid-activation and dropped Wi-Fi once).

**Linux secret storage:** profiles must be system connections with
`wifi-sec.psk-flags=0` (NM-owned). `psk-flags=1` (agent-owned) makes nmtui /
GUIs re-prompt and leaves `/var/lib/iwd/*.psk` without a Passphrase — Wi-Fi
then fails after reboot. `dendritic-wifi-ensure` forces flags=0.

**GUI:** waybar network click opens `iwgtk` (has Connect). `nm-connection-editor`
only edits profiles.

Agents: launchd `com.aspauldingcode.wifi-ensure` (macOS), systemd user path/service

- `dendritic-wifi-radio` oneshot (NixOS boot radio on).

## EWU eduroam (802.1X)

Campus Wi‑Fi is a separate module — pass-backed PEAP/MSCHAPv2, not PSK.
See [`docs/wifi-eduroam.md`](wifi-eduroam.md) (`dendritic.eduroam`).

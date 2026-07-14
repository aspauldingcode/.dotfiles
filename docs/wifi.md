# Dendritic Wi-Fi (`dendritic.wifi`)

Declarative known networks with **PSK from pass** (never in the Nix store).

## Live profile we match (Bubbles)

Captured from mba + sliceanddice while connected:

| Setting       | Value                                        |
| ------------- | -------------------------------------------- |
| SSID          | `Bubbles`                                    |
| Security      | WPA2 Personal (`wpa-psk`)                    |
| IPv4 / IPv6   | DHCP / auto (`addr-gen-mode=stable-privacy`) |
| DNS           | From DHCP (no static override)               |
| Autoconnect   | on (priority 100)                            |
| NixOS backend | NetworkManager + **iwd**                     |
| Darwin        | `networksetup` preferred network + join      |

Pass entry: `secretspec/shared/default/Bubbles`  
Materialize: `~/.config/dendritic/wifi/Bubbles.psk`  
NixOS optional root copy: `/var/lib/dendritic/wifi/Bubbles.psk` (0600)

## Module

[`modules/wifi.nix`](../modules/wifi.nix) — defaults `dendritic.wifi.enable = true`.

| Platform | How Bubbles is applied                                    |
| -------- | --------------------------------------------------------- |
| NixOS    | `dendritic-wifi-ensure` → `nmcli` upsert (iwd via NM)     |
| macOS    | `dendritic-wifi-ensure` → `networksetup` preferred + join |

NixOS intentionally does **not** use `ensureProfiles` during `nixos-rebuild`
(that rewrote keyfiles mid-activation and dropped Wi-Fi once). Desired state
(WPA2-PSK, DHCP IPv4/IPv6, autoconnect) is applied after pass materialize.

```bash
# After GPG unlock / pass sync
pass-materialize          # writes Bubbles.psk
dendritic-wifi-ensure     # applies OS profile + connects
```

Agents: launchd `com.dendritic.wifi-ensure` (macOS), systemd user path/service (NixOS).

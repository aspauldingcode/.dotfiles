# Dendritic EWU eduroam (`dendritic.eduroam`)

Zero-interaction **User Mode 802.1X** matching this mba — **not** an EWU
`.mobileconfig`. Same trust model as Bubbles: sops unlocks GPG → pass →
materialize → ensure. No pinentry for Wi‑Fi, no Trust dialog at join time.

## Live profile (mba ground truth)

| Piece       | Value                                                                        |
| ----------- | ---------------------------------------------------------------------------- |
| SSID        | `eduroam`                                                                    |
| Security    | WPA2-Enterprise                                                              |
| Identity    | `aspaulding5@ewu.edu` (from pass)                                            |
| Outer EAP   | PEAP + MSCHAPv2, `anonymous@ewu.edu`                                         |
| RADIUS CN   | `lipfence02v.eastern.ewu.edu`                                                |
| Trust       | InCommon RSA Server CA 2 (+ USERTrust); leaf optional in CA bundle           |
| Darwin      | Keychain service `com.apple.network.eap.user.item.wlan.ssid.eduroam`         |
| Linux/Asahi | `/var/lib/iwd/eduroam.8021x` (keep **iwd**, do not switch to wpa_supplicant) |

## Pass → home files

| SecretSpec key     | Materialize target                              |
| ------------------ | ----------------------------------------------- |
| `EDUROAM_IDENTITY` | `~/.config/dendritic/wifi/eduroam/identity`     |
| `EDUROAM_PASSWORD` | `~/.config/dendritic/wifi/eduroam/password`     |
| `EDUROAM_CA`       | `~/.config/dendritic/wifi/eduroam/ca.pem`       |
| `EDUROAM_PROFILE`  | `~/.config/dendritic/wifi/eduroam/profile.json` |

Never in the Nix store / public git. Missing keys surface as tray
`materialize_warnings` (same path as Bubbles).

## Apply

```bash
pass-materialize                 # writes eduroam/* from pass
dendritic-eduroam-ensure         # Darwin Keychain / Linux iwd + connect
dendritic-eduroam-rotate         # optional: refresh CA from lipfence when online
```

| Platform    | Ensure behavior                                                              |
| ----------- | ---------------------------------------------------------------------------- |
| macOS       | Preferred WPA2E + upsert Keychain 802.1X (`-T eapolclient`) + import CA PEMs |
| NixOS/Asahi | Write `eduroam.8021x` (embedded CA, ServerDomainMask) + `iwctl`/`nmcli`      |

Agents: launchd `com.dendritic.eduroam-ensure` (+ weekly rotate);
systemd user path/service + weekly timer on Linux.

## Rotation

- **Password:** change pass entry → `pass-materialize` → ensure rewrites Keychain / `.8021x`.
- **Trust:** when lipfence leaf/CA rotates, `dendritic-eduroam-rotate` (online)
  refreshes PEMs into pass → peers sync → ensure re-imports / rewrites embed CA.

## Module / hosts

[`modules/wifi-eduroam.nix`](../modules/wifi-eduroam.nix) — defaults
`dendritic.eduroam.enable = true` on mba, sliceanddice, mba-asahi (via dendritic HM).

See also [`docs/wifi.md`](wifi.md) (Bubbles PSK path; untouched by this module).

## Out of scope

- `.mobileconfig` / MDM
- Switching Asahi to `wpa_supplicant` unless PEAP+iwd is proven broken against EWU RADIUS

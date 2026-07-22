# Dendritic WireGuard (mba ↔ sliceanddice + clients)

Private overlay so one host can stay on home **Bubbles** Wi‑Fi while the other
is away — SSH, VNC (mba Screen Sharing), and LAN-style inspection over
`10.87.0.0/24`. Optional **client** peers (iPhone, …) dial a host via the
WireGuard app.

Secrets stay in the private **pass** store (SecretSpec). Endpoints / public IPs
are **never** committed to this flake (same threat model as
[`fleet-status.md`](fleet-status.md)).

## Addresses (non-secret)

| Peer           | Role   | Tunnel address | UDP port | Desktop               |
| -------------- | ------ | -------------- | -------: | --------------------- |
| `mba`          | host   | `10.87.0.1/24` |    51820 | VNC `:5900` (Bonjour) |
| `sliceanddice` | host   | `10.87.0.2/24` |    51820 | —                     |
| `iphone`       | client | `10.87.0.3/24` |        — | —                     |

Declared in [`home/wireguard-peers.json`](../home/wireguard-peers.json). Enroll
the phone from the menubar **Connect device → WireGuard for iPhone…** (see
[`connect-device.md`](connect-device.md)).

## SecretSpec keys (pass)

| Key                                 | Role                                                      |
| ----------------------------------- | --------------------------------------------------------- |
| `WG_PRIVATE_KEY_{MBA,SLICEANDDICE}` | Per-peer private key (not materialized to both hosts)     |
| `WG_PUBLIC_KEY_{MBA,SLICEANDDICE}`  | Public keys → `~/.config/dendritic/wireguard/keys/`       |
| `WG_PSK`                            | Optional pre-shared key                                   |
| `WG_ENDPOINT_{MBA,SLICEANDDICE}`    | Optional `host:port` when that peer is reachable remotely |
| `WG_HOME`                           | Which peer is currently left at home                      |

sops-nix still only unlocks GPG so pass works — WG material is **not** in
`sops.secrets`.

## One-time bootstrap

```bash
nix run .#pass-wg-bootstrap
# peers sync pass via ntfy, then on each host:
pass-materialize
dendritic-wg-ensure          # needs sudo once to install /etc/wireguard/dendritic.conf
```

Rebuild after enabling `dendritic.wireguard` on both hosts:

```bash
# mba
nh darwin switch .
# sliceanddice
nh os switch .
```

## Bubbles (home LAN) vs remote

**Both on Bubbles:** leave `WG_ENDPOINT_*` empty. `dendritic-wg-ensure` resolves
`mba.local` / `sliceanddice.local` and dials LAN UDP/51820.

**One home, one away:** on either host (pass syncs):

```bash
# Example: sliceanddice stays home; put your public/DDNS host in pass (not git)
nix run .#pass-wg-set-home -- --peer sliceanddice --endpoint YOUR.DDNS.EXAMPLE:51820
```

Router: forward **UDP 51820** → home peer’s LAN IP. Traveler pulls pass + runs
`pass-materialize && dendritic-wg-ensure`.

Clear remote mode:

```bash
nix run .#pass-wg-set-home -- --clear
```

## Inspect over the tunnel

```bash
ssh alex@10.87.0.2               # → sliceanddice
ssh 8amps@10.87.0.1              # → mba
open vnc://mba.local             # → mba Screen Sharing (LAN / Bonjour)
open vnc://10.87.0.1             # → mba over WireGuard
ping -c2 10.87.0.2
sudo wg show
```

mba advertises `_rfb._tcp` as **mba** (`dendritic.apps.vnc`). Auth is the
macOS login for `8amps`.

## Rotate pairing tokens

```bash
pass-rotate-cli-auth --wg        # or: pass-wg-rotate
# PSK only:     pass-wg-rotate --psk-only
# Keys only:    pass-wg-rotate --keys-only
```

Both peers must rematerialize + `dendritic-wg-ensure` after a rotate (old keys
die immediately). `--wg` is **not** part of weekly auto-rotate.

## Status

```bash
pass-wg-bootstrap --status
pass-rotate-cli-auth --status    # includes WireGuard section
pass-wg-set-home --status
```

## Layout

| Piece                     | Path                                                                  |
| ------------------------- | --------------------------------------------------------------------- |
| Module                    | [`modules/wireguard.nix`](../modules/wireguard.nix)                   |
| Ensure                    | [`scripts/dendritic-wg-ensure.sh`](../scripts/dendritic-wg-ensure.sh) |
| Bootstrap / rotate / home | `scripts/pass-wg-*.sh`                                                |
| Peers JSON                | [`home/wireguard-peers.json`](../home/wireguard-peers.json)           |

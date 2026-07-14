# Fleet presence (public-safe)

Enrolled hosts phone home to the **private** repo
`aspauldingcode/dendritic-fleet-status`. Public CI rewrites **status badges only**
in the root README (and a machine-readable snapshot in
[`fleet-status.json`](./fleet-status.json)).

The README does **not** embed last-seen clocks or tip tables — those go stale
between commits. Shields badges (`online` / `stale` / `offline`) are the public
signal; CI updates them about every 30 minutes when status changes.

## Threat model

| Public                         | Never public               |
| ------------------------------ | -------------------------- |
| Host id (`mba`, …)             | Public/private IP, CIDR    |
| Platform (in JSON snapshot)    | mDNS / FQDN beyond host id |
| Flake tip short SHA (JSON)     | WiFi SSID / BSSID / geo    |
| `online` / `stale` / `offline` | MAC, home paths            |

“Online” means the host agent can reach GitHub — not LAN reachability.

## Thresholds

| Status      | Meaning                     |
| ----------- | --------------------------- |
| **online**  | Heartbeat within 30 minutes |
| **stale**   | Heartbeat within 24 hours   |
| **offline** | Older or missing            |

## Enrollment

Roster: [`home/fleet-hosts.nix`](../home/fleet-hosts.nix).

Per host (HM):

```nix
dendritic.fleet.enable = true;
dendritic.fleet.hostId = "mba"; # must be a roster key
```

Agent: launchd / systemd timer every 15 minutes → `scripts/fleet-heartbeat.sh`.

Auth: sops `fleet_status_github_token` (write to private fleet repo only) or
existing `gh` auth. Public CI uses Actions secret `FLEET_STATUS_READ_TOKEN`
(read-only on the private repo).

## Rotate token (no host burn)

1. Create a new fine-grained PAT (contents: write on `dendritic-fleet-status` only).
2. `sops set secrets/secrets.yaml '["fleet_status_github_token"]' '"…"'`
3. `gh secret set FLEET_STATUS_READ_TOKEN -R aspauldingcode/.dotfiles` (read-only PAT).
4. Rebuild hosts; revoke the old token.

Do **not** delete host enrollments when rotating credentials.

## Manual refresh

```bash
# On a host
systemctl --user start fleet-heartbeat.service   # Linux
launchctl kickstart -k gui/$(id -u)/com.aspaulding.fleet-heartbeat  # macOS

# Public render (needs read token)
FLEET_STATUS_READ_TOKEN=… ./scripts/fleet-status-render.sh
gh workflow run fleet-status.yml -R aspauldingcode/.dotfiles
```

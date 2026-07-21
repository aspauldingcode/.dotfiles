# nix-android (OnePlus 6T / LineageOS)

Declarative Android apps and reachable device state via
[nix-android](https://github.com/devindudeman/nix-android) — **nix-darwin, but
for your phone**. Converge over authorized `adb` shell; no root, no replacing
the OS, no Nix on the device.

| Piece                             | Path / attr                                                      |
| --------------------------------- | ---------------------------------------------------------------- |
| Device module                     | [`hosts/android/oneplus6t/`](../hosts/android/oneplus6t/)        |
| APK lock                          | `hosts/android/oneplus6t/apps.lock.json`                         |
| Flake wiring                      | [`modules/nix-android.nix`](../modules/nix-android.nix)          |
| Config (Apple Silicon controller) | `.#oneplus6t-darwin`                                             |
| Config (x86_64 Linux controller)  | `.#oneplus6t-linux`                                              |
| CLI                               | `nix run .#android-rebuild -- …`                                 |
| Wireless adb                      | `nix run .#adb-wireless -- …` / `scripts/adb-wireless.sh`        |
| Always-on agent                   | `dendritic.androidConverge` (mba launchd + sliceanddice systemd) |

## Always-on converge agent

Shared Home Manager module [`modules/apps/android-converge.nix`](../modules/apps/android-converge.nix)
installs the same agent on **mba** (launchd) and **sliceanddice** (systemd user
timer). Default interval is 15 minutes; `RunAtLoad` / `OnBootSec` so it is
always on when the host is up.

Each run writes `~/.cache/android-converge.status` (reachable, transport, state,
lease, config tip). Controllers also heartbeat `hosts/oneplus6t.json` into the
private fleet repo when the phone is up — that drives the README
`oneplus6t` shield ([fleet-status.md](./fleet-status.md)). The menubar tray
surfaces the same status via `dendritic-tray-collect`
([dendritic-tray.md](./dendritic-tray.md)).

**No duplicate apply:** before `switch`, the agent writes a short lease on the
phone (`/data/local/tmp/nix-android-<device>.lease`) with `hostId` + expiry.
If the other controller holds a valid lease, this host skips. A local
`~/.cache/android-converge.lock` also prevents overlapping runs on one machine.

```bash
# Logs
tail -f ~/.cache/android-converge.log      # mba
journalctl --user -u android-converge -f # sliceanddice

# Manual kick
launchctl kickstart -k gui/$(id -u)/com.aspauldingcode.android-converge  # mba
systemctl --user start android-converge.service                      # sliceanddice
```

Enabled with `dendritic.androidConverge.enable = true` on both controllers
(`hostId` defaults from `dendritic.fleet.hostId`).

## Support boundary

Upstream’s first-class targets are **stock Pixel** and **GrapheneOS**. Other
AOSP-derived phones (including **LineageOS on OnePlus 6T**) are **best-effort**:
successful `adb` authorization alone is not a support claim. Review every
`plan` before `switch` or `bootstrap`. See upstream
[SUPPORT.md](https://github.com/devindudeman/nix-android/blob/main/docs/SUPPORT.md)
and [LIMITS.md](https://github.com/devindudeman/nix-android/blob/main/docs/LIMITS.md).

Controllers: **Apple Silicon macOS** (`mba`) and **x86_64 Linux**
(`sliceanddice`). Both already have `android-tools` / `adb`.

## Prerequisites

1. USB debugging enabled on the phone (or Wireless debugging — see below); accept
   the RSA prompt once.
2. Confirm the serial (`USB` hardware id, or wireless `IP:PORT`):

   ```bash
   adb devices -l
   # or
   nix run .#adb-wireless -- status
   ```

3. Declared ABI is `arm64-v8a` (OnePlus 6T). The engine refuses a mismatch with
   `ro.product.cpu.abi`.

## Wireless adb

nix-android only needs a working adb serial — wireless works the same as USB.
Two setup paths:

### A. USB once → stay on Wi-Fi (`tcpip`)

Same LAN as the controller. Plug in once:

```bash
nix run .#adb-wireless -- tcpip          # enables adb tcpip 5555, connects
# unplug USB
nix run .#adb-wireless -- status
```

Later reconnects (phone IP may change):

```bash
nix run .#adb-wireless -- connect 192.168.1.40:5555
```

### B. Android 11+ Wireless debugging (no cable)

On the phone: **Settings → System → Developer options → Wireless debugging**
→ enable → **Pair device with pairing code**. Then:

```bash
nix run .#adb-wireless -- pair 192.168.1.40:37123 123456
nix run .#adb-wireless -- connect 192.168.1.40:41259   # IP & port from Wireless debugging
```

LineageOS exposes this when based on Android 11+. Older builds use path A.

### Use with android-rebuild

```bash
SERIAL=$(nix run .#adb-wireless -- serial)
nix run .#android-rebuild -- plan --flake .#oneplus6t-darwin --serial "$SERIAL"
```

`adb-wireless` remembers the last `HOST:PORT` under
`~/.local/state/adb-wireless/last-endpoint` so bare `connect` works next time.

## Daily workflow

From the repo root. On **mba** use `oneplus6t-darwin`; on **sliceanddice** use
`oneplus6t-linux`.

```bash
# After editing apps.* in hosts/android/oneplus6t/default.nix — refresh pins
nix run .#android-rebuild -- update --flake .#oneplus6t-darwin \
  --lock hosts/android/oneplus6t/apps.lock.json
git add hosts/android/oneplus6t/apps.lock.json

# Read-only plan (may fetch/build APKs on the controller)
nix run .#android-rebuild -- plan --flake .#oneplus6t-darwin --serial SERIAL

# Apply only after reviewing the plan
nix run .#android-rebuild -- switch --flake .#oneplus6t-darwin --serial SERIAL

# Drift since last successful switch
nix run .#android-rebuild -- status --flake .#oneplus6t-darwin --serial SERIAL
```

Play / attended apps need human consent:

```bash
nix run .#android-rebuild -- assist --watch --flake .#oneplus6t-darwin --serial SERIAL
```

Wiped-device resumable path (review plan first):

```bash
nix run .#android-rebuild -- bootstrap --flake .#oneplus6t-darwin --serial SERIAL
```

## Seed from a live phone

To draft a fuller config from what is already installed:

```bash
nix run .#android-rebuild -- import --serial SERIAL
```

Paste the generated module into `hosts/android/oneplus6t/default.nix`, then
`update` → `plan` → `switch`.

## Defaults in this repo

- **Cleanup on** (`apps.cleanup = "uninstall"`) — undeclared third-party owner
  apps are removed after a successful apply. System packages are never cleanup
  candidates; disable those with `android.packages.disabled`.
- Keepers today: F-Droid + Termux (managed) and **Wawona**
  (`com.aspauldingcode.wawona` under `apps.attended`). Add anything else you
  want to keep under `apps.play` / `apps.attended` / `apps.fdroid` /
  `apps.release` **before** the next `switch`, or it will be uninstalled.
- Dark mode + opportunistic Private DNS; Termux notification permission and
  background/battery exemptions.

Full option surface: upstream
[USING.md](https://github.com/devindudeman/nix-android/blob/main/docs/USING.md)
and [OPTIONS.md](https://github.com/devindudeman/nix-android/blob/main/docs/OPTIONS.md).

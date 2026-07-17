# Windows 11 IoT Enterprise LTSC dual-boot (sliceanddice)

NixOS remains the default OS. Windows is a peer boot entry for firmware tooling
(e.g. keyboard EC dumps). Edition is **Windows 11 IoT Enterprise LTSC 2024**
(no Store / consumer inbox apps — the “bloatless enterprise” SKU).

## Layout (disko / dendritic-reinstall)

See [`hosts/nixos/sliceanddice/disko.nix`](../hosts/nixos/sliceanddice/disko.nix).

**Physical order on disk:**

| PARTLABEL  | Size  | Role                                                                |
| ---------- | ----- | ------------------------------------------------------------------- |
| ESP        | 512M  | Shared `/boot` (systemd-boot + Windows Boot Manager)                |
| nixos      | rest  | btrfs (`@` `@nix` `@home` `@log`)                                   |
| windows    | 64G   | NTFS → `/mnt/windows` (rw, `nofail`)                                |
| wininstall | 8G    | Extracted Setup media → `/mnt/wininstall` (`nofail`, ro after prep) |
| swap       | ~4–9G | hibernate / swap                                                    |
| nixinstall | 8G    | On-disk NixOS installer (end of disk; never wiped)                  |

**Install target:** Windows Setup / diskpart use **LBA order**, not GPT index.
Physical ESP→nixos→windows→… means Autounattend `InstallTo` is usually
**PartitionID 3** (`PARTLABEL=windows`). Bootstrap stamps the live LBA index into
`Autounattend.xml` (do not hard-code GPT numbers — Setup may also create MSR).

`nh os switch` never repartitions or reinstalls Windows. Markers under
`/var/lib/dendritic-windows/`:

- `media-ready` — Setup media extracted (skip re-extract)
- `installed` — Windows finished; bootstrap is a permanent no-op

## First-time bootstrap (no USB)

Prerequisites (already true on current sliceanddice carve):

1. Secure Boot **off**
2. AC power
3. `PARTLABEL=windows` + `PARTLABEL=wininstall` present (from `dendritic-reinstall`)
4. ≳8 GiB free on `/var/cache` for the ISO download

With `dendritic.windows.enable = true` and `autoBootstrap = true`:

1. Timer starts ~90s after boot and runs `dendritic-windows-bootstrap.service`
2. Downloads IoT LTSC 2024 x64 eval ISO (fwlink → CDN), SHA256
   `67cec5865eaa037a72ddc633a717a10a2bed50778862267223ddb9c60ef5da68`
3. Extracts ISO → wininstall, writes `Autounattend.xml` (InstallTo LBA index of **windows**)
4. Deletes ISO cache (media lives on wininstall)
5. `efibootmgr --bootnext` → `Windows Setup (dendritic)`
6. Reboots (`autoReboot`); silent Setup installs onto **windows**
7. Setup’s downlevel phase reboots into **Windows Boot Manager** for specialize /
   OOBE / FirstLogon. If systemd-boot wins that reboot, `continue-setup` BootNexts
   WBM once more.
8. FirstLogon writes `C:\dendritic-windows-ready` and reboots to NixOS
9. `dendritic-windows-finalize` clears BootNext, keeps systemd-boot first, writes
   **installed**

Manual kick:

```bash
sudo systemctl start dendritic-windows-bootstrap.service
```

`dendritic.windows.autoReboot = false` — prepare media only; reboot yourself.

## Computer name

Autounattend sets `ComputerName` to **`sliceanddice`** (≤15 NetBIOS chars).
Longer names (e.g. `sliceanddice-win`) make specialize fail with `0x80220005` /
`0x8007001F`.

## Shared login (NixOS + Windows)

Password lives in the **private pass store** only
(`secretspec/shared/default/LOGIN_PASSWORD`). It is never in sops or the flake.
`pass-materialize` writes `~/.config/dendritic/identity/login.password` (0600);
systemd applies it to NixOS and stages Windows sync from that file.

| Side               | Mechanism                                                |
| ------------------ | -------------------------------------------------------- |
| pass               | `LOGIN_PASSWORD` (SecretSpec / pass)                     |
| Materialize        | `~/.config/dendritic/identity/login.password`            |
| NixOS              | `dendritic-identity-apply-nixos-password` → `chpasswd`   |
| Windows (install)  | Autounattend stamps the same password + username         |
| Windows (existing) | `dendritic-windows-sync-login` → Startup `net user` once |

Change the shared password:

```bash
./scripts/dendritic-identity-set-password.sh          # prompts (hidden)
# or pipe stdin — do not put the value in shell history / scripts in git
pass-materialize   # if units did not pick up the file yet
# boot Windows once so sync-login applies
```

Fallback (identity off): `/var/lib/dendritic-windows/password`, or
`dendritic.windows.passwordFile`.

## Declarative drivers (Sword 15)

`dendritic.windows.drivers.enable` builds a pinned INF tree and stages it to
**both**:

- `C:\dendritic-drivers\` (current install) + Startup `pnputil` once
- `X:\dendritic-drivers\` on wininstall + Autounattend FirstLogon `pnputil`

Pinned on sliceanddice:

- NVIDIA notebook 572.60 (RTX 3050 Ti / GA107)
- SteelSeries Engine 3.19.2 (keyboard backlight — `ssps2.inf` / `ACPI\\MSI0007` + silent `/S` install)

Linux keyboard backlight RE (no EC writes): [`docs/re/sword-kbd-bl/`](re/sword-kbd-bl/).
Capture kit stages to `C:\dendritic\re\` when `dendritic.swordKbdBl.enable` is on.

Drop additional Intel Wi‑Fi / chipset INF zips under
`/var/cache/dendritic-windows/drivers-extra/` when needed.

## Idempotency / force

- `installed` or existing `ntoskrnl.exe` → skip forever
- `media-ready` without Windows → refresh BootNext only (no re-download / no auto-reboot)
- `dendritic.windows.forceRedeploy = true` re-extracts / re-runs Setup (destructive)

## Writing from Linux

`/mnt/windows` is ntfs3 rw after a clean Windows shutdown (Fast Startup off in unattend).

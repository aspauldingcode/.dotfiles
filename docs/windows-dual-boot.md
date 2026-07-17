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
7. FirstLogon writes `C:\dendritic-windows-ready` and reboots to NixOS
8. `dendritic-windows-finalize` clears BootNext, keeps systemd-boot first, writes
   **installed**

Manual kick:

```bash
sudo systemctl start dendritic-windows-bootstrap.service
```

`dendritic.windows.autoReboot = false` — prepare media only; reboot yourself.

## Password

Default: `/var/lib/dendritic-windows/password` (mode 0600).
Override: `dendritic.windows.passwordFile`.

## Idempotency / force

- `installed` or existing `ntoskrnl.exe` → skip forever
- `media-ready` without Windows → refresh BootNext only (no re-download / no auto-reboot)
- `dendritic.windows.forceRedeploy = true` re-extracts / re-runs Setup (destructive)

## Writing from Linux

`/mnt/windows` is ntfs3 rw after a clean Windows shutdown (Fast Startup off in unattend).

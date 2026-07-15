# Windows 11 IoT Enterprise LTSC dual-boot (sliceanddice)

NixOS remains the default OS. Windows is a peer boot entry for firmware tooling
(e.g. keyboard EC dumps). Edition is **Windows 11 IoT Enterprise LTSC 2024**
(no Store / consumer inbox apps).

## Layout (disko)

See [`hosts/nixos/sliceanddice/disko.nix`](../hosts/nixos/sliceanddice/disko.nix):

- ESP 512M shared (`/boot`) — systemd-boot generations + Windows Boot Manager
- NixOS root (shrunk)
- 64G NTFS `PARTLABEL=windows` → `/mnt/windows` (rw from Linux, `nofail`)
- 8G NTFS `PARTLABEL=wininstall` → `/mnt/wininstall` (extracted Setup media, stays)
- ~9G swap (same UUID across recreate)

No USB / optical media. Bootstrap extracts the ISO onto **wininstall** and boots
that partition once via EFI BootNext.

`nh os switch` never repartitions or reinstalls Windows. Markers:

- `/var/lib/dendritic-windows/media-ready` — Setup media extracted (skip re-extract)
- `/var/lib/dendritic-windows/installed` — Windows finished; bootstrap is a permanent no-op

## First-time bootstrap (fully automatic, no GUI, no external media)

With `dendritic.windows.enable = true` and `autoBootstrap = true` (sliceanddice
defaults):

1. Secure Boot stays **off**.
2. Plug in **AC power**; keep ≳20 GiB free on `/` after carving 64+8+9 GiB.
3. Timer starts ~90s after boot and:
   - downloads the IoT LTSC 2024 x64 eval ISO (fwlink → CDN),
   - verifies SHA256 `67cec5865eaa037a72ddc633a717a10a2bed50778862267223ddb9c60ef5da68`,
   - shrinks root; creates windows + wininstall + swap,
   - extracts ISO → wininstall, writes `Autounattend.xml` (InstallTo partition 3),
   - deletes the ISO cache (media lives on wininstall),
   - `efibootmgr --bootnext` → `Windows Setup (dendritic)` on wininstall,
   - reboots (`autoReboot`).
4. Silent Setup installs onto **windows**; FirstLogon writes
   `C:\dendritic-windows-ready` and reboots to NixOS.
5. `dendritic-windows-finalize` clears BootNext, keeps systemd-boot first, writes
   **installed**. wininstall stays for repair; bootstrap never runs again.

Manual kick:

```bash
sudo systemctl start dendritic-windows-bootstrap.service
```

`dendritic.windows.autoReboot = false` — reboot yourself after media prep.

## Password

Default: `/var/lib/dendritic-windows/password` (mode 0600).
Override: `dendritic.windows.passwordFile`.

## Idempotency / force

- `installed` or existing `ntoskrnl.exe` → skip forever.
- `media-ready` without Windows → refresh BootNext only (no re-download).
- `dendritic.windows.forceRedeploy = true` re-extracts / re-runs Setup (destructive).

## Writing from Linux

`/mnt/windows` is ntfs3 rw after a clean Windows shutdown (Fast Startup off).

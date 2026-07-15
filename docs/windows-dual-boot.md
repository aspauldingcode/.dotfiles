# Windows 11 IoT Enterprise LTSC dual-boot (sliceanddice)

NixOS remains the default OS. Windows is a peer boot entry for firmware tooling
(e.g. keyboard EC dumps). Edition is **Windows 11 IoT Enterprise LTSC 2024**
(no Store / consumer inbox apps).

## Layout (disko)

See [`hosts/nixos/sliceanddice/disko.nix`](../hosts/nixos/sliceanddice/disko.nix):

- ESP 512M shared (`/boot`) — systemd-boot generations + Windows Boot Manager
- NixOS root (shrunk)
- 64G NTFS `PARTLABEL=windows` → `/mnt/windows` (rw from Linux, `nofail`)
- ~9G swap (same UUID across recreate)

`nh os switch` never repartitions or reinstalls Windows. Install is a oneshot
gated by `/var/lib/dendritic-windows/installed`.

## First-time bootstrap (fully automatic, no GUI)

Install is **silent end-to-end**: Linux applies the WIM with `wimlib` (no Windows
Setup), injects Panther `unattend.xml` (`WillShowUI=Never`, `SkipMachineOOBE`,
`SkipUserOOBE`, AcceptEula, local `alex`, no MSA), then one-shots specialize via
EFI **BootNext** (BootOrder stays systemd-boot-first).

With `dendritic.windows.enable = true` and `autoBootstrap = true` (sliceanddice
defaults):

1. Secure Boot stays **off** (already off on this host).
2. Plug in **AC power**; keep ≳20 GiB free on `/` after carving 64+9 GiB.
3. `nh os switch` — a **timer** (`dendritic-windows-bootstrap.timer`) starts ~90s
   after boot and:
   - downloads the IoT LTSC 2024 x64 eval ISO from Microsoft
     (`https://go.microsoft.com/fwlink/?linkid=2289029` → PRSS CDN),
   - verifies SHA256 `8abf91c9cd408368dc73aab3425d5e3c02dae74900742072eb5c750fc637c195`,
   - shrinks root, creates NTFS + swap, `wimlib` apply, injects unattend,
   - installs Windows Boot Manager on the shared ESP,
   - sets `efibootmgr --bootnext` to Windows and **reboots** (`autoReboot`).
4. Windows boots once for unattended specialize (progress splash only — no OOBE
   prompts). FirstLogon writes `C:\dendritic-windows-ready` and reboots.
5. Next boot is NixOS. `dendritic-windows-finalize` clears BootNext and keeps
   **systemd-boot first**. Menu still lists NixOS generations + Windows.

Manual kick (optional):

```bash
sudo systemctl start dendritic-windows-bootstrap.service
```

Set `dendritic.windows.autoReboot = false` if you want to reboot yourself after
the unit finishes (`journalctl -u dendritic-windows-bootstrap -f`).

ISO cache path: `/var/cache/dendritic-windows/<isoName>`.

## Password

Default: auto-generated at `/var/lib/dendritic-windows/password` (mode 0600).
Override with `dendritic.windows.passwordFile`.

## Idempotency / force

- Marker `/var/lib/dendritic-windows/installed` or existing `ntoskrnl.exe` → skip.
- `dendritic.windows.forceRedeploy = true` re-applies (destructive).

## Writing from Linux

`/mnt/windows` is ntfs3 rw. Only mount after a clean Windows shutdown
(Fast Startup disabled by unattend).

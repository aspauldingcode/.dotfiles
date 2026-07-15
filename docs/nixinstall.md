# On-disk NixOS installer (sliceanddice)

No USB. A persistent **`nixinstall`** partition holds `sliceanddice-installer`
and a **vault** (SSH, GnuPG, `pass`). systemd-boot entry **NixOS Installer
(dendritic)** boots it. From there, `dendritic-reinstall` runs disko +
`nixos-install` to wipe/reformat main `nixos` as btrfs.

## Layout

See [`hosts/nixos/sliceanddice/disko.nix`](../hosts/nixos/sliceanddice/disko.nix):

| Part | Label | Role |
|------|--------|------|
| 1 | ESP | systemd-boot (shared) |
| 2 | nixos | Main OS (btrfs `@` `@nix` `@home` `@log`) — wipeable |
| 3 | nixinstall | Installer root + `/vault` — **never wipe** |
| 4 | windows | Windows NTFS |
| 5 | wininstall | Windows Setup media |
| 6 | swap | Stable UUID |

## First-time (current ext4 machine)

1. `nh os switch` with `dendritic.nixinstall.enable = true` — timer creates
   nixinstall in free space (~8G ex-swap), installs installer, writes boot entry.
2. `sudo dendritic-vault-sync` — copy `~/.ssh`, `~/.gnupg`, `~/.password-store`
   to `/mnt/nixinstall/vault`.
3. Reboot → pick **NixOS Installer (dendritic)**.
4. `sudo dendritic-reinstall` (or SSH in with Cursor) — disko formats `nixos` as
   btrfs, installs `#sliceanddice`, restores vault.
5. Reboot into main OS. Set `dendritic.disk.liveExt4Compat = false` and switch.
6. Enable `dendritic.windows.autoBootstrap = true` when ready for Windows media.

## Commands

```bash
dendritic-vault-sync              # main OS → vault
dendritic-vault-restore /mnt      # after nixos-install
dendritic-reinstall               # installer only; destroys nixos partition
```

## Safety

- Installer root is `PARTLABEL=nixinstall`; disko must not format it.
- Vault is not in git — partition-local only.
- `liveExt4Compat = true` keeps `/` on the old ext4 UUID until step 5.

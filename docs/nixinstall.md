# On-disk NixOS installer (sliceanddice)

No USB. A persistent **`nixinstall`** partition holds `sliceanddice-installer`
and a **vault** (SSH, GnuPG, `pass`). systemd-boot entry **NixOS Installer
(dendritic)** boots it. From there, `dendritic-reinstall` runs disko +
`nixos-install` to wipe/reformat main `nixos` as btrfs.

## Layout

See [`hosts/nixos/sliceanddice/disko.nix`](../hosts/nixos/sliceanddice/disko.nix):

| Part | Label      | Role                                                 |
| ---- | ---------- | ---------------------------------------------------- |
| 1    | ESP        | systemd-boot (shared)                                |
| 2    | nixos      | Main OS (btrfs `@` `@nix` `@home` `@log`) — wipeable |
| 3    | nixinstall | Installer root + `/vault` — **never wipe**           |
| 4    | windows    | Windows NTFS                                         |
| 5    | wininstall | Windows Setup media                                  |
| 6    | swap       | Stable UUID                                          |

## First-time (current ext4 machine)

1. `nh os switch` with `dendritic.nixinstall.enable = true` — timer creates
   nixinstall in free space (~8G ex-swap), installs installer, writes boot entry.
2. `sudo dendritic-vault-sync` — copy `~/.ssh`, `~/.gnupg`, `~/.password-store`
   to `/mnt/nixinstall/vault`.
3. Reboot → pick **NixOS Installer (dendritic)**.
4. `sudo dendritic-reinstall` (or SSH in with Cursor) — shrinks/reformats `nixos`
   as btrfs, carves windows/wininstall/swap **without wiping nixinstall**,
   installs `#sliceanddice`, restores vault. Requires
   `dendritic.disk.liveExt4Compat = false` in the flake being installed.
5. Reboot into main OS (btrfs). Enable `dendritic.windows.autoBootstrap = true`
   when ready for Windows media.

**Do not** run stock `disko --mode destroy` while booted from nixinstall — that
clears the GPT and would destroy the live installer + vault.

## Network + SSH (installer)

Installer uses **NetworkManager + iwd** (same as main OS). After
`dendritic-vault-sync` on the main OS, `/vault/wifi/*.psk` + `networks.json`
autoconnect via `dendritic-installer-wifi` (Bubbles preferred).

**SSH** is on by default (`services.openssh`, port 22):
- Pubkeys from [`home/ssh-keys.nix`](../home/ssh-keys.nix) for `alex` and `root`
- Extra keys from `/vault/ssh/authorized_keys` + `/vault/ssh/id_ed25519.pub`
- Password auth off — sync the vault before relying on remote Cursor

```bash
ssh alex@sliceanddice-installer.local   # or the LAN IP from the console
sudo dendritic-reinstall
```

Fallback on the installer console: `nmtui` (or `nmcli device wifi connect …`).

`dendritic-reinstall` does **not** need GitHub for disko (local carve + mkfs),
but `nixos-install` still wants cache/network for substitutes.

## Safety

- Installer root is `PARTLABEL=nixinstall`; disko must not format it.
- Vault is not in git — partition-local only.
- `liveExt4Compat = true` keeps `/` on the old ext4 UUID until step 5.

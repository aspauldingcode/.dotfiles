# Emergency Recovery Guide for sliceanddice

## Problem Analysis

Your sliceanddice NixOS system is in emergency mode. Based on the repository analysis:

### Most Likely Causes:

1. **Missing disko.nix import**: If you pulled/applied configuration from the `development` branch (commit `ba8fb7cb` or later), it references `./disko.nix` which doesn't exist on `master` branch.

2. **Filesystem mounting failure**: The recent changes included:
   - New disko partitioning scheme (btrfs subvolumes)
   - Modified filesystem UUIDs and mount options
   - New swap configuration

3. **Boot generation limit**: Commit `963b83f1` capped systemd-boot generations to 5 to prevent `/boot` from filling (511M EFI partition).

## Immediate Recovery Steps

### Option 1: Boot into a previous generation (RECOMMENDED FIRST STEP)

1. At boot, when you see the systemd-boot menu, press `Space` or `Esc` immediately
2. Select an older NixOS generation from before your recent changes
3. Press `Enter` to boot
4. Once booted, you can investigate what went wrong

### Option 2: Emergency mode recovery

If you're already in emergency mode:

```bash
# 1. Check which filesystems are mounted
mount | grep -E "/(boot|nix|home)"

# 2. Check for filesystem errors
journalctl -xb | grep -i "failed\|error\|emergency"

# 3. Check if /boot is full
df -h /boot

# 4. Check filesystem mounts status
systemctl list-units --type=mount --failed

# 5. Try to mount root as read-write if needed
mount -o remount,rw /
```

### Option 3: Rollback to stable master branch configuration

If you're using `/etc/nixos/.dotfiles`:

```bash
# In emergency mode or from an older generation:
cd /etc/nixos/.dotfiles

# Check current branch and status
git branch
git status

# If you're on development branch, switch to master
git checkout master
git pull origin master

# Rebuild with stable config
nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice
```

## Known Issues from Recent Commits

### Issue 1: disko.nix import on master branch
- **Commit**: `ba8fb7cb` (on development branch only)
- **Problem**: Imports `./disko.nix` which doesn't exist on master
- **Solution**: Ensure you're using master branch, or cherry-pick disko.nix from development

### Issue 2: Boot partition space
- **Commit**: `963b83f1`
- **Problem**: 511M EFI partition fills with initrds (~50MB each)
- **Solution**: Already fixed with `boot.loader.systemd-boot.configurationLimit = 5`
- **Check**: Run `df -h /boot` to verify space

### Issue 3: Filesystem UUID changes
- **Location**: `hosts/nixos/sliceanddice/hardware-configuration.nix`
- **Current UUIDs**:
  - Root: `b89f5dca-4b37-4062-bf1d-9e4ebfd61916` (ext4)
  - Boot: `8824-4C5F` (vfat)
  - Swap: `c570ec29-6025-456b-99d1-8f16b677835a`

## Verification Commands

Once you can boot normally, verify the configuration:

```bash
# Check current branch
cd /etc/nixos/.dotfiles && git branch

# Verify filesystem mounts
findmnt / /boot /home /nix

# Check boot partition space
df -h /boot
du -sh /boot/loader/entries/*

# List available boot generations
ls -lh /boot/loader/entries/

# Check system status
systemctl status
journalctl -p err -b
```

## Prevention

1. **Always test major changes**: Use `nixos-rebuild test` before `switch`
2. **Keep old generations**: The configurationLimit=5 is set, but you can temporarily increase it
3. **Monitor /boot space**: Run `df -h /boot` before rebuilds
4. **Stick to one branch**: Use either `master` or `development`, not a mix

## Contact Information

If you need to restore from scratch:
- Bootstrap script: `scripts/install-sliceanddice.sh`
- Secrets: `secrets/sliceanddice-secrets.yaml` (encrypted with sops)
- Hardware config: `hosts/nixos/sliceanddice/hardware-configuration.nix`

## Architecture Notes

- Laptop: MSI with Intel Tiger Lake UHD + NVIDIA RTX 3050 Ti Mobile
- Storage: Samsung 870 EVO 500GB (`ata-Samsung_SSD_870_EVO_500GB_S62ANJ0R238724D`)
- Graphics: Hybrid PRIME render offload (Intel for display, NVIDIA on-demand)
- Kernel: Latest mainline (`pkgs.linuxPackages_latest`)

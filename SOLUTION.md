# Solution for sliceanddice Emergency Mode

## Problem Summary

Your sliceanddice NixOS system entered emergency mode. Analysis of the git repository reveals:

### Root Cause

The `development` branch (ahead of `master`) includes these changes to sliceanddice:
- **NEW**: `disko.nix` - disk/filesystem configuration 
- **NEW**: `kbd-bl-ask.nix` - keyboard backlight config
- **NEW**: `msi-ec-sword-kbd-disable.patch` - MSI EC kernel patch
- **MODIFIED**: `default.nix` - imports disko.nix, adds power management, nixinstall features
- **MODIFIED**: `hardware-configuration.nix` - updated for new partition layout

**If you pulled/applied configuration from `development` to your machine but the files are missing, the system can't boot.**

## Immediate Recovery (Choose One)

### Recovery Option A: Boot Previous Generation (FASTEST)

1. **Reboot** the machine
2. At the **systemd-boot menu**, press `Space` or `Esc`
3. **Select an older generation** from before your changes
4. Boot into that generation
5. Then either:
   - Stay on that generation (it works), OR
   - Fix the configuration and rebuild

### Recovery Option B: Fix Configuration in Emergency Mode

If you're already in emergency mode shell:

```bash
# 1. Remount root as read-write
mount -o remount,rw /

# 2. Navigate to dotfiles
cd /etc/nixos/.dotfiles

# 3. Check current state
git status
git branch

# 4. Switch to stable master branch
git fetch origin
git checkout master
git reset --hard origin/master

# 5. Rebuild from stable config
nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice

# 6. Reboot
reboot
```

### Recovery Option C: Use Rescue Media

If the above don't work:

1. Boot from NixOS install media or the nixinstall partition
2. Mount your root filesystem:
   ```bash
   mount /dev/disk/by-uuid/b89f5dca-4b37-4062-bf1d-9e4ebfd61916 /mnt
   mount /dev/disk/by-uuid/8824-4C5F /mnt/boot
   ```
3. Chroot and fix:
   ```bash
   nixos-enter --root /mnt
   cd /etc/nixos/.dotfiles
   git checkout master
   nixos-rebuild switch --flake .#sliceanddice
   exit
   reboot
   ```

## Long-term Solution: Sync Repository

To prevent this in the future, you need to decide:

### Option 1: Stay on Master (Stable)

Keep using the `master` branch - it's tested and working.

```bash
cd /etc/nixos/.dotfiles
git checkout master
git pull origin master
nixos-rebuild switch --flake .#sliceanddice
```

### Option 2: Move to Development (New Features)

If you want the new features (power management, disko, nixinstall), merge development to master:

**This should be done in this repository first, then pulled to sliceanddice.**

The development branch adds:
- ✨ Disk management with disko (btrfs subvolumes)
- ✨ Power management (RAPL/EPP, zswap, lid/suspend)
- ✨ On-disk NixOS installer
- ✨ Windows dual-boot support
- ✨ Boot generation limiting (prevents /boot from filling)
- ✨ Keyboard backlight controls

## Technical Details

### Current Master Branch
- Root: ext4 (`/dev/disk/by-uuid/b89f5dca-4b37-4062-bf1d-9e4ebfd61916`)
- No disko.nix
- No boot generation limit
- Basic hardware config

### Development Branch Changes
- Root: Can be btrfs with subvolumes (after reinstall via nixinstall)
- Managed by disko.nix
- Boot generations limited to 5
- Power management enabled
- Enhanced hardware support (MSI laptop features)

### Why Emergency Mode Happened

Most likely scenario:
1. You ran `nixos-rebuild switch` with development branch config
2. The config imports `./disko.nix`
3. File doesn't exist (not pulled or wrong branch)
4. NixOS build/activation fails
5. System can't complete boot → emergency mode

Alternative scenarios:
- /boot partition full (unlikely with the 5-generation limit)
- Filesystem mount failure
- Hardware configuration mismatch

## Files Provided for Recovery

1. **EMERGENCY_RECOVERY.md** - Detailed recovery steps
2. **diagnose-emergency.sh** - Diagnostic script to run in emergency mode
3. **SOLUTION.md** - This file

## Next Steps

1. **First**: Boot into a previous generation (Recovery Option A)
2. **Then**: Decide if you want to stay on master or move to development
3. **If development**: Properly merge the branches in this repository
4. **Finally**: Pull the correct branch to sliceanddice and rebuild

## Questions?

Check these files for your current configuration:
- Hardware UUIDs: `hosts/nixos/sliceanddice/hardware-configuration.nix`
- Main config: `hosts/nixos/sliceanddice/default.nix`
- Boot config: In default.nix, look for `boot.loader.*`
- Filesystems: In hardware-configuration.nix or disko.nix (if present)

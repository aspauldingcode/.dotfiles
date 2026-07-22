# Quick Recovery Guide - sliceanddice Emergency Mode

## Fastest Solution (Do This First!)

### Step 1: Boot Previous Generation

1. **Reboot** your sliceanddice machine
2. When you see the boot menu, press **Space** or **Esc** 
3. **Select an older NixOS generation** (one from before the issue)
4. Press Enter to boot

That's it! You should now be back in a working system.

---

## Step 2: Prevent It From Happening Again

Once you're booted into the working generation:

```bash
# Go to your dotfiles
cd /etc/nixos/.dotfiles

# Check which branch you're on
git branch
# If you see "development", that's likely the issue

# Switch to stable master branch
git checkout master
git pull origin master

# Make this the current system
sudo nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice

# Reboot to test
sudo reboot
```

---

## What Happened?

The `development` branch has new features but requires additional files:
- `disko.nix` - disk configuration
- `kbd-bl-ask.nix` - keyboard backlight
- MSI-specific kernel patches
- Power management features

If you rebuilt with the development branch but those files weren't present, NixOS couldn't complete the build and entered emergency mode.

---

## Alternative: Fix in Emergency Mode

If you can't access the boot menu:

```bash
# You should be at an emergency shell prompt
# Remount root as writable
mount -o remount,rw /

# Fix the configuration
cd /etc/nixos/.dotfiles
git checkout master
git reset --hard origin/master

# Rebuild
nixos-rebuild switch --flake .#sliceanddice

# Reboot
reboot
```

---

## Need More Help?

See the detailed guides:
- **SOLUTION.md** - Full explanation and multiple recovery options
- **EMERGENCY_RECOVERY.md** - Detailed technical recovery procedures  
- **diagnose-emergency.sh** - Run this script to diagnose the issue

Or run the diagnostic script:
```bash
bash diagnose-emergency.sh
```

---

## Summary

**Problem**: Configuration mismatch between branches  
**Solution**: Boot previous generation, switch to master branch  
**Prevention**: Stick to one branch (master is stable)

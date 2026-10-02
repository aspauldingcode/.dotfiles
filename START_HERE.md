# 🚨 START HERE - sliceanddice Emergency Recovery

**YOUR SYSTEM**: sliceanddice (NixOS laptop)  
**STATUS**: Emergency mode  
**URGENCY**: Medium (system is recoverable, data is safe)  
**SOLUTION TIME**: 1-10 minutes depending on method

---

## What You Need to Do RIGHT NOW

### The 1-Minute Fix (DO THIS FIRST!)

1. **Reboot** your sliceanddice laptop
2. You'll see a boot menu with several options
3. Press **`Space`** or **`Esc`** key
4. Use arrow keys to select an **older entry** (one from before the issue)
5. Press **`Enter`** to boot

**That's it!** Your system should boot normally now.

---

## Understanding What Happened

### The Problem
Your NixOS configuration repository has two branches:
- **`master`** - Stable, working configuration ✅
- **`development`** - New features, requires extra files ⚠️

You recently made changes that may have mixed these branches, causing the system to look for files that don't exist, which triggered emergency mode.

### The Branches

**Master Branch (current):**
- Simple, stable configuration
- ext4 filesystem
- Works out of the box

**Development Branch (ahead):**
- Adds `disko.nix` for disk management
- Adds `kbd-bl-ask.nix` for keyboard backlight
- Adds power management features
- Adds on-disk installer
- **Requires** all these files to exist

---

## After You've Booted Successfully

Once you're back in a working system, **prevent it from happening again**:

```bash
# Open a terminal
cd /etc/nixos/.dotfiles

# Check which branch you're on
git branch
# If it shows: * development (or anything other than master)

# Switch to stable master
git checkout master
git pull origin master

# Make this the active configuration
sudo nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice

# Verify it worked
sudo reboot
```

---

## Alternative: Use the Automatic Fix Script

If you're comfortable with automation:

```bash
cd /etc/nixos/.dotfiles
sudo bash fix-emergency-auto.sh
```

This script will:
1. Detect the problem
2. Switch to master branch
3. Rebuild your system
4. Tell you if it worked

---

## All Available Resources

I've created comprehensive documentation for you:

| File | Purpose | Read When |
|------|---------|-----------|
| **START_HERE.md** | Quick start (this file) | Right now! |
| **README-EMERGENCY.md** | Main recovery hub | After quick fix |
| **QUICKSTART.md** | Fast recovery steps | You want TL;DR |
| **SOLUTION.md** | Full explanation | You want details |
| **EMERGENCY_RECOVERY.md** | Technical deep-dive | You need advanced help |
| **diagnose-emergency.sh** | Diagnostic tool | Something's still wrong |
| **fix-emergency-auto.sh** | Automated fix | You want one command |

---

## Your Recovery Path

```
┌─────────────────────────┐
│ You are here:           │
│ System in emergency mode│
└───────────┬─────────────┘
            │
            ├── Option 1: Boot old generation (1 min) ──┐
            │                                            │
            ├── Option 2: Auto-fix script (5 min) ──────┤
            │                                            │
            └── Option 3: Manual fix (10 min) ──────────┤
                                                         │
                                            ┌────────────▼───────────┐
                                            │ System working again   │
                                            │ On stable master branch│
                                            └────────────────────────┘
```

---

## Technical Summary (For Reference)

### Your System Specs
- **Machine**: MSI laptop (Intel Tiger Lake + NVIDIA RTX 3050 Ti)
- **Storage**: Samsung 870 EVO 500GB
- **Current FS**: ext4
- **Boot**: systemd-boot (511M EFI)

### Root Cause Analysis
- Development branch refs `./disko.nix` import
- File exists in development but not in master
- If system tried to build with development config on master branch
- → Missing file → Build/activation failure → Emergency mode

### Expected Filesystem UUIDs
- Root: `b89f5dca-4b37-4062-bf1d-9e4ebfd61916` (ext4)
- Boot: `8824-4C5F` (vfat)
- Swap: `c570ec29-6025-456b-99d1-8f16b677835a`

---

## FAQ

**Q: Will I lose data?**  
A: No! Your data is safe. This is a configuration issue, not a data loss issue.

**Q: Can I just stay on the old generation?**  
A: Yes! It's perfectly fine to boot the old generation and use that. You don't have to "fix" anything if the old generation works for you.

**Q: Do I have to switch to master branch?**  
A: For now, yes, unless you want to properly merge the development features (which requires more work).

**Q: What if the old generation doesn't work?**  
A: See `EMERGENCY_RECOVERY.md` for rescue media instructions. But this is very unlikely.

**Q: Can I keep using development branch?**  
A: Yes, but you need to ensure ALL the required files are present and properly tracked in git.

---

## Next Steps

1. ✅ **Now**: Boot previous generation (the 1-minute fix above)
2. ✅ **Next**: Switch to master branch (commands above)
3. ✅ **Later**: Read `README-EMERGENCY.md` to understand everything
4. ✅ **Future**: Decide if you want to stay on master or properly setup development

---

## Pull Request

All this documentation has been added to your repository in this PR:
- **Branch**: `cursor/fix-sliceanddice-emergency-mode-75c8`
- **PR**: #188 on GitHub

You can merge it once your system is recovered to have these docs available for future reference.

---

## Support

If you're still stuck after trying the above:

1. Run diagnostic: `bash diagnose-emergency.sh`
2. Read detailed guides: `EMERGENCY_RECOVERY.md`, `SOLUTION.md`
3. Check system logs: `journalctl -xb | grep -i error`
4. Verify mounts: `mount | grep -E "/(boot|nix)"`

**Remember**: Your data is safe. This is fixable. The fastest path is: Reboot → Boot old generation → Done!

---

Good luck! 🍀

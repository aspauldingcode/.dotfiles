# Current Issues Summary - sliceanddice

**Date**: November 11, 2026  
**System**: sliceanddice (NixOS, niri desktop)  
**Status**: Two active issues, both diagnosed with solutions ready

---

## Issue #1: TTY1 Blank Cursor / Greeter Not Starting

### Status: 🔴 CRITICAL
**What**: TTY1 shows blank blinking cursor instead of graphical login (gtkgreet)  
**Impact**: Cannot log in graphically  
**Root Cause**: greetd → sway → gtkgreet chain is broken

### Quick Fix:
```bash
# From TTY2 (Ctrl+Alt+F2)
sudo systemctl restart greetd
```

### Alternative Fix:
```bash
# Boot previous generation from systemd-boot menu
# Or rebuild from stable master branch
cd /etc/nixos/.dotfiles
git checkout master
sudo nixos-rebuild switch --flake .#sliceanddice
```

### Documentation:
- **FIX-TTY1-GREETER.md** - Complete troubleshooting guide
- **diagnose-tty1-greeter.sh** - Diagnostic script

### Technical Details:
The login flow is:
1. greetd service starts
2. sway launches as kiosk compositor  
3. gtkgreet shows login UI inside sway
4. After login, niri starts as desktop

One of these steps is failing. Most likely sway or gtkgreet.

### Important Note:
You mentioned "Shoji-wm/Shoji greeter" but this is **not** in the codebase. The actual stack is:
- greetd (service)
- sway (kiosk compositor)
- gtkgreet (login UI)
- niri (desktop)

If you're seeing "Shoji" references, check for local modifications.

---

## Issue #2: Cursor Multiple Instances / Display Issues

### Status: 🟡 MODERATE  
**What**: Cursor running but not displaying windows properly  
**Impact**: Cannot use Cursor IDE  
**Root Cause**: Stuck Cursor process or corrupted window state

### Quick Fix:
```bash
# Kill all Cursor processes
pkill -9 cursor

# Relaunch with Wayland
cursor --ozone-platform=wayland
```

### Key Findings:
| Finding | Meaning | Status |
|---------|---------|--------|
| Isolated profile works | Fresh user-data launches fine | ✅ Confirmed |
| Existing instance stuck | PID 23387 not showing windows | ✅ Confirmed |
| X11 backend active | Using XWayland instead of native Wayland | ✅ Confirmed |
| Mesa error | GBM driver load failure | ⚠️ Unknown impact |

### Why This Isn't a Reinstall:
- Cursor works (isolated launch proved it)
- NixOS config is fine
- **Problem is in `~/.config/Cursor` state**

### Progressive Fixes:
1. **Kill and relaunch** (most likely fix)
2. **Disable extensions** if #1 fails
3. **Disable GPU** if #2 fails  
4. **Fresh profile** if #3 fails
5. **Repair original profile** selectively

### Documentation:
- **FIX-CURSOR-MULTIPLE-INSTANCES.md** - Complete debugging guide

### Don't Do This:
- ❌ Don't reinstall Cursor
- ❌ Don't rebuild NixOS
- ❌ Don't delete config without backup

---

## Combined Recovery Plan

### Priority Order:

**1. Fix TTY1 First** (you need graphical login)
   - Use TTY2 to diagnose
   - Restart greetd service
   - Or boot previous generation

**2. Then Fix Cursor** (after you can log in)
   - Kill stuck processes
   - Relaunch with Wayland flags
   - Test progressively if needed

### Emergency Access:

If you can't log in graphically:

```bash
# From TTY2
# Temporarily enable autologin
sudo nano /etc/nixos/.dotfiles/hosts/nixos/sliceanddice/default.nix

# Add:
services.getty.autologinUser = "alex";

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice

# Reboot
sudo reboot
```

---

## System Context

### Hardware:
- **Machine**: MSI laptop
- **CPU**: Intel Tiger Lake
- **GPU**: Intel iGPU + NVIDIA RTX 3050 Ti (hybrid)
- **Display**: Internal panel on Intel iGPU
- **Storage**: Samsung 870 EVO 500GB

### Software Stack:
- **OS**: NixOS (system.stateVersion 24.11)
- **Compositor**: niri (scrollable-tiling Wayland)
- **Greeter**: gtkgreet via sway kiosk
- **Service Manager**: greetd
- **Kernel**: linuxPackages_latest

### Current Branch Status:
- **Master**: Stable, working configuration
- **Development**: New features, requires additional files
- **Emergency mode issue**: Caused by branch mismatch (now documented)

---

## All Available Documentation

| File | Purpose |
|------|---------|
| **CURRENT-ISSUES-SUMMARY.md** | This file - overview of both issues |
| **FIX-TTY1-GREETER.md** | TTY1/greeter troubleshooting |
| **diagnose-tty1-greeter.sh** | TTY1 diagnostic script |
| **FIX-CURSOR-MULTIPLE-INSTANCES.md** | Cursor issues troubleshooting |
| **START_HERE.md** | Emergency mode recovery quick start |
| **README-EMERGENCY.md** | Emergency recovery hub |
| **QUICKSTART.md** | Fast emergency recovery |
| **SOLUTION.md** | Full emergency mode explanation |
| **EMERGENCY_RECOVERY.md** | Technical recovery procedures |
| **diagnose-emergency.sh** | Emergency mode diagnostic |
| **fix-emergency-auto.sh** | Automated emergency fix |

---

## Quick Command Reference

### Diagnostics:
```bash
# TTY1/Greeter
sudo bash diagnose-tty1-greeter.sh

# Emergency Mode
sudo bash diagnose-emergency.sh

# Cursor
cursor --ozone-platform=wayland --enable-logging --v=1
```

### Fixes:
```bash
# TTY1
sudo systemctl restart greetd

# Cursor
pkill -9 cursor && cursor --ozone-platform=wayland

# Emergency Mode
sudo bash fix-emergency-auto.sh
```

### Logs:
```bash
# Greeter
sudo journalctl -u greetd -n 50

# System
sudo journalctl -b | grep -iE "(error|fail)"

# Graphics
sudo journalctl -b | grep -iE "(drm|nvidia|i915)"
```

---

## Next Steps

1. **Immediate**: Fix TTY1 to get graphical login working
2. **Then**: Fix Cursor once logged in
3. **Later**: Review and merge emergency mode documentation (PR #188)
4. **Future**: Decide on master vs development branch strategy

---

## Notes

- Both issues are **not** NixOS installation problems
- Both have **clear diagnostic paths**
- Both have **progressive fixes** (start simple, get more complex)
- All diagnostics and fixes are now documented and committed
- PR #188 contains all emergency recovery documentation

---

**Bottom Line**:
1. TTY1 issue: Service/compositor problem → restart greetd or boot old generation
2. Cursor issue: Stuck process → kill and relaunch with Wayland

Both are fixable without reinstalling anything!

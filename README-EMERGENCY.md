# 🆘 sliceanddice Emergency Mode - Recovery Instructions

> **STATUS**: Your sliceanddice NixOS system is in emergency mode  
> **CAUSE**: Configuration mismatch between master and development branches  
> **SOLUTION**: Multiple recovery paths available (choose the easiest one for you)

---

## 🚀 Quick Fix (Recommended - 2 minutes)

### Option 1: Boot Previous Generation (FASTEST!)

1. **Reboot** the sliceanddice machine
2. At the systemd-boot menu, press **`Space`** or **`Esc`**
3. Select an **older NixOS generation** (from before the problem)
4. Press **Enter** to boot

✅ **Done!** You're back in a working system.

Then prevent it from happening again:
```bash
cd /etc/nixos/.dotfiles
git checkout master
sudo nixos-rebuild switch --flake .#sliceanddice
```

---

## 🔧 Automated Fix Script

If you're in a working shell (emergency mode or booted from old generation):

```bash
cd /etc/nixos/.dotfiles
sudo bash fix-emergency-auto.sh
```

This script will:
- ✅ Detect the configuration problem
- ✅ Switch to stable master branch  
- ✅ Rebuild your system
- ✅ Verify everything works

---

## 📖 Detailed Documentation

Choose the guide that fits your situation:

| File | Purpose | When to Use |
|------|---------|-------------|
| **QUICKSTART.md** | Fast recovery steps | You want the TL;DR |
| **SOLUTION.md** | Complete explanation | You want to understand what happened |
| **EMERGENCY_RECOVERY.md** | Technical deep-dive | You need detailed recovery procedures |
| **diagnose-emergency.sh** | Diagnostic script | You want to see what's wrong |
| **fix-emergency-auto.sh** | Automated fix | You want one-command recovery |

---

## 🔍 What Happened?

**Short version**: The `development` branch has new features that require additional files. If you rebuilt using development branch config but the files weren't present, NixOS couldn't activate and dropped into emergency mode.

**Files required by development branch**:
- `disko.nix` - Disk/filesystem management
- `kbd-bl-ask.nix` - Keyboard backlight config
- `msi-ec-sword-kbd-disable.patch` - MSI laptop kernel patch
- Power management features
- Boot generation limiting

**Current master branch**: ✅ Stable, working, doesn't need these files

---

## 🛠️ Recovery Paths

### Path A: Previous Generation (Easiest)
Boot from systemd-boot menu → Select older generation → Boot

### Path B: Emergency Shell Fix
```bash
mount -o remount,rw /
cd /etc/nixos/.dotfiles
git checkout master
nixos-rebuild switch --flake .#sliceanddice
reboot
```

### Path C: Automated Script
```bash
sudo bash fix-emergency-auto.sh
```

### Path D: Rescue Media
Boot NixOS installer → Mount filesystems → Chroot → Fix config

---

## ⚡ After Recovery

Once your system is working again:

1. **Verify you're on master branch**:
   ```bash
   cd /etc/nixos/.dotfiles
   git branch  # Should show: * master
   ```

2. **Stay on master** (recommended):
   - It's stable and tested
   - No configuration changes needed
   - Everything works

3. **OR move to development** (advanced):
   - Merge development features properly
   - Test in VM first
   - Ensure all files are present

---

## 📞 Still Having Issues?

1. Run the diagnostic script:
   ```bash
   bash diagnose-emergency.sh
   ```

2. Check the detailed guides:
   - Read `SOLUTION.md` for full explanation
   - Read `EMERGENCY_RECOVERY.md` for technical details

3. Verify filesystem integrity:
   ```bash
   lsblk -o NAME,UUID,FSTYPE,SIZE,MOUNTPOINT
   df -h
   mount | grep -E "/(boot|nix|home)"
   ```

---

## 📊 System Information

**Machine**: MSI laptop with Intel Tiger Lake + NVIDIA RTX 3050 Ti  
**Storage**: Samsung 870 EVO 500GB  
**Current filesystem**: ext4 on root  
**Boot**: systemd-boot (511M EFI partition)  

**Expected UUIDs**:
- Root: `b89f5dca-4b37-4062-bf1d-9e4ebfd61916`
- Boot: `8824-4C5F`
- Swap: `c570ec29-6025-456b-99d1-8f16b677835a`

---

## ✅ Success Indicators

You'll know recovery worked when:
- ✅ System boots to desktop without emergency mode
- ✅ All applications work normally
- ✅ `systemctl status` shows no critical failures
- ✅ You're on master branch: `git branch` in dotfiles shows `* master`

---

## 🎯 Summary

| Problem | Fix | Time |
|---------|-----|------|
| Emergency mode | Boot previous generation | 1 min |
| + Want to prevent | Switch to master branch | 5 min |
| + Want automated fix | Run fix-emergency-auto.sh | 10 min |

**Bottom line**: Boot an older generation from the boot menu. Problem solved! 🎉

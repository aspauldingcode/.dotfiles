# Fix: Cursor Multiple Instances / Display Issues

## Problem Summary

Cursor is running multiple instances and not displaying correctly. An isolated launch works, but the normal instance doesn't show windows properly.

## Root Cause Analysis

Based on diagnostics, the issue is **NOT** a broken Cursor installation or NixOS configuration. Instead:

### Confirmed Issues:
1. **Existing Cursor process (PID 23387)** - New launches forward to already-running instance
2. **Isolated profile works** - Fresh user-data directory launches successfully  
3. **Existing renderers use X11** - Original instance running through XWayland
4. **Mesa `Permission denied`** - GBM driver load failure (impact unknown)
5. **Stuck window state** - Process running but not displaying windows

### Why Isolated Launch Worked

The successful isolated launch command changed three things:
1. **Fresh user-data directory** - Bypassed `~/.config/Cursor`
2. **Disabled extensions** - Prevented extensions from loading
3. **Native Wayland** - Requested Wayland instead of X11 backend

**Conclusion**: The problem is in your **existing Cursor profile/state**, not the application itself.

## Investigation Summary Table

| Finding                             | Meaning                                                                         | Assessment                      |
| ----------------------------------- | ------------------------------------------------------------------------------- | ------------------------------- |
| Existing Cursor process (PID 23387) | New launches were forwarded to an already-running instance                      | ✅ Confirmed                    |
| Isolated profile works              | Cursor can launch with a fresh user-data directory                              | ✅ Confirmed                    |
| Existing renderers use X11          | Your original instance was running through XWayland                             | ✅ Confirmed                    |
| Mesa `Permission denied`            | A GBM driver could not be loaded                                                | ⚠️ Confirmed error, impact unknown |
| Four Electron flag warnings         | Cursor doesn't recognize those options in its application-level argument parser | ℹ️ Not necessarily fatal        |
| `XDG_SESSION_TYPE=tty`              | Your graphical session may have been launched from a TTY                        | ℹ️ Not necessarily an issue     |

## Step-by-Step Fix

### Step 1: Kill All Cursor Instances

```bash
# Find all Cursor processes
ps aux | grep -i cursor

# Kill them all
pkill -9 cursor
pkill -9 Cursor

# Verify they're gone
ps aux | grep -i cursor
```

### Step 2: Test Clean Launch

After killing all instances, test a normal launch with Wayland:

```bash
cursor --ozone-platform=wayland
```

**If this works**: The problem was the stuck process. You're done!

**If this fails**: Continue to Step 3.

### Step 3: Test Without Extensions

Close Cursor and try launching without extensions:

```bash
cursor --disable-extensions --ozone-platform=wayland
```

**If this works**: An extension is causing the issue. See [Extension Debugging](#extension-debugging) below.

**If this fails**: Continue to Step 4.

### Step 4: Test GPU Configuration

Close Cursor and try with disabled GPU acceleration:

```bash
cursor --disable-gpu --ozone-platform=wayland
```

**If this works**: GPU/Mesa configuration issue. See [GPU Debugging](#gpu-debugging) below.

**If this fails**: Continue to Step 5.

### Step 5: Test Fresh Profile (Persistent)

Create a test profile and use it:

```bash
mkdir -p ~/.local/share/cursor-test-profile
cursor --user-data-dir="$HOME/.local/share/cursor-test-profile" --ozone-platform=wayland
```

**If this works**: Your original profile data is corrupted. See [Profile Repair](#profile-repair) below.

**If this fails**: The issue is deeper. See [Advanced Debugging](#advanced-debugging).

## Extension Debugging

If Step 3 worked (no extensions = works), identify the problematic extension:

```bash
# 1. Launch Cursor without extensions
cursor --disable-extensions --ozone-platform=wayland

# 2. Open Extensions view (Ctrl+Shift+X)

# 3. Disable all extensions manually

# 4. Close Cursor and relaunch normally
cursor --ozone-platform=wayland

# 5. Enable extensions one-by-one to find the culprit
```

**Common problematic extensions**:
- Remote development extensions
- Window management extensions
- Custom UI/theme extensions
- Extensions that hook into window creation

## GPU Debugging

If Step 4 worked (disabled GPU = works), investigate graphics issues:

### Check Mesa/GBM Setup

```bash
# Check for Mesa errors
journalctl --user -u cursor -n 100 | grep -i mesa

# Verify DRI devices
ls -la /dev/dri/

# Check OpenGL
glxinfo | grep -i "opengl\|vendor"
```

### Check NVIDIA/Intel Hybrid Graphics

Your sliceanddice has **Intel + NVIDIA hybrid graphics**. Cursor might be trying to use the wrong GPU.

```bash
# Force Intel GPU (integrated)
__GLX_VENDOR_LIBRARY_NAME=mesa cursor --ozone-platform=wayland

# Or force NVIDIA GPU (requires nvidia-offload)
nvidia-offload cursor --ozone-platform=wayland
```

### Wayland vs XWayland

The logs show your original instance used X11 through XWayland. Try forcing native Wayland:

```bash
# Ensure Wayland flags are set
export NIXOS_OZONE_WL=1
cursor --enable-features=UseOzonePlatform --ozone-platform=wayland
```

## Profile Repair

If Step 5 worked (fresh profile = works), your original profile has issues. **Don't delete everything!** Instead, selectively repair:

### Option 1: Reset Window State (Safest)

```bash
# Backup first
cp -r ~/.config/Cursor ~/.config/Cursor.backup

# Remove window state files
rm -f ~/.config/Cursor/User/globalStorage/state.vscdb*
rm -f ~/.config/Cursor/User/workspaceStorage/*/state.vscdb*

# Try launching
cursor --ozone-platform=wayland
```

### Option 2: Disable Cached Data

```bash
# Remove GPU cache
rm -rf ~/.config/Cursor/GPUCache/

# Remove code cache
rm -rf ~/.config/Cursor/CachedData/

# Try launching
cursor --ozone-platform=wayland
```

### Option 3: Fresh Extensions (Keep Settings)

```bash
# Backup
cp -r ~/.config/Cursor ~/.config/Cursor.backup

# Remove extensions but keep settings
rm -rf ~/.config/Cursor/extensions/

# Try launching (extensions will reinstall)
cursor --ozone-platform=wayland
```

### Option 4: Selective Settings Reset

```bash
# Backup
cp -r ~/.config/Cursor ~/.config/Cursor.backup

# Copy settings.json to safe place
cp ~/.config/Cursor/User/settings.json ~/cursor-settings-backup.json

# Remove problematic UI state
rm -rf ~/.config/Cursor/User/globalStorage/
rm -rf ~/.config/Cursor/User/workspaceStorage/

# Restore settings
cp ~/cursor-settings-backup.json ~/.config/Cursor/User/settings.json

# Try launching
cursor --ozone-platform=wayland
```

### Option 5: Full Profile Reset (Last Resort)

Only if nothing else works:

```bash
# Full backup
mv ~/.config/Cursor ~/.config/Cursor.broken-$(date +%Y%m%d)

# Launch fresh
cursor --ozone-platform=wayland

# Then manually restore settings/keybindings from backup
```

## Advanced Debugging

### Check Wayland Socket

```bash
# Verify Wayland display
echo $WAYLAND_DISPLAY

# Check socket permissions
ls -la $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY

# Test with weston-info
weston-info | head -20
```

### Check Niri Compositor

Since you're using niri:

```bash
# Check niri is running
ps aux | grep niri

# Check niri IPC
niri msg outputs

# Check niri version
niri --version
```

### Session Type Check

Your logs showed `XDG_SESSION_TYPE=tty`. This might be the issue:

```bash
# Check session type
echo $XDG_SESSION_TYPE
# Should be "wayland", not "tty"

# If wrong, ensure niri session is properly configured
# Check /etc/greetd/environments
cat /etc/greetd/environments
```

### Cursor Launch Script

Check how Cursor is being launched:

```bash
# Find the Cursor wrapper
which cursor
cat $(which cursor)

# Check for any custom launch flags in your shell config
grep -r "cursor" ~/.zshrc ~/.bashrc ~/.config/fish/
```

## NixOS-Specific Checks

### Verify Cursor Package

```bash
# Check Cursor derivation
nix-store -q --references $(which cursor) | grep cursor

# Verify Ozone flags are set system-wide
echo $NIXOS_OZONE_WL
# Should be "1"
```

### Check Home Manager Config

```bash
cd /etc/nixos/.dotfiles

# Check for Cursor configuration
grep -r "cursor" modules/apps/
grep -r "Cursor" home/
```

From your sliceanddice config, Cursor is enabled via:
```nix
dendritic.apps.cursor.enable = true;
```

### Rebuild if Needed

Only if you suspect the NixOS configuration:

```bash
cd /etc/nixos/.dotfiles
sudo nixos-rebuild switch --flake .#sliceanddice
```

## Automated Fix Script

```bash
#!/usr/bin/env bash
# Quick Cursor fix script

echo "=== Cursor Multi-Instance Fix ==="
echo ""

echo "Step 1: Killing all Cursor processes..."
pkill -9 cursor 2>/dev/null || true
pkill -9 Cursor 2>/dev/null || true
sleep 2

echo "Step 2: Checking for remaining processes..."
if pgrep -i cursor >/dev/null; then
    echo "⚠️  Cursor processes still running:"
    ps aux | grep -i [c]ursor
else
    echo "✓ All Cursor processes killed"
fi
echo ""

echo "Step 3: Testing clean launch with Wayland..."
cursor --ozone-platform=wayland &
CURSOR_PID=$!
sleep 3

if ps -p $CURSOR_PID > /dev/null; then
    echo "✓ Cursor launched successfully!"
    echo "  PID: $CURSOR_PID"
    echo ""
    echo "If the window appeared, you're done!"
    echo "If not, press Ctrl+C and run the manual tests."
else
    echo "❌ Cursor failed to launch"
    echo "   Try the manual debugging steps in FIX-CURSOR-MULTIPLE-INSTANCES.md"
fi
```

Save this as `fix-cursor-quick.sh` and run it.

## Prevention

To avoid this issue in the future:

1. **Always use native Wayland**:
   ```bash
   # Add to your shell rc file
   alias cursor='cursor --ozone-platform=wayland'
   ```

2. **Clean shutdown**: Don't force-kill Cursor unless necessary
   
3. **Monitor stuck processes**:
   ```bash
   # Before launching, check if already running
   pgrep cursor && echo "Cursor already running!"
   ```

4. **Regular cache cleanup**:
   ```bash
   # Once a month
   rm -rf ~/.config/Cursor/GPUCache/
   rm -rf ~/.config/Cursor/CachedData/
   ```

## Summary of the Fix Path

```
1. Kill all Cursor processes
   ↓ Works? → Done!
   ↓ Fails? ↓
   
2. Launch without extensions  
   ↓ Works? → Disable problematic extension
   ↓ Fails? ↓
   
3. Launch without GPU
   ↓ Works? → Fix Mesa/GPU configuration
   ↓ Fails? ↓
   
4. Launch with fresh profile
   ↓ Works? → Repair original profile
   ↓ Fails? → Advanced debugging needed
```

## Most Likely Solution

Based on the symptoms, **the most likely fix** is simply:

```bash
# Kill stuck process
pkill -9 cursor

# Relaunch with proper Wayland
cursor --ozone-platform=wayland
```

The isolated launch proved Cursor works fine; the issue was the stuck existing process or corrupted window state.

## What NOT to Do

- ❌ Don't reinstall Cursor (not needed)
- ❌ Don't rebuild NixOS (not needed)  
- ❌ Don't delete `~/.config/Cursor` without backup
- ❌ Don't delete `~/.cursor` without backup

## Need More Help?

If none of these work, collect debug info:

```bash
# Run Cursor with verbose logging
cursor --ozone-platform=wayland --enable-logging --v=1 2>&1 | tee ~/cursor-debug.log

# Then check the log
grep -i "error\|failed\|denied" ~/cursor-debug.log
```

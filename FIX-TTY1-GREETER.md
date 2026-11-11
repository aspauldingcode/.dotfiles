# Fix: TTY1 Blank Cursor / Greeter Not Starting

## Problem
TTY1 shows a blank blinking cursor instead of the graphical greeter (gtkgreet running in sway kiosk mode).

## Root Cause Analysis

Based on the niri configuration in `modules/apps/niri.nix`, the login flow is:
1. **greetd** service starts on boot
2. **sway** launches as a minimal kiosk compositor  
3. **gtkgreet** runs inside sway to show the login UI
4. After login, **niri** starts as the main desktop compositor

**Blank cursor** means one of these steps is failing (most likely #2 or #3).

## Quick Diagnosis

### From TTY2 (Ctrl+Alt+F2)

```bash
# Login to TTY2
# Then check what's failing:

# 1. Check greetd service
sudo systemctl status greetd

# 2. Check recent logs
sudo journalctl -u greetd -n 50

# 3. Check for sway processes
ps aux | grep sway

# 4. Check graphics
ls -la /dev/dri/
```

### Using the Diagnostic Script

```bash
cd /etc/nixos/.dotfiles
sudo bash diagnose-tty1-greeter.sh
```

## Common Causes & Fixes

### 1. Sway Kiosk Config Missing/Broken

**Symptom**: greetd tries to start sway but sway fails immediately

**Check**:
```bash
# Look for the sway greeter config in system closure
ls -la /nix/store/*greetd-sway-gtkgreet*
```

**Fix**: The config is generated from `modules/apps/niri.nix`. Check if `swayGreeterConfig` is being created correctly.

### 2. Graphics Driver Issues (NVIDIA + Intel Hybrid)

**Symptom**: sway can't access GPU, DRM errors in journal

**Check**:
```bash
# Verify drivers are loaded
lsmod | grep -E "nvidia|i915"

# Check DRM devices
ls -la /dev/dri/

# Look for DRM errors
journalctl -b | grep -i drm
```

**Fix for NVIDIA issues**:
- The sliceanddice config uses NVIDIA open drivers + Intel hybrid
- sway needs access to the Intel iGPU (not NVIDIA for the greeter)
- Ensure `hardware.nvidia.modesetting.enable = true`
- Check that sway isn't trying to use NVIDIA

### 3. gtkgreet Binary Missing or Wrong Path

**Symptom**: sway starts but gtkgreet command fails

**Check**:
```bash
# Verify gtkgreet exists
which gtkgreet
gtkgreet --version

# Check the exact command greetd is trying to run
sudo journalctl -u greetd | grep -i "exec\|command"
```

**Fix**: Rebuild to ensure gtkgreet is in the closure:
```bash
cd /etc/nixos/.dotfiles
sudo nixos-rebuild switch --flake .#sliceanddice
```

### 4. CSS File Missing

**Symptom**: gtkgreet starts but crashes due to missing stylesheet

**Check**:
```bash
ls -la /etc/greetd/gtkgreet.css
```

**Fix**: The CSS is generated from `_gtk-auth-style.nix` via `environment.etc."greetd/gtkgreet.css"`. Rebuild to regenerate it.

### 5. Wayland Socket Permissions

**Symptom**: sway starts but can't create Wayland socket

**Check**:
```bash
ls -la /run/user/*/wayland-*
sudo -u greeter ls -la $XDG_RUNTIME_DIR 2>/dev/null || echo "No runtime dir"
```

**Fix**: Ensure the `greeter` user has proper runtime directory setup.

### 6. Development vs Master Branch Mismatch

**Important**: The development branch has a completely different auth setup!

**Development branch** uses:
- Runtime wallpaper selection
- Dynamic CSS generation
- `gtkgreet-auth` wrapper script
- Avatar/profile photo integration
- Dendritic appearance tool

**Master branch** uses:
- Static wallpaper from `stylix.image`
- Static CSS from `_gtk-auth-style.nix`
- Simple gtkgreet launch

**If you're seeing issues**, check which branch you're on:
```bash
cd /etc/nixos/.dotfiles
git branch --show-current
```

If on development, the auth system is more complex and may have additional failure points.

## Step-by-Step Fix

### Fix 1: Restart greetd

```bash
sudo systemctl restart greetd
```

Then switch back to TTY1 (Ctrl+Alt+F1) and see if greeter appears.

### Fix 2: Rebuild from Stable Master

```bash
cd /etc/nixos/.dotfiles

# Switch to master if needed
git checkout master
git pull origin master

# Rebuild
sudo nixos-rebuild switch --flake .#sliceanddice

# Reboot
sudo reboot
```

### Fix 3: Check and Fix Graphics

```bash
# If NVIDIA is causing issues, temporarily disable it for greeter
# Edit hosts/nixos/sliceanddice/default.nix
# Comment out the nvidia videoDrivers line:
# services.xserver.videoDrivers = [ "nvidia" ];

sudo nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice
sudo reboot
```

### Fix 4: Switch to Different Greeter (Emergency)

If gtkgreet is broken, you can temporarily use autologin or a simpler greeter:

```nix
# In hosts/nixos/sliceanddice/default.nix
# Temporarily disable niri greeter:
dendritic.apps.niri.enable = false;

# Add simple getty autologin:
services.getty.autologinUser = "alex";
```

## Manual Testing

To test the greeter command manually:

```bash
# Become the greeter user
sudo -u greeter bash

# Try running sway with the greeter config
# (You'll need to find the config path first)
sway --config /nix/store/*greetd-sway-gtkgreet*
```

## Checking Configuration

### Expected Configuration on Master Branch

From `modules/apps/niri.nix`:

```nix
swayGreeterConfig = pkgs.writeText "greetd-sway-gtkgreet" ''
  # Minimal kiosk compositor for gtkgreet (desktop sway stays disabled).
  exec "${gtkgreet}/bin/gtkgreet -l -s /etc/greetd/gtkgreet.css; ${pkgs.sway}/bin/swaymsg exit"
  bindsym Mod4+shift+e exec ${pkgs.sway}/bin/swaynag \
    -t warning \
    -m 'Power?' \
    -b 'Poweroff' 'systemctl poweroff' \
    -b 'Reboot' 'systemctl reboot'
'';

services.greetd = {
  enable = true;
  settings.default_session = {
    command = "${pkgs.sway}/bin/sway --config ${swayGreeterConfig}";
    user = "greeter";
  };
};
```

This should be present if `dendritic.apps.niri.enable = true` in your sliceanddice config.

## About "Shoji" Greeter

You mentioned "Shoji-wm/Shoji greeter" - this is **not** in the current codebase. The actual setup uses:
- **greetd** (login daemon)
- **gtkgreet** (GTK-based greeter UI)
- **sway** (Wayland compositor, kiosk mode only for login)
- **niri** (main desktop compositor after login)

If you're seeing references to "Shoji", this might be:
1. A local modification not in git
2. A misunderstanding of the stack
3. An experimental branch

## System Stack Verification

```bash
# On the actual sliceanddice machine:
cd /etc/nixos/.dotfiles

# Check configuration
grep -r "shoji" . || echo "No Shoji found"
grep -r "greetd" hosts/nixos/sliceanddice/
grep -r "gtkgreet" modules/apps/niri.nix

# Verify packages are installed
nix-store -q --references /run/current-system | grep -E "(greetd|gtkgreet|sway)"
```

## Logs to Collect

If the issue persists, collect these logs:

```bash
# greetd logs
sudo journalctl -u greetd -n 100 > /tmp/greetd.log

# Boot logs (graphics/wayland)
sudo journalctl -b | grep -iE "(sway|wayland|drm|nvidia|i915)" > /tmp/graphics.log

# System status
systemctl status greetd > /tmp/greetd-status.log
systemctl status getty@tty1 > /tmp/getty-status.log
```

## Next Steps

1. Run `diagnose-tty1-greeter.sh` and review output
2. Check which branch you're on (master vs development)
3. Check greetd logs for specific error messages
4. Verify graphics drivers are working
5. If all else fails, boot previous generation or use autologin temporarily

## Prevention

- **Test display manager changes in VM first**
- **Keep old generations**: Don't set `boot.loader.systemd-boot.configurationLimit` too low
- **Stick to one branch**: Don't mix master and development features
- **Check logs after every rebuild**: `sudo journalctl -u greetd -f`

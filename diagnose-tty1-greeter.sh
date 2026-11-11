#!/usr/bin/env bash
# Diagnostic for TTY1 greeter issues (blank blinking cursor)
# Run this as root to diagnose greeter/display manager problems

set -euo pipefail

echo "=== TTY1 / Greeter Diagnostic ==="
echo "Timestamp: $(date)"
echo ""

echo "=== Greeter Service Status ==="
echo "--- greetd status ---"
systemctl status greetd.service --no-pager -l || true
echo ""

echo "--- greetd logs (last 50 lines) ---"
journalctl -u greetd.service -n 50 --no-pager || true
echo ""

echo "=== Display Manager Check ==="
echo "Active display managers:"
systemctl list-units --type=service --state=running | grep -iE "(gdm|sddm|lightdm|greetd|ly)" || echo "None found"
echo ""

echo "=== TTY1 Status ==="
echo "--- getty@tty1 status ---"
systemctl status getty@tty1.service --no-pager || true
echo ""

echo "=== Sway / Compositor Status ==="
echo "Sway processes:"
ps aux | grep -E "[s]way|[S]way" || echo "No sway processes"
echo ""

echo "Niri processes:"
ps aux | grep "[n]iri" || echo "No niri processes"
echo ""

echo "=== Wayland / Display Environment ==="
echo "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-not set}"
echo "DISPLAY: ${DISPLAY:-not set}"
echo ""

echo "Active Wayland compositors:"
ps aux | grep -E "[w]eston|[s]way|[n]iri|[h]yprland|[w]ay.*fire" || echo "None found"
echo ""

echo "=== gtkgreet Configuration ==="
if [ -f /etc/greetd/config.toml ]; then
    echo "--- /etc/greetd/config.toml ---"
    cat /etc/greetd/config.toml
else
    echo "⚠️  /etc/greetd/config.toml NOT FOUND"
fi
echo ""

if [ -f /etc/greetd/gtkgreet.css ]; then
    echo "✓ /etc/greetd/gtkgreet.css exists ($(wc -l < /etc/greetd/gtkgreet.css) lines)"
else
    echo "⚠️  /etc/greetd/gtkgreet.css NOT FOUND"
fi
echo ""

if [ -d /etc/greetd ]; then
    echo "--- /etc/greetd contents ---"
    ls -la /etc/greetd/
else
    echo "⚠️  /etc/greetd directory NOT FOUND"
fi
echo ""

echo "=== Sway Greeter Config ==="
sway_config=$(nix-store -q --references /run/current-system 2>/dev/null | grep -i "greetd-sway" | head -1 || echo "")
if [ -n "$sway_config" ]; then
    echo "Found sway greeter config: $sway_config"
    if [ -f "$sway_config" ]; then
        echo "--- Contents ---"
        cat "$sway_config" 2>/dev/null || echo "Cannot read"
    fi
else
    echo "⚠️  Sway greeter config not found in system closure"
fi
echo ""

echo "=== Recent Boot Errors (grep for sway/greeter/wayland) ==="
journalctl -b --no-pager -p err | grep -iE "(sway|greet|wayland|compositor|drm|gpu)" || echo "No relevant errors"
echo ""

echo "=== Graphics/DRM Status ==="
echo "--- DRM devices ---"
ls -la /dev/dri/ 2>/dev/null || echo "/dev/dri not found"
echo ""

echo "--- Graphics drivers loaded ---"
lsmod | grep -iE "(nvidia|nouveau|i915|amdgpu|radeon)" || echo "No graphics modules"
echo ""

echo "=== NixOS Configuration ==="
if [ -d /etc/nixos/.dotfiles ]; then
    cd /etc/nixos/.dotfiles
    echo "Git branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo "Last commit: $(git log -1 --oneline 2>/dev/null || echo 'unknown')"
    echo ""
    
    echo "Checking niri module config..."
    if grep -q "dendritic.apps.niri.enable = true" hosts/nixos/sliceanddice/default.nix 2>/dev/null; then
        echo "✓ niri is enabled"
    else
        echo "⚠️  niri might not be enabled"
    fi
    
    if grep -q "services.greetd" modules/apps/niri.nix 2>/dev/null; then
        echo "✓ greetd configuration found in niri.nix"
    else
        echo "⚠️  greetd configuration not found"
    fi
fi
echo ""

echo "=== Package Versions ==="
echo "gtkgreet: $(gtkgreet --version 2>/dev/null || echo 'not in PATH')"
echo "sway: $(sway --version 2>/dev/null || echo 'not in PATH')"
echo "niri: $(niri --version 2>/dev/null || echo 'not in PATH')"
echo ""

echo "=== Common Issues & Solutions ==="
echo ""
echo "Issue: Blank cursor on TTY1"
echo "Possible causes:"
echo "  1. Sway failing to start (check sway logs above)"
echo "  2. gtkgreet crashing immediately (check greetd logs)"
echo "  3. Missing/broken sway config for greeter"
echo "  4. Graphics driver issues (NVIDIA/Intel hybrid)"
echo "  5. Wayland socket permissions"
echo ""
echo "Quick fixes:"
echo "  1. Switch to TTY2: Ctrl+Alt+F2, login, check logs"
echo "  2. Restart greetd: systemctl restart greetd"
echo "  3. Check sway manually: sudo -u greeter sway --config /path/to/greeter/config"
echo "  4. Rebuild config: nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice"
echo ""

echo "=== Suggested Next Steps ==="
echo ""
if systemctl is-failed greetd.service >/dev/null 2>&1; then
    echo "❌ greetd service FAILED - this is the problem!"
    echo "   → Check 'journalctl -u greetd.service' output above"
    echo "   → Common fix: rebuild NixOS config"
elif ! systemctl is-active greetd.service >/dev/null 2>&1; then
    echo "❌ greetd service NOT RUNNING"
    echo "   → Try: systemctl start greetd"
else
    echo "✓ greetd service is running"
    echo "  → Check if sway process is stuck"
    echo "  → Check Wayland socket: ls -la /run/user/*/wayland-*"
fi
echo ""

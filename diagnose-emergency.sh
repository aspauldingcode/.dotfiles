#!/usr/bin/env bash
# Emergency diagnostic script for sliceanddice boot issues
# Run this in emergency mode or from a rescue shell

set -euo pipefail

echo "=== sliceanddice Emergency Diagnostic ==="
echo "Timestamp: $(date)"
echo ""

echo "=== System Status ==="
systemctl status --no-pager --failed || true
echo ""

echo "=== Mount Status ==="
mount | sort
echo ""

echo "=== Filesystem Space ==="
df -h || true
echo ""

echo "=== Failed Mount Units ==="
systemctl list-units --type=mount --failed --no-pager || true
echo ""

echo "=== Boot Partition Contents ==="
if [ -d /boot ]; then
    echo "Boot partition space:"
    du -sh /boot/* 2>/dev/null || true
    echo ""
    echo "Boot entries:"
    ls -lh /boot/loader/entries/ 2>/dev/null || true
else
    echo "/boot not mounted"
fi
echo ""

echo "=== Filesystem UUIDs ==="
echo "Expected UUIDs from hardware-configuration.nix:"
echo "  Root (ext4): b89f5dca-4b37-4062-bf1d-9e4ebfd61916"
echo "  Boot (vfat): 8824-4C5F"
echo "  Swap:        c570ec29-6025-456b-99d1-8f16b677835a"
echo ""
echo "Actual block devices:"
lsblk -o NAME,UUID,FSTYPE,SIZE,MOUNTPOINT || true
echo ""

echo "=== Git Configuration Status ==="
if [ -d /etc/nixos/.dotfiles ]; then
    cd /etc/nixos/.dotfiles
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo "Last commit: $(git log -1 --oneline 2>/dev/null || echo 'unknown')"
    echo "Status:"
    git status -s 2>/dev/null || true
    echo ""
    echo "Checking for disko.nix:"
    if [ -f hosts/nixos/sliceanddice/disko.nix ]; then
        echo "  ✓ disko.nix exists"
    else
        echo "  ✗ disko.nix MISSING"
        echo "  → This is likely the problem if default.nix imports it!"
    fi
    echo ""
    echo "Checking imports in default.nix:"
    grep -E "^\s*(./disko\.nix|imports\s*=)" hosts/nixos/sliceanddice/default.nix 2>/dev/null || true
else
    echo "/etc/nixos/.dotfiles not found"
fi
echo ""

echo "=== Recent Boot Logs (errors only) ==="
journalctl -p err -b --no-pager -n 50 2>/dev/null || true
echo ""

echo "=== Kernel Command Line ==="
cat /proc/cmdline 2>/dev/null || true
echo ""

echo "=== Available Generations ==="
if [ -d /nix/var/nix/profiles ]; then
    ls -lh /nix/var/nix/profiles/system-*-link 2>/dev/null | tail -10 || true
else
    echo "Profile directory not accessible"
fi
echo ""

echo "=== Suggested Actions ==="
echo ""
echo "1. If disko.nix is missing but imported:"
echo "   cd /etc/nixos/.dotfiles && git checkout master"
echo ""
echo "2. If /boot is full:"
echo "   nix-collect-garbage -d"
echo "   Or temporarily increase configurationLimit"
echo ""
echo "3. If filesystems won't mount:"
echo "   Check 'journalctl -xb' for specific mount errors"
echo "   Verify UUIDs match: blkid /dev/sdX"
echo ""
echo "4. Rollback to previous generation:"
echo "   From systemd-boot menu, select an older entry"
echo ""
echo "5. Force rebuild from master:"
echo "   cd /etc/nixos/.dotfiles"
echo "   git checkout master && git reset --hard origin/master"
echo "   nixos-rebuild switch --flake /etc/nixos/.dotfiles#sliceanddice"
echo ""

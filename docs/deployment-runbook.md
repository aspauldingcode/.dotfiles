# Production Deployment Runbook

## 🚀 Overview

This runbook provides step-by-step procedures for deploying and managing the production Nix flake configurations across multiple systems and architectures.

## 📋 Pre-Deployment Checklist

### Security Verification

- [ ] All SOPS keys are properly rotated for production
- [ ] Secrets are encrypted and validated
- [ ] Security scanning has passed in CI/CD
- [ ] No hardcoded credentials in configurations
- [ ] Firewall rules are configured appropriately

### Configuration Validation

- [ ] All configurations pass `nix flake check`
- [ ] Cross-platform builds are tested
- [ ] Development shells are functional
- [ ] Custom packages build successfully
- [ ] Performance benchmarks are within acceptable limits

### Infrastructure Readiness

- [ ] Target hardware is available and accessible
- [ ] Network connectivity is established
- [ ] Backup systems are in place
- [ ] Monitoring systems are configured
- [ ] Rollback procedures are tested

## 🎯 Deployment Procedures

### 1. macOS Systems (Darwin)

#### NIXY (Apple Silicon macOS)

```bash
# 1. Backup current configuration
sudo cp -r /etc/nix /etc/nix.backup.$(date +%Y%m%d-%H%M%S)

# 2. Clone/update repository
cd ~/.dotfiles
git pull origin main

# 3. Validate configuration
./scripts/flake-check.sh --current-system

# 4. Build configuration
nix build .#darwinConfigurations.NIXY.system

# 5. Apply configuration
sudo ./result/sw/bin/darwin-rebuild switch --flake .#NIXY

# 6. Verify system health
system_profiler SPSoftwareDataType
nix-env --list-generations
```

#### NIXI (Intel macOS)

```bash
# 1. Backup current configuration
sudo cp -r /etc/nix /etc/nix.backup.$(date +%Y%m%d-%H%M%S)

# 2. Clone/update repository
cd ~/.dotfiles
git pull origin main

# 3. Validate configuration
./scripts/flake-check.sh --current-system

# 4. Build configuration
nix build .#darwinConfigurations.NIXI.system

# 5. Apply configuration
darwin-rebuild switch --flake .#NIXI

# 6. Verify system health
system_profiler SPSoftwareDataType
nix-env --list-generations
```

#### Rollback Procedure (macOS)

```bash
# List available generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nix-env --rollback --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/activate
```

### 2. NixOS Systems

#### NIXSTATION64 (x86_64 Linux Desktop)

```bash
# 1. Backup current configuration
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup.$(date +%Y%m%d-%H%M%S)

# 2. Clone/update repository
cd /etc/nixos/dotfiles
git pull origin main

# 3. Validate configuration
./scripts/flake-check.sh --current-system

# 4. Build configuration
sudo nixos-rebuild build --flake .#NIXSTATION64

# 5. Test configuration (optional)
sudo nixos-rebuild test --flake .#NIXSTATION64

# 6. Apply configuration
sudo nixos-rebuild switch --flake .#NIXSTATION64

# 7. Verify system health
systemctl status
journalctl -xe --no-pager -n 50
```

#### NIXY2 (ARM64 Linux VM)

```bash
# 1. Ensure VM is running and accessible
ssh admin@nixy2-vm

# 2. Update repository
cd ~/.dotfiles
git pull origin main

# 3. Validate configuration
./scripts/flake-check.sh --current-system

# 4. Build and apply
sudo nixos-rebuild switch --flake .#NIXY2

# 5. Verify VM functionality
systemctl status
free -h
df -h
```

#### NIXEDUP (Mobile NixOS - OnePlus 6T)

```bash
# 1. Prepare mobile device
# Ensure device is in fastboot mode
fastboot devices

# 2. Build mobile image
nix build .#nixosConfigurations.NIXEDUP.config.system.build.toplevel

# 3. Flash device (CAUTION: This will wipe the device)
# Follow mobile-nixos specific flashing procedures
# Refer to: https://mobile.nixos.org/devices/oneplus-6t.html

# 4. First boot verification
# Connect via SSH after boot
ssh mobile@192.168.1.xxx

# 5. Verify mobile-specific services
systemctl status phosh
systemctl status calls
systemctl status chatty
```

### 3. Home Manager Configurations

#### Standalone Home Manager Deployment

```bash
# 1. Update repository
cd ~/.dotfiles
git pull origin main

# 2. Validate home configuration
nix build .#homeConfigurations.alex-$(hostname).activationPackage

# 3. Apply home configuration
./result/activate

# 4. Verify user environment
home-manager generations
echo $PATH
which nvim
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Build Failures

```bash
# Clear Nix cache
nix-collect-garbage -d
nix store gc

# Rebuild with verbose output
nix build --verbose --show-trace .#nixosConfigurations.SYSTEM_NAME.config.system.build.toplevel
```

#### 2. SOPS Decryption Failures

```bash
# Verify SOPS key
sops --decrypt secrets/example.yaml

# Re-encrypt with new key
sops --rotate --in-place secrets/example.yaml

# Update age key
age-keygen -o ~/.config/sops/age/keys.txt
```

#### 3. Cross-Platform Build Issues

```bash
# Use our custom flake check script
./scripts/flake-check.sh --current-system

# Force rebuild with current system only
nix build --system $(nix eval --impure --raw --expr 'builtins.currentSystem') .#CONFIGURATION
```

#### 4. Network Connectivity Issues (Mobile)

```bash
# Check NetworkManager status
nmcli device status
nmcli connection show

# Restart networking
sudo systemctl restart NetworkManager
```

#### 5. Performance Issues

```bash
# Check system resources
htop
iotop
nix-store --gc --print-roots | wc -l

# Optimize Nix store
nix store optimise
```

## 📊 Health Checks

### System Health Verification

```bash
#!/bin/bash
# health-check.sh

echo "🏥 System Health Check"
echo "====================="

# System info
echo "📋 System Information:"
uname -a
nix --version

# Disk usage
echo "💾 Disk Usage:"
df -h /nix

# Memory usage
echo "🧠 Memory Usage:"
free -h

# Service status (NixOS)
if command -v systemctl >/dev/null; then
    echo "🔧 Critical Services:"
    systemctl is-active sshd NetworkManager
fi

# Nix store health
echo "📦 Nix Store Health:"
nix store verify --all --no-trust || echo "Store verification failed"

# Configuration generation
echo "🔄 Current Generation:"
if command -v nixos-version >/dev/null; then
    nixos-version
elif command -v darwin-version >/dev/null; then
    darwin-version
fi

echo "✅ Health check completed"
```

### Performance Monitoring

```bash
#!/bin/bash
# performance-monitor.sh

echo "⚡ Performance Monitoring"
echo "========================"

# Build time measurement
echo "🏗️  Build Performance:"
time nix eval .#nixosConfigurations.NIXSTATION64.config.system.build.toplevel.outPath --raw

# Memory usage during evaluation
echo "🧠 Memory Usage During Evaluation:"
/usr/bin/time -v nix eval .#nixosConfigurations --apply builtins.attrNames 2>&1 | grep "Maximum resident set size"

# Store size
echo "📦 Nix Store Size:"
du -sh /nix/store

echo "📊 Performance monitoring completed"
```

## 🔄 Backup and Recovery

### Configuration Backup

```bash
#!/bin/bash
# backup-config.sh

BACKUP_DIR="/var/backups/nixos-config/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup current configuration
cp -r ~/.dotfiles "$BACKUP_DIR/dotfiles"
cp /etc/nixos/hardware-configuration.nix "$BACKUP_DIR/" 2>/dev/null || true

# Backup current generation
nix-env --list-generations --profile /nix/var/nix/profiles/system > "$BACKUP_DIR/generations.txt"

# Backup SOPS keys
cp -r ~/.config/sops "$BACKUP_DIR/sops-keys" 2>/dev/null || true

echo "✅ Configuration backed up to $BACKUP_DIR"
```

### System Recovery

```bash
#!/bin/bash
# recovery.sh

echo "🚨 System Recovery Procedure"
echo "============================"

# 1. Boot from NixOS installer or recovery media
# 2. Mount existing system
mount /dev/disk/by-label/nixos /mnt
mount /dev/disk/by-label/boot /mnt/boot

# 3. Enter chroot environment
nixos-enter --root /mnt

# 4. Rollback to previous generation
nix-env --rollback --profile /nix/var/nix/profiles/system
/nix/var/nix/profiles/system/bin/switch-to-configuration switch

# 5. Reboot
reboot
```

## 📈 Monitoring and Alerting

### Key Metrics to Monitor

- System uptime and availability
- Disk usage (/nix partition)
- Memory consumption
- Network connectivity
- Service health (SSH, NetworkManager, etc.)
- Configuration drift detection
- Security update status

### Alerting Thresholds

- Disk usage > 85%
- Memory usage > 90%
- Service downtime > 5 minutes
- Failed configuration builds
- Security vulnerabilities detected

## 🔐 Security Procedures

### SOPS Key Rotation

```bash
#!/bin/bash
# rotate-sops-keys.sh

echo "🔐 SOPS Key Rotation"
echo "==================="

# 1. Generate new age key
age-keygen -o ~/.config/sops/age/keys-new.txt

# 2. Update .sops.yaml with new key
# Edit .sops.yaml to include new public key

# 3. Re-encrypt all secrets
find secrets/ -name "*.yaml" -exec sops --rotate --in-place {} \;

# 4. Test decryption with new key
sops --decrypt secrets/example.yaml

# 5. Replace old key
mv ~/.config/sops/age/keys.txt ~/.config/sops/age/keys-old.txt
mv ~/.config/sops/age/keys-new.txt ~/.config/sops/age/keys.txt

echo "✅ SOPS key rotation completed"
```

### Security Audit

```bash
#!/bin/bash
# security-audit.sh

echo "🔍 Security Audit"
echo "================="

# Check for insecure packages
nix-env -qa --json | jq -r '.[] | select(.meta.insecure == true) | .pname'

# Verify SOPS encryption
find secrets/ -name "*.yaml" -exec sh -c 'echo "Checking $1:"; head -5 "$1"' _ {} \;

# Check file permissions
find ~/.dotfiles -type f -perm /o+w -ls

# Scan for potential secrets in code
git log --all --full-history -- "*.nix" | grep -i -E "(password|secret|key|token)" || echo "No obvious secrets found in git history"

echo "🔒 Security audit completed"
```

## 📞 Emergency Contacts and Escalation

### Emergency Procedures

1. **System Down**: Use recovery media to boot and rollback
1. **Security Breach**: Immediately rotate all SOPS keys and secrets
1. **Data Loss**: Restore from latest backup and verify integrity
1. **Network Issues**: Check physical connections and restart NetworkManager

### Escalation Matrix

- **Level 1**: Configuration issues, minor service disruptions
- **Level 2**: System boot failures, major service outages
- **Level 3**: Security incidents, data corruption, hardware failures

## 📚 Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix-Darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [SOPS Documentation](https://github.com/mozilla/sops)
- [Mobile NixOS Documentation](https://mobile.nixos.org/)

______________________________________________________________________

**Last Updated**: $(date)
**Version**: 1.0
**Maintainer**: Production Operations Team

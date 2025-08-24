# Nixible Playbooks

This directory contains Nixible playbooks for configuring remote devices using Ansible with Nix's type safety and reproducibility.

## Available Playbooks

### `remote-device-setup.nix`

A comprehensive playbook for setting up a **jailbroken iPhone** (hostname: "8AMPS") with essential development tools and configurations.

#### Target Device Configuration

- **Device**: Jailbroken iPhone "8AMPS"
- **IP Address**: `10.0.0.84`
- **Primary User**: `mobile` (fallback to `root`)
- **Package Manager**: `apt` (Debian-based packages on jailbroken iOS)

#### What it installs and configures:

**Essential Packages:**

- `neovim` - Modern vim editor with custom configuration
- `wget` & `curl` - Download utilities
- `git` - Version control system
- `zsh` - Advanced shell with Oh My Zsh
- `tmux` - Terminal multiplexer
- `htop` - Process monitor
- `tree` - Directory tree viewer
- `neofetch` - System information display
- `xterm` - Terminal emulator
- `pasteboard-utils` - Clipboard utilities (if available)
- Development tools: `python3`, `python3-pip`, `unzip`, `nano`

**Custom Configurations:**

- **Zsh setup** with Oh My Zsh for both `mobile` and `root` users
- **Neovim configuration** with sensible defaults and iPhone-specific settings
- **Custom aliases** including jailbreak-specific commands (`respring`, `safemode`)
- **Shell environment** optimized for jailbroken iOS

#### Usage

```bash
# Build the Nixible CLI
nix build .#remote-device-setup

# Run the playbook
nix run .#remote-device-setup
```

#### Prerequisites

1. **SSH Access**: Ensure SSH is enabled on your jailbroken iPhone
1. **SSH Key**: Have your SSH private key at `~/.ssh/id_ed25519`
1. **Network**: Device should be accessible at `10.0.0.84`
1. **Jailbreak**: Device must be jailbroken with apt package manager available

#### Customization

To customize for your device:

1. **Change IP Address**: Update `ansible_host` in the inventory section
1. **Change Username**: Modify `ansible_user` (typically `mobile` or `root`)
1. **Add Packages**: Extend the package lists in the apt tasks
1. **Modify Configs**: Update the shell and editor configurations as needed

#### Jailbreak-Specific Features

The playbook includes several iPhone/jailbreak-specific enhancements:

- **Respring alias**: Quick SpringBoard restart
- **Safe mode**: Emergency safe mode activation
- **iOS-themed neofetch**: Custom ASCII art for iOS
- **Proper paths**: Uses `/var/mobile/` and `/var/root/` directories
- **Lockdown restart**: Mobile device management restart command

#### Troubleshooting

**Connection Issues:**

- Verify SSH is running: `ssh mobile@10.0.0.84`
- Check if OpenSSH is installed on the jailbroken device
- Ensure the device is on the same network

**Package Installation Failures:**

- Some packages might not be available in Cydia/apt repositories
- The playbook uses `ignore_errors: true` for optional components
- Check if Cydia sources are properly configured

**Permission Issues:**

- Ensure the user has sudo privileges
- Some jailbroken devices may have different permission structures
- Try running with `root` user if `mobile` fails

**Network Connectivity:**

- Verify the device can reach external repositories
- Check if the device has internet connectivity
- Some corporate networks may block package downloads

#### Security Notes

- The playbook configures both `mobile` and `root` users
- SSH keys should be properly secured
- Consider changing default passwords after setup
- Be cautious with root access on jailbroken devices

## Adding New Playbooks

To add a new playbook:

1. Create a new `.nix` file in this directory
1. Follow the Nixible structure with `collections`, `inventory`, and `playbook` sections
1. Add the playbook to `parts/packages.nix` using `inputs.nixible.lib.mkNixibleCli`
1. Update this README with documentation

## Nixible Documentation

For more information about Nixible syntax and capabilities, visit: https://nixible.projects.tf

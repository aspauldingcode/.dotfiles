#!/usr/bin/env bash
set -euo pipefail

# Optional: pretty output
info() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

OS="$(uname)"
FLAKE_URI="github:aspauldingcode/.dotfiles"

if [[ "$OS" == "Darwin" ]]; then
    info "Detected macOS. Installing Nix via .pkg..."

    # Download and install the .pkg silently
    curl -sSfL https://install.determinate.systems/nix/nix-installer.pkg -o /tmp/nix-installer.pkg
    sudo installer -pkg /tmp/nix-installer.pkg -target /

    # Load Nix profile
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

    info "Running darwin-rebuild switch..."
    sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake "$FLAKE_URI"

elif [[ "$OS" == "Linux" ]]; then
    info "Detected Linux. Installing Nix via shell installer..."

    # Install silently with Determinate Nix Installer
    curl -sSfL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm

    # Load Nix profile
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

    # Optional: run your flake (customize as needed)
    # Example: home-manager, nixos-rebuild, etc.
    info "Running flake activation..."
    # sudo nixos-rebuild switch --flake "$FLAKE_URI"
    # OR: home-manager switch --flake "$FLAKE_URI"
    echo "Linux detected, but flake activation is left for you to customize."

else
    error "Unsupported OS: $OS"
    exit 1
fi

info "Installation complete."

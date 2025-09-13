#!/usr/bin/env bash
set -euo pipefail

# Pretty output
info() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

OS="$(uname)"
FLAKE_URI="github:aspauldingcode/.dotfiles"

if [[ "$OS" == "Darwin" ]]; then
    info "Detected macOS. Installing Nix via .pkg..."

    # ✅ Correct .pkg URL for macOS Universal installer
    curl -sSfL https://install.determinate.systems/determinate-pkg/stable/Universal -o /tmp/determinate.pkg
    sudo installer -pkg /tmp/determinate.pkg -target /

    # Load nix profile
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

    info "Running darwin-rebuild switch..."
    sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake "$FLAKE_URI"

elif [[ "$OS" == "Linux" ]]; then
    info "Detected Linux. Installing Nix via shell script..."

    curl -sSfL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm

    # Load nix profile
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

    info "Linux install complete. Customize your flake activation here if needed."
    # Example:
    # home-manager switch --flake "$FLAKE_URI"
    # sudo nixos-rebuild switch --flake "$FLAKE_URI"

else
    error "Unsupported OS: $OS"
    exit 1
fi

info "✅ Installation complete!"

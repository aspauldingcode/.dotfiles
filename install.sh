#!/bin/bash

# Detect the operating system
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS-specific installation
    echo "Detected macOS. Installing using .pkg..."
    curl -sSfL https://install.determinate.systems/nix.pkg -o /tmp/determinate.pkg && \
    sudo installer -pkg /tmp/determinate.pkg -target / && \
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake github:aspauldingcode/.dotfiles && \
    . ~/.zshrc
elif [[ "$(uname)" == "Linux" ]]; then
    # Linux-specific installation
    echo "Detected Linux. Installing with the detests installer..."
    curl -sSfL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm && \
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
    sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake github:aspauldingcode/.dotfiles && \
    . ~/.bashrc
else
    echo "Unsupported OS detected."
    exit 1
fi


#!/bin/sh

if [ $# -gt 0 ]
  then
    SCRIPT_DIR=$1
  else
    SCRIPT_DIR=~/.dotfiles
fi
export EDITOR=nvim

ARGS="--show-trace --option eval-cache false"

nix-shell -p git --command "git clone https://github.com/aspauldingcode/.dotfiles.git $SCRIPT_DIR"

sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update

# Append experimental features to configuration.nix
# Define the line to be inserted
FEATURES_LINE='  nix.settings.experimental-features = [ "nix-command" "flakes" ];'

# Define the configuration file path
CONFIG_FILE='/etc/nixos/configuration.nix'

# Check if the line is already present in the configuration file
if ! grep -q 'nix.settings.experimental-features' "$CONFIG_FILE"; then
    # Ensure that the FEATURES_LINE is placed inside the configuration block
    # Insert the line before the final closing brace
    sudo sed -i '/^}$/i\'"$FEATURES_LINE" "$CONFIG_FILE"
fi

# rebuild and upgrade too.
sudo nixos-rebuild switch --upgrade

# now, we can update the flake
nix flake update

# Generate hardware config for new system
mkdir -p $SCRIPT_DIR/system/$hostname/
sudo nixos-generate-config --show-hardware-config > $SCRIPT_DIR/system/$hostname/hardware-configuration.nix

# Copy current system config if the one in doesn't exist

sudo nixos-rebuild switch $ARGS --flake .#$hostname

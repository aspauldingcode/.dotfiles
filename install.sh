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

# Generate hardware config for new system
mkdir -p $SCRIPT_DIR/system/$hostname/
sudo nixos-generate-config --show-hardware-config > $SCRIPT_DIR/system/$hostname/hardware-configuration.nix

# Copy current system config if the one in doesn't exist

# rebuild.
sudo nixos-rebuild switch $ARGS --flake .#$hostname

#!/bin/sh

echo "uninstall Homebrew (if installed)"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
sudo rm -r /opt/homebrew/bin/ /opt/homebrew/etc/ /opt/homebrew/lib/ /opt/homebrew/share/ /opt/homebrew/var/

echo "Install Homebrew"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "source homebrew"
 (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/alex/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"

echo "uninstall nix if already installed"
/nix/nix-installer uninstall --no-confirm

echo "Install nix with flakes"
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

echo "Sourcnge nix"
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

echo "Done."

echo "Uninstall nix-darwin if installed..."
nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller
darwin-uninstaller

echo "Installing nix-darwin..."
echo "since using flakes, we will just run `darwin-rebuild switch to install nix-darwin`"
echo "As darwin-rebuild won't be installed in your PATH yet, you can use the following command: `nix run nix-darwin -- switch --flake ~/.dotfiles`"
echo -e "\n running that now..."
nix run nix-darwin -- switch --flake ~/.dotfiles

echo "now, applying changes to system with darwin-rebuild..."
nix run nix-darwin -- switch --flake ~/.dotfiles

SCRIPT_DIR=~/.dotfiles
export EDITOR=nvim

ARGS="--show-trace --option eval-cache false --experimental-features 'nix-command flakes'"

nix-shell -p git --command "git clone https://github.com/aspauldingcode/.dotfiles.git $SCRIPT_DIR"

echo "Generate hardware config for new system"
mkdir -p $SCRIPT_DIR/system/$(hostname)/
sudo nixos-generate-config --show-hardware-config > $SCRIPT_DIR/system/$(hostname)/hardware-configuration-$(hostname).nix

echo "rebuild."
sudo nixos-rebuild switch $ARGS --flake .#$(hostname)

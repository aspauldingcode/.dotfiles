#!/bin/sh

if [ "$(uname -s)" = "Darwin" ]; then
  SCRIPT_DIR=~/.dotfiles
  export EDITOR=nvim
  if [ "$(uname -m)" = "aarch64" ]; then
    HOMEBREW_LOCATION=/opt/homebrew
  else
    HOMEBREW_LOCATION=/usr/local/homebrew
  fi

  echo "install rosetta 2!"
  if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
    sudo softwareupdate --install-rosetta --agree-to-license
  else
    echo "Rosetta 2 is already installed."
  fi

  if command -v brew >/dev/null 2>&1; then
    echo "uninstall all homebrew packages if installed"
    if [ "$(brew list --formula)" ]; then
      brew uninstall --force $(brew list --formula)
    fi
    if [ "$(brew list --cask)" ]; then
      brew uninstall --cask --force $(brew list --cask)
    fi

    echo "uninstall Homebrew (if installed)"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    sudo rm -r $HOMEBREW_LOCATION/bin/ $HOMEBREW_LOCATION/etc/ $HOMEBREW_LOCATION/lib/ $HOMEBREW_LOCATION/share/ $HOMEBREW_LOCATION/var/
  else
    echo "Homebrew is not installed."
  fi

  echo "Install Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo "source homebrew"
  (echo; echo 'eval "$($HOMEBREW_LOCATION/bin/brew shellenv)"') >> ~/.zprofile
  eval "$($HOMEBREW_LOCATION/bin/brew shellenv)"

  echo "Uninstall nix-darwin if installed..."
  if command -v darwin-rebuild >/dev/null 2>&1; then
    echo "y" | sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller || echo "y" | sudo darwin-uninstaller
  else
    echo "nix-darwin is not installed."
  fi


  echo "uninstall nix if already installed"
  if command -v nix >/dev/null 2>&1; then
    sudo /nix/nix-installer uninstall --no-confirm
  else
    echo "Nix is not installed."
  fi

  echo "Install nix with flakes"
  sudo curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

  echo "Sourcing nix"
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  echo "Done."

  echo "Installing nix-darwin..."
  echo "since using flakes, we will just run darwin-rebuild switch to install nix-darwin"
  echo "As darwin-rebuild won't be installed in your PATH yet, you can use the following command: `nix run nix-darwin -- switch --flake $SCRIPT_DIR`"
  echo -e "\n running that now..."
  nix run nix-darwin -- switch --flake $SCRIPT_DIR

  echo "uninstalling previous generations"
  sudo rm /Users/$USERNAME/.local/state/nix/profiles/home-manager*
  sudo rm /Users/$USERNAME/.local/state/home-manager/gcroots/current-home
  sudo rm /Users/$USERNAME/Library/LaunchAgents/org.nix-community.home.xdg_cache_home.plist
  sudo rm /Users/$USERNAME/Library/LaunchAgents/org.nix-community.home.notificationcenter.plist

  echo "now, applying changes to system with darwin-rebuild..."
  sudo darwin-rebuild switch --flake $SCRIPT_DIR
fi

ARGS="--show-trace --option eval-cache false --experimental-features 'nix-command flakes'"

nix-shell -p git --command "git clone https://github.com/aspauldingcode/.dotfiles.git $SCRIPT_DIR"

# only if on linux
if [ "$(uname -s)" = "Linux" ]; then
  echo "Generate hardware config for new system"
  mkdir -p $SCRIPT_DIR/system/$(hostname)/
  sudo nixos-generate-config --show-hardware-config > $SCRIPT_DIR/system/$(hostname)/hardware-configuration-$(hostname).nix

  echo "rebuild."
  sudo nixos-rebuild switch $ARGS --flake $SCRIPT_DIR#$(hostname)
fi

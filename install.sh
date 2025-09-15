#!/usr/bin/env bash
set -euo pipefail

info() {
  echo "[INFO] $*"
}

error() {
  echo "[ERROR] $*" >&2
  exit 1
}

detect_os() {
  unameOut="$(uname -s)"
  case "${unameOut}" in
  Linux*) echo "linux" ;;
  Darwin*) echo "darwin" ;;
  *) error "Unsupported OS: ${unameOut}" ;;
  esac
}

is_nixos() {
  if [[ -f /etc/os-release ]]; then
    if grep -qi '^ID=nixos' /etc/os-release; then
      return 0
    fi
  fi
  return 1
}

install_mac() {
  info "Detected macOS. Installing Nix via Determinate .pkg..."

  PKG_URL="https://install.determinate.systems/determinate-pkg/stable/Universal"
  PKG_FILE="Determinate.pkg"

  info "Downloading installer package from $PKG_URL..."
  curl -L -H 'Cache-Control: no-cache' -o "$PKG_FILE" "$PKG_URL" || error "Failed to download .pkg installer."

  info "Installing package..."
  sudo installer -pkg "$PKG_FILE" -target / || error "Failed to install the package."

  info "Cleaning up installer file..."
  rm -f "$PKG_FILE"

  info "Installation complete."
}

install_linux() {
  if is_nixos; then
    info "Detected NixOS. Your Nix flake should already install Determinate Nix. Skipping installation."
    return
  fi

  info "Detected Linux. Installing Determinate Nix via official script..."

  INSTALLER_URL="https://install.determinate.systems/nix"

  info "Running installer script from $INSTALLER_URL..."
  curl -sSfL "$INSTALLER_URL" | sh -s -- install --determinate --no-confirm &&
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || error "Installation failed."

  info "Installation complete."
}

main() {
  OS=$(detect_os)
  case "$OS" in
  darwin) install_mac ;;
  linux) install_linux ;;
  *) error "Unsupported OS: $OS" ;;
  esac
}

main

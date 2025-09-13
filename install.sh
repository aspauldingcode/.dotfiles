#!/usr/bin/env bash
set -e

if [[ "$(uname)" == "Darwin" ]]; then
  echo "[INFO] Detected macOS. Installing via .pkg..."

  # Short URL for the pkg
  SHORT_URL="https://install.determinate.systems/determinate-pkg/stable/Universal"

  # Get the real URL by following the redirect, but only fetch headers first
  REAL_URL=$(curl -sI "$SHORT_URL" | awk '/^location:/ {print $2}' | tr -d '\r')

  echo "[INFO] Resolved real .pkg URL: $REAL_URL"

  TMP_PKG=$(mktemp -t determinate_pkg_XXXXXX.pkg)

  echo "[INFO] Downloading installer package..."
  curl -L --fail -o "$TMP_PKG" "$REAL_URL"

  echo "[INFO] Running installer..."
  sudo installer -pkg "$TMP_PKG" -target /

  rm -f "$TMP_PKG"
  echo "[INFO] Installation complete."

elif [[ "$(uname)" == "Linux" ]]; then
  echo "[INFO] Detected Linux. Installing via CLI..."
  curl -sSfL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm

else
  echo "[ERROR] Unsupported OS: $(uname)"
  exit 1
fi

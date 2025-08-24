#!/usr/bin/env bash
set -euo pipefail

# Smart rebuild script that automatically selects the correct theme configuration
# based on the current macOS system theme state

# Function to detect current macOS theme
detect_macos_theme() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "dark" # Default to dark on non-macOS systems
    return
  fi

  # Get current macOS theme state
  local macos_dark_mode
  macos_dark_mode=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode' 2>/dev/null || echo "true")

  if [[ $macos_dark_mode == "true" ]]; then
    echo "dark"
  else
    echo "light"
  fi
}

# Get hostname for flake configuration
hostname=$(scutil --get LocalHostName 2>/dev/null || hostname)

# Detect current theme
current_theme=$(detect_macos_theme)

echo "Detected current macOS theme: $current_theme"

# Determine which flake configuration to use
if [[ $current_theme == "light" ]]; then
  flake_config="$hostname-light"
else
  flake_config="$hostname"
fi

echo "Using flake configuration: $flake_config"

# Pass through all arguments to darwin-rebuild, but use the detected configuration
if [[ $# -eq 0 ]]; then
  # Default to switch if no arguments provided
  sudo darwin-rebuild switch --flake ~/.dotfiles#"$flake_config"
else
  # Check if --flake is already specified in arguments
  if [[ $* == *"--flake"* ]]; then
    echo "Warning: --flake argument detected. Using provided configuration instead of auto-detected theme."
    sudo darwin-rebuild "$@"
  else
    # Add the flake configuration to the arguments
    sudo darwin-rebuild "$@" --flake ~/.dotfiles#"$flake_config"
  fi
fi

echo "✓ Smart rebuild completed with $current_theme theme"

#!/usr/bin/env bash

# Builds a macOS .pkg installer for the dotfiles configuration

set -e

PKG_NAME="DotfilesInstaller.pkg"
IDENTIFIER="com.aspauldingcode.dotfiles"
BUILD_DIR="$(mktemp -d)"

echo "Creating payload package in $BUILD_DIR..."

# Create a scripts directory for the pkgbuild
mkdir -p "$BUILD_DIR/scripts"

# The postinstall script runs automatically when the user double-clicks the .pkg
cat << 'EOF' > "$BUILD_DIR/scripts/postinstall"
#!/usr/bin/env bash
set -e

# The postinstall script is run as root by Installer.app
# Let's find the user logged into the GUI console
LOGGED_IN_USER=$(stat -f "%Su" /dev/console)
USER_HOME=$(eval echo "~$LOGGED_IN_USER")

# Log output to a file on the user's desktop for debugging
LOG_FILE="$USER_HOME/Desktop/dotfiles_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting dotfiles installation at $(date)"
echo "Target user: $LOGGED_IN_USER"

# Run the installation as the user to ensure it goes into their home folder properly
sudo -u "$LOGGED_IN_USER" -H bash -c "
  set -e
  export PATH=\"/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin\"

  if [ ! -d \"\$HOME/.dotfiles\" ]; then
    echo 'Cloning .dotfiles repository...'
    git clone https://github.com/aspauldingcode/.dotfiles.git \"\$HOME/.dotfiles\"
  fi

  cd \"\$HOME/.dotfiles\"
  git checkout development || true
  git pull || true

  echo 'Running install-mac.sh...'
  ./install-mac.sh
"

echo "Installation finished successfully at $(date)"
EOF

chmod +x "$BUILD_DIR/scripts/postinstall"

echo "Building $PKG_NAME..."
pkgbuild --identifier "$IDENTIFIER" --version "1.0" --nopayload --scripts "$BUILD_DIR/scripts" "$PKG_NAME"

# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "Done! You can now distribute '$PKG_NAME'."
echo "Double-clicking it will run the install-mac.sh script in the background."

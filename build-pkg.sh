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

# To ensure the script is run with the right permissions and context
# Usually postinstall runs as root, so we need to run Nix as the user who installed it
USER_HOME=$(eval echo "~$USER")

echo "Running installation payload..."

# Remote execution of the simplified installation script
sudo -u "$USER" bash -c "bash <(curl -sL https://raw.githubusercontent.com/aspauldingcode/.dotfiles/development/install-mac.sh)"
EOF

chmod +x "$BUILD_DIR/scripts/postinstall"

echo "Building $PKG_NAME..."
pkgbuild --identifier "$IDENTIFIER" --version "1.0" --nopayload --scripts "$BUILD_DIR/scripts" "$PKG_NAME"

# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "Done! You can now distribute '$PKG_NAME'."
echo "Double-clicking it will run the install-mac.sh script in the background."

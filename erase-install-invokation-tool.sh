#!/bin/bash

# example: sudo ./erase-install-invokation-tool.sh --version=14.4.1 --erase

ERASE_INSTALL_PATH="/Library/Management/erase-install/erase-install.sh"

# Check if erase-install.sh exists
if [ ! -f "$ERASE_INSTALL_PATH" ]; then
    echo "Error: erase-install.sh not found at $ERASE_INSTALL_PATH"
    echo "Please run erase-installer-fetcher.sh first and install the downloaded pkg manually."
    exit 1
fi

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo privileges"
    echo "Please run: sudo $0 $*"
    exit 1
fi

# Function to display usage
show_usage() {
    echo "Usage: sudo $0 [OPTION]"
    echo "Options:"
    echo "  --list                 Show available macOS versions"
    echo "  --download            Just download latest macOS installer"
    echo "  --reinstall           Download and upgrade to newer macOS"
    echo "  --erase               Erase and reinstall macOS (WARNING: Will wipe system!)"
    echo "  --version=XX.XX       Download specific macOS version"
    echo "  --help               Show this help message"
    echo ""
    echo "Example: sudo $0 --reinstall"
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Process arguments
case "$1" in
    --help)
        show_usage
        ;;
    --list|--download|--reinstall|--erase|--version=*)
        echo "Executing: sudo $ERASE_INSTALL_PATH $*"
        sudo "$ERASE_INSTALL_PATH" "$@"
        ;;
    *)
        echo "Error: Unknown option $1"
        show_usage
        exit 1
        ;;
esac

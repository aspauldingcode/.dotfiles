#!/bin/bash

# Exit on any error
set -e

# PATHS
SYSTEM_VOLUME_IDENTIFIER=$(diskutil list | grep "Macintosh HD" | awk '{print $NF}')
MOUNTPOINT_DIR="$HOME/MountPoints/Macintosh HD"

DOCK_RESOURCES_PATH="System/Library/CoreServices/Dock.app/Contents/Resources"
PLIST_PATH="$MOUNTPOINT_DIR/$DOCK_RESOURCES_PATH/DockMenus.plist"

PlistBuddy=/usr/libexec/PlistBuddy

echo "System volume identifier: $SYSTEM_VOLUME_IDENTIFIER"

# Create mount point directory if it doesn't exist
mkdir -p "$MOUNTPOINT_DIR"

# Check if already mounted
if mount | grep -q "$MOUNTPOINT_DIR"; then
    echo "Volume already mounted at $MOUNTPOINT_DIR"
else
    echo "Mounting system volume with read-write access..."
    # First try to unmount if it's mounted elsewhere
    sudo diskutil unmount "/dev/$SYSTEM_VOLUME_IDENTIFIER" 2>/dev/null || true
    # Mount the system volume with read-write access
    sudo mount -o nobrowse,rw -t apfs "/dev/$SYSTEM_VOLUME_IDENTIFIER" "$MOUNTPOINT_DIR"
fi

# Verify the mount was successful
if [ ! -d "$MOUNTPOINT_DIR/$DOCK_RESOURCES_PATH" ]; then
    echo "Error: Could not access Dock resources at $MOUNTPOINT_DIR/$DOCK_RESOURCES_PATH"
    echo "Available directories in mount point:"
    ls -la "$MOUNTPOINT_DIR/" 2>/dev/null || echo "Mount point is empty or inaccessible"
    exit 1
fi

echo "Successfully mounted. Proceeding with modifications..."

# 2 - Backup DockMenus.plist
echo "Creating backup of DockMenus.plist..."
sudo cp "$MOUNTPOINT_DIR/$DOCK_RESOURCES_PATH/DockMenus.plist" "$MOUNTPOINT_DIR/$DOCK_RESOURCES_PATH/DockMenus.BACKUP.plist"

# 3 - Modify the plist
echo "Modifying DockMenus.plist..."

# Check if entries already exist and delete them first
echo "Checking for existing entries..."
sudo $PlistBuddy -c "Delete 'finder-running':2:sub" "$PLIST_PATH" 2>/dev/null || true
sudo $PlistBuddy -c "Delete 'trash':1" "$PLIST_PATH" 2>/dev/null || true

echo "Adding new entries..."
sudo $PlistBuddy    -c "Add 'finder-running':2:sub Dict" \
                    -c "Add 'finder-running':2:sub:0:command integer 1004" \
                    -c "Add 'finder-running':2:sub:0:name string REMOVE_FROM_DOCK" \
                    -c "Add 'trash':1 Dict" \
                    -c "Add 'trash':1:0:command integer 1004" \
                    -c "Add 'trash':1:0:name string REMOVE_FROM_DOCK" "$PLIST_PATH"

# 4 - Repair file ownership
echo "Repairing file ownership..."
sudo chown root:wheel "$MOUNTPOINT_DIR/$DOCK_RESOURCES_PATH/DockMenus.plist"

# 5 - Create a new system snapshot (required for sealed system volumes)
echo "Creating new system snapshot..."
sudo bless --mount "$MOUNTPOINT_DIR" --bootefi --create-snapshot

# 6 - Unmount the system volume
echo "Unmounting system volume..."
sudo umount "$MOUNTPOINT_DIR"

echo "Script completed successfully!"
echo "You may need to restart your Mac for changes to take effect."

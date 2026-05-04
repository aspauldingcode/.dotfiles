#!/bin/bash

# Configuration
VSOCK_SOCKET="/Users/8amps/.dotfiles/dendritic-vm-vsock.sock"
WAYPIPE_SOCKET="/tmp/waypipe-wawona.sock"
WAWONA_RUNTIME="/tmp/wawona-503"
WAYPIPE_BIN="/nix/store/vnilw5d3406zb209j4x66hw8w27xanlh-wawona-macos/Applications/Wawona.app/Contents/MacOS/waypipe"

# Kill existing bridge processes
killall waypipe socat 2>/dev/null
rm -f "$WAYPIPE_SOCKET"

# Ensure Wawona runtime exists
if [ ! -d "$WAWONA_RUNTIME" ]; then
    echo "Error: Wawona runtime directory $WAWONA_RUNTIME not found. Is Wawona running?"
    exit 1
fi

# Start waypipe client listening on a separate socket
echo "Starting waypipe client..."
export XDG_RUNTIME_DIR="$WAWONA_RUNTIME"
export WAYLAND_DISPLAY="wayland-0"
$WAYPIPE_BIN --socket "$WAYPIPE_SOCKET" client &

# Wait for waypipe to start
sleep 1

# Bridge the vfkit vsock socket to the waypipe socket
echo "Bridging vsock socket to waypipe..."
if [ -S "$VSOCK_SOCKET" ]; then
    socat UNIX-CONNECT:"$VSOCK_SOCKET" UNIX-CONNECT:"$WAYPIPE_SOCKET" &
    echo "Bridge established. Sway should now appear in Wawona."
else
    echo "Warning: $VSOCK_SOCKET not found. Please start the MicroVM first."
    echo "Once the VM starts, run: socat UNIX-CONNECT:$VSOCK_SOCKET UNIX-CONNECT:$WAYPIPE_SOCKET &"
fi

wait

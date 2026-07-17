#!/usr/bin/env bash
# Stage keyboard-backlight RE capture scripts onto the Windows volume.
set -euo pipefail

MOUNT="${DENDRITIC_WINDOWS_MOUNT:-/mnt/windows}"
SRC_DIR="${DENDRITIC_KBD_RE_SCRIPTS:?}"

log() { echo "dendritic-windows-stage-kbd-re: $*"; }

[[ -d $MOUNT/Windows ]] || {
  log "Windows volume not ready — skip"
  exit 0
}

mkdir -p "$MOUNT/dendritic/re"
cp -f "$SRC_DIR/list-hid.ps1" "$MOUNT/dendritic/re/list-hid.ps1"
cp -f "$SRC_DIR/README-CAPTURE.txt" "$MOUNT/dendritic/re/README-CAPTURE.txt"
# PROTOCOL/CAPTURE are markdown in the flake; drop short pointer.
cat >"$MOUNT/dendritic/re/OPEN-ME.txt" <<'EOF'
Keyboard backlight reverse-engineering capture kit.

1. Ensure SteelSeries Engine backlight works.
2. Run: powershell -ExecutionPolicy Bypass -File C:\dendritic\re\list-hid.ps1
3. USBPcap while toggling Fn backlight — see flake docs/re/sword-kbd-bl/CAPTURE.md
4. Never write EC registers.

Linux will not light the keys until HID capture is done (EC 0xd3 writes hang this Sword).
EOF
log "staged capture kit under $MOUNT/dendritic/re/"

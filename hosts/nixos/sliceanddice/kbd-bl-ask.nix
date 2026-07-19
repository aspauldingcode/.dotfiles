# Yes/No GUI for interactive keyboard-backlight probe cycles.
# Usage: dendritic-kbd-bl-ask "Cycle N" "What to do / what we just did"
#
# SAFETY: this helper is UI only. It must never write EC registers.
# On Sword 15 A11UD, EC writes to 0xd3 / 0xf3 / kbd mode have hard-hung the EC.
{
  pkgs,
}:
pkgs.writeShellApplication {
  name = "dendritic-kbd-bl-ask";
  runtimeInputs = [
    pkgs.zenity
    pkgs.coreutils
  ];
  text = ''
    set -euo pipefail

    cycle="''${1:-Cycle}"
    detail="''${2:-Was the keyboard backlit (any glow, even dim/brief)?}"
    out="''${DENDRITIC_KBD_BL_ANSWER_FILE:-/tmp/dendritic-kbd-bl-answer}"

    # Prefer the live niri Wayland session when launched from SSH/agent.
    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      if [ -S "''${XDG_RUNTIME_DIR:-/run/user/1000}/wayland-1" ]; then
        export WAYLAND_DISPLAY=wayland-1
      elif [ -S "''${XDG_RUNTIME_DIR:-/run/user/1000}/wayland-0" ]; then
        export WAYLAND_DISPLAY=wayland-0
      fi
    fi
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/1000}"
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

    rm -f "$out"

    if zenity --question \
      --title="Keyboard backlight — $cycle" \
      --width=480 \
      --ok-label="Yes — lit" \
      --cancel-label="No — dark" \
      --text="<b>$cycle</b>\n\n$detail\n\nClick <b>Yes — lit</b> if any backlight appeared.\nClick <b>No — dark</b> if the keys stayed dark."; then
      echo yes >"$out"
      echo "yes"
      exit 0
    else
      echo no >"$out"
      echo "no"
      exit 1
    fi
  '';
}

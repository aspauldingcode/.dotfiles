#!/usr/bin/env bash
# Sync declarative Windows driver tree onto C: and wininstall; arm one-shot
# pnputil apply for the current install.
set -euo pipefail

MOUNT="${DENDRITIC_WINDOWS_MOUNT:-/mnt/windows}"
INSTALL_MOUNT="${DENDRITIC_WINDOWS_INSTALL_MOUNT:-/mnt/wininstall}"
DRIVERS_SRC="${DENDRITIC_WINDOWS_DRIVERS_SRC:?}"
STATE_DIR="${DENDRITIC_WINDOWS_STATE:-/var/lib/dendritic-windows}"
EXTRA_DIR="${DENDRITIC_WINDOWS_DRIVERS_EXTRA:-/var/cache/dendritic-windows/drivers-extra}"
MARKER="$STATE_DIR/drivers-stage.stamp"

log() { echo "dendritic-windows-stage-drivers: $*"; }
die() {
  echo "dendritic-windows-stage-drivers: ERROR: $*" >&2
  exit 1
}

[[ -d $DRIVERS_SRC ]] || die "drivers src missing: $DRIVERS_SRC"

stamp_src="$(find "$DRIVERS_SRC" -type f -printf '%P\t%s\t%T@\n' 2>/dev/null | sort | sha256sum | awk '{print $1}')"
if [[ -d $EXTRA_DIR ]]; then
  stamp_extra="$(find "$EXTRA_DIR" -type f -printf '%P\t%s\t%T@\n' 2>/dev/null | sort | sha256sum | awk '{print $1}')"
else
  stamp_extra=none
fi
stamp="${stamp_src}:${stamp_extra}"

sync_tree() {
  local dest=$1
  mkdir -p "$dest"
  rsync -a --delete --exclude '.git' "$DRIVERS_SRC/" "$dest/"
  if [[ -d $EXTRA_DIR ]]; then
    rsync -a "$EXTRA_DIR/" "$dest/extra/"
  fi
}

staged=0
if [[ -d $MOUNT/Windows ]]; then
  sync_tree "$MOUNT/dendritic-drivers"
  mkdir -p "$MOUNT/dendritic"
  cat >"$MOUNT/dendritic/apply-drivers.cmd" <<'EOF'
@echo off
setlocal EnableExtensions
set "LOG=C:\dendritic\apply-drivers.log"
echo dendritic apply-drivers %DATE% %TIME%> "%LOG%"
if not exist "C:\dendritic-drivers" (
  echo missing C:\dendritic-drivers>> "%LOG%"
  exit /b 1
)
pnputil /add-driver C:\dendritic-drivers\*.inf /subdirs /install >> "%LOG%" 2>&1
echo pnputil exit=%ERRORLEVEL%>> "%LOG%"
REM SteelSeries Engine (keyboard backlight) — NSIS silent
for /r "C:\dendritic-drivers" %%F in (*Setup*.exe) do (
  echo silent-install %%F>> "%LOG%"
  start /wait "" "%%F" /S >> "%LOG%" 2>&1
)
echo apply-drivers done>> "%LOG%"
del /f /q "%~f0" >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v DendriticApplyDrivers /f >nul 2>&1
endlocal
EOF
  startup="$MOUNT/ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp"
  mkdir -p "$startup"
  # Always refresh Startup when stamp changes; also force if steelseries tree appears.
  if [[ ! -f $MARKER ]] || [[ $(cat "$MARKER" 2>/dev/null || true) != "$stamp" ]]; then
    cat >"$startup/dendritic-apply-drivers.cmd" <<'EOF'
@echo off
call C:\dendritic\apply-drivers.cmd
del /f /q "%~f0" >nul 2>&1
EOF
    staged=1
    log "staged driver tree + Startup apply on $MOUNT"
  else
    log "driver tree on $MOUNT already current"
  fi
else
  log "Windows volume not ready at $MOUNT — skip C: stage"
fi

# wininstall: keep packs for future Setup / FirstLogon (copy to C: during OOBE).
if [[ -d $INSTALL_MOUNT/sources ]] || [[ -f $INSTALL_MOUNT/setup.exe ]]; then
  # Mount may be RO; try rw remount via separate path under /run.
  dest_install="$INSTALL_MOUNT/dendritic-drivers"
  if mkdir -p "$dest_install" 2>/dev/null && [[ -w $dest_install || -w $INSTALL_MOUNT ]]; then
    sync_tree "$dest_install"
    mkdir -p "$INSTALL_MOUNT/dendritic"
    cp -f "$MOUNT/dendritic/apply-drivers.cmd" "$INSTALL_MOUNT/dendritic/apply-drivers.cmd" 2>/dev/null ||
      cat >"$INSTALL_MOUNT/dendritic/apply-drivers.cmd" <<'EOF'
@echo off
setlocal
if exist X:\dendritic-drivers (
  if not exist C:\dendritic-drivers mkdir C:\dendritic-drivers
  xcopy /E /I /Y X:\dendritic-drivers C:\dendritic-drivers\ >nul
)
call C:\dendritic\apply-drivers.cmd
endlocal
EOF
    log "staged driver tree on wininstall"
  else
    # RO fuse mount: stage via /run then instruct bootstrap; try ntfs3 remount.
    tmp=/run/dendritic-wininstall-drivers
    mkdir -p "$tmp"
    sync_tree "$tmp/dendritic-drivers"
    if mountpoint -q "$INSTALL_MOUNT"; then
      install_dev="$(findmnt -n -o SOURCE --target "$INSTALL_MOUNT" || true)"
      if [[ -n $install_dev ]]; then
        umount "$INSTALL_MOUNT" 2>/dev/null || true
        mkdir -p "$INSTALL_MOUNT"
        if mount -t ntfs3 -o rw,uid=0,gid=0 "$install_dev" "$INSTALL_MOUNT" 2>/dev/null ||
          mount -t ntfs-3g -o rw,uid=0,gid=0 "$install_dev" "$INSTALL_MOUNT" 2>/dev/null; then
          sync_tree "$INSTALL_MOUNT/dendritic-drivers"
          mkdir -p "$INSTALL_MOUNT/dendritic"
          cp -a "$tmp/dendritic-drivers/../dendritic" "$INSTALL_MOUNT/" 2>/dev/null || true
          cat >"$INSTALL_MOUNT/dendritic/apply-drivers.cmd" <<'EOF'
@echo off
setlocal
if exist X:\dendritic-drivers xcopy /E /I /Y X:\dendritic-drivers C:\dendritic-drivers\ >nul
pnputil /add-driver C:\dendritic-drivers\*.inf /subdirs /install
endlocal
EOF
          log "remounted wininstall rw and staged drivers"
        else
          log "WARN: could not remount wininstall rw — drivers only on C: if staged"
        fi
      fi
    fi
  fi
else
  log "wininstall media not populated — skip install-media stage"
fi

mkdir -p "$STATE_DIR"
printf '%s\n' "$stamp" >"$MARKER"
[[ $staged -eq 1 ]] || true
log "done"

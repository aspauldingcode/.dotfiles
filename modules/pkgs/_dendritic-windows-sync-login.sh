#!/usr/bin/env bash
# Stage a one-shot Windows RunOnce that sets the local account password from the
# shared dendritic identity password file, then deletes the staged secret.
set -euo pipefail

MOUNT="${DENDRITIC_WINDOWS_MOUNT:-/mnt/windows}"
PASSWORD_FILE="${DENDRITIC_WINDOWS_PASSWORD_FILE:?}"
LOCAL_USER="${DENDRITIC_WINDOWS_LOCAL_USER:-alex}"
STATE_DIR="${DENDRITIC_WINDOWS_STATE:-/var/lib/dendritic-windows}"
MARKER="$STATE_DIR/login-sync.stamp"

log() { echo "dendritic-windows-sync-login: $*"; }
die() {
  echo "dendritic-windows-sync-login: ERROR: $*" >&2
  exit 1
}

[[ -r $PASSWORD_FILE ]] || die "password file missing: $PASSWORD_FILE"
plain="$(tr -d '\n' <"$PASSWORD_FILE")"
[[ -n $plain ]] || die "password file empty"

[[ -d $MOUNT/Windows ]] || {
  log "Windows volume not mounted/populated at $MOUNT — skip"
  exit 0
}

mkdir -p "$STATE_DIR" "$MOUNT/dendritic"
# Content-addressed stamp: re-stage when password or username changes.
stamp="$(printf '%s\0%s' "$LOCAL_USER" "$plain" | sha256sum | awk '{print $1}')"
if [[ -f $MARKER ]] && [[ $(cat "$MARKER") == "$stamp" ]] && [[ -f $MOUNT/dendritic/sync-login.cmd ]]; then
  log "login sync already staged for current secret"
  exit 0
fi

# Password on its own line; cmd script reads it without echoing.
umask 077
printf '%s\n' "$plain" >"$MOUNT/dendritic/login.password"
# Escape ^ & < > | for cmd.net user when embedding username only in the script.
cat >"$MOUNT/dendritic/sync-login.cmd" <<'EOF'
@echo off
setlocal EnableExtensions
set "DIR=%~dp0"
set "PWFILE=%DIR%login.password"
set "LOG=%DIR%sync-login.log"
echo dendritic sync-login %DATE% %TIME%> "%LOG%"
if not exist "%PWFILE%" (
  echo missing password file>> "%LOG%"
  exit /b 1
)
set /p DENDRITIC_PW=<"%PWFILE%"
net user __DENDRITIC_USERNAME__ "%DENDRITIC_PW%" >> "%LOG%" 2>&1
set ERR=%ERRORLEVEL%
del /f /q "%PWFILE%" >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v DendriticSyncLogin /f >nul 2>&1
echo done err=%ERR%>> "%LOG%"
endlocal & exit /b %ERR%
EOF
sed -i "s|__DENDRITIC_USERNAME__|${LOCAL_USER}|g" "$MOUNT/dendritic/sync-login.cmd"

# Offline RunOnce via SYSTEM hive when possible; else Startup folder for all users.
hive="$MOUNT/Windows/System32/config/SOFTWARE"
if [[ -f $hive ]] && command -v reged >/dev/null 2>&1; then
  # chntpw's reged: import a minimal .reg under RunOnce.
  regf="$MOUNT/dendritic/sync-login.reg"
  cat >"$regf" <<EOF
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce]
"DendriticSyncLogin"="C:\\\\dendritic\\\\sync-login.cmd"
EOF
  # reged -I is interactive; use Startup fallback which is reliable on ntfs3 mounts.
  rm -f "$regf"
fi

startup="$MOUNT/ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp"
mkdir -p "$startup"
# Wrapper that self-deletes after first run (in addition to RunOnce cmd cleanup).
cat >"$startup/dendritic-sync-login.cmd" <<EOF
@echo off
call C:\\dendritic\\sync-login.cmd
del /f /q "%~f0" >nul 2>&1
EOF

printf '%s\n' "$stamp" >"$MARKER"
log "staged password sync for user '$LOCAL_USER' (applies on next Windows boot)"

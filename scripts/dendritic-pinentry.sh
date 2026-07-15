#!/usr/bin/env bash
# Assuan pinentry that NEVER shows a GUI / TTY prompt.
#
# Serves the GPG passphrase from sops-materialized files only
# (DENDRITIC_GPG_PASSPHRASE_FILE[+_PREVIOUS]). This closes the
# pinentry-mac → Keychain loop that asked humans for a passphrase
# they are not supposed to know.
#
# Protocol: https://www.gnupg.org/documentation/manuals/assuan/
set -euo pipefail

percent_encode() {
  # Assuan D-line: escape %, CR, LF.
  local s=$1 out= c hex
  local i
  for ((i = 0; i < ${#s}; i++)); do
    c=${s:i:1}
    case "$c" in
    %) out+='%25' ;;
    $'\r') out+='%0D' ;;
    $'\n') out+='%0A' ;;
    *) out+="$c" ;;
    esac
  done
  printf '%s' "$out"
}

read_pp() {
  local f=$1
  [[ -n $f && -r $f ]] || return 1
  local pp
  pp=$(tr -d '\r\n' <"$f")
  [[ -n $pp && $pp != placeholder ]] || return 1
  printf '%s' "$pp"
}

get_passphrase() {
  local pp
  if pp=$(read_pp "${DENDRITIC_GPG_PASSPHRASE_FILE:-}"); then
    printf '%s' "$pp"
    return 0
  fi
  if pp=$(read_pp "${DENDRITIC_GPG_PASSPHRASE_PREVIOUS_FILE:-}"); then
    printf '%s' "$pp"
    return 0
  fi
  return 1
}

printf 'OK Pleased to meet you\n'

while IFS= read -r line || [[ -n ${line:-} ]]; do
  # Trim CR from Assuan lines.
  line=${line%$'\r'}
  cmd=${line%% *}
  case "$cmd" in
  GETPIN)
    if pp=$(get_passphrase); then
      printf 'D %s\n' "$(percent_encode "$pp")"
      printf 'OK\n'
    else
      # 0x5000005 = "cancelled" / no pin — fail closed, no UI.
      printf 'ERR 83886179 No sops gpg_passphrase available\n'
    fi
    ;;
  BYE)
    printf 'OK closing connection\n'
    exit 0
    ;;
  NOP | OPTION | SETDESC | SETPROMPT | SETKEYINFO | SETTITLE | SETOK | SETCANCEL | SETNOTOK | SETERROR | SETTIMEOUT | RESET | GETINFO | CONFIRM | MESSAGE)
    printf 'OK\n'
    ;;
  *)
    # Unknown: acknowledge so gpg-agent does not stall.
    printf 'OK\n'
    ;;
  esac
done

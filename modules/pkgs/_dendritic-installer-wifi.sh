#!/usr/bin/env bash
# Apply vault Wi-Fi PSKs on sliceanddice-installer (NetworkManager + iwd).
set -euo pipefail

VAULT_WIFI="${DENDRITIC_VAULT_WIFI:-/vault/wifi}"
NETWORKS_JSON="${DENDRITIC_WIFI_NETWORKS_JSON:-$VAULT_WIFI/networks.json}"

log() { echo "dendritic-installer-wifi: $*"; }

rfkill unblock wifi 2>/dev/null || true
nmcli radio wifi on 2>/dev/null || true

[[ -f $NETWORKS_JSON ]] || {
  log "no $NETWORKS_JSON — use nmtui, or vault-sync wifi from main OS"
  exit 0
}
[[ -d $VAULT_WIFI ]] || {
  log "no $VAULT_WIFI"
  exit 0
}

command -v jq >/dev/null || {
  log "jq missing"
  exit 1
}
command -v nmcli >/dev/null || {
  log "nmcli missing"
  exit 1
}

count="$(jq 'length' "$NETWORKS_JSON")"
i=0
while [[ $i -lt $count ]]; do
  ssid="$(jq -r ".[$i].ssid" "$NETWORKS_JSON")"
  pass_key="$(jq -r ".[$i].passKey" "$NETWORKS_JSON")"
  uuid="$(jq -r ".[$i].uuid // empty" "$NETWORKS_JSON")"
  key_mgmt="$(jq -r ".[$i].keyMgmt // \"wpa-psk\"" "$NETWORKS_JSON")"
  prio="$(jq -r ".[$i].autoconnectPriority // 50" "$NETWORKS_JSON")"
  i=$((i + 1))

  [[ -n $ssid && $ssid != null ]] || continue
  psk_file="$VAULT_WIFI/${pass_key}.psk"
  if [[ ! -f $psk_file ]]; then
    log "skip $ssid — missing $psk_file"
    continue
  fi
  psk="$(tr -d '\n' <"$psk_file")"
  [[ -n $psk ]] || continue

  if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$ssid"; then
    if [[ $key_mgmt == "none" ]]; then
      nmcli connection modify "$ssid" \
        connection.autoconnect yes \
        connection.autoconnect-priority "$prio" \
        wifi-sec.key-mgmt none || true
    else
      nmcli connection modify "$ssid" \
        connection.autoconnect yes \
        connection.autoconnect-priority "$prio" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$psk" \
        wifi-sec.psk-flags 0 || true
    fi
    log "updated $ssid"
  else
    add_args=(
      connection add type wifi con-name "$ssid" ifname '*' ssid "$ssid"
      connection.autoconnect yes
      connection.autoconnect-priority "$prio"
    )
    if [[ -n $uuid ]]; then
      add_args+=(connection.uuid "$uuid")
    fi
    if [[ $key_mgmt == "none" ]]; then
      add_args+=(wifi-sec.key-mgmt none)
    else
      add_args+=(
        wifi-sec.key-mgmt wpa-psk
        wifi-sec.psk "$psk"
        wifi-sec.psk-flags 0
      )
    fi
    nmcli "${add_args[@]}" >/dev/null
    log "added $ssid"
  fi
done

nmcli connection reload || true
if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq Bubbles; then
  nmcli connection up Bubbles >/dev/null 2>&1 || true
fi
log "done"

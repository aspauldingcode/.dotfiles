#!/usr/bin/env bash
# Two-phase GPG rotation for pass + sops (Alex-only).
#
#   pass-rotate-gpg.sh              # Phase 1: dual-encrypt with new key
#   pass-rotate-gpg.sh --finalize   # Phase 2: drop old key
#   pass-rotate-gpg.sh --status
set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SOPS_FILE="${SOPS_FILE:-$DOTFILES_ROOT/secrets/secrets.yaml}"
PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
STATE_FILE="${STATE_FILE:-$DOTFILES_ROOT/docs/pass-rotation-state.json}"
CI_GPG_ID_FILE="${CI_GPG_ID_FILE:-$PASSWORD_STORE_DIR/.ci-gpg-id}"
GPG_NAME="${GPG_NAME:-Alex Spaulding}"
GPG_EMAIL="${GPG_EMAIL:-alex@aspauldingcode.com}"
GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"

export PASSWORD_STORE_DIR GNUPGHOME

die() {
  echo "error: $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }
json_str() { python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

need gpg
need pass
need sops
need openssl
need git
need python3

cd "$DOTFILES_ROOT"
MODE="${1:-}"

current_fpr() {
  if [[ -f $STATE_FILE ]]; then
    python3 -c "import json; print(json.load(open('$STATE_FILE')).get('fingerprint',''))"
  elif [[ -f "$PASSWORD_STORE_DIR/.gpg-id" ]]; then
    head -n1 "$PASSWORD_STORE_DIR/.gpg-id"
  else
    echo ""
  fi
}

status() {
  local fpr pending gen
  fpr="$(current_fpr)"
  pending=false
  gen=""
  if [[ -f $STATE_FILE ]]; then
    pending="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('pending_finalize', False))")"
    gen="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('generated_at',''))")"
  fi
  echo "fingerprint:       ${fpr:-unknown}"
  echo "generated_at:      ${gen:-unknown}"
  echo "pending_finalize:  $pending"
  if [[ -f $CI_GPG_ID_FILE ]]; then
    echo "ci_gpg_id:         $(tr -d '[:space:]' <"$CI_GPG_ID_FILE")"
  fi
}

write_state() {
  local fpr="$1" pending="$2" old="${3:-}"
  python3 - <<PY
import json
from pathlib import Path
from datetime import datetime, timezone
Path("$STATE_FILE").parent.mkdir(parents=True, exist_ok=True)
data = {
  "fingerprint": "$fpr",
  "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "pending_finalize": $pending,
}
old = "$old"
if old:
  data["previous_fingerprint"] = old
Path("$STATE_FILE").write_text(json.dumps(data, indent=2) + "\n")
PY
  printf '%s\n' "$fpr" >"$DOTFILES_ROOT/docs/pass-gpg-fingerprint.txt"
}

reencrypt_all() {
  # Re-encrypt every entry according to current .gpg-id recipients.
  local entry
  while IFS= read -r -d '' entry; do
    local rel="${entry#"$PASSWORD_STORE_DIR"/}"
    rel="${rel%.gpg}"
    echo "reencrypt: $rel"
    pass continue "$rel" </dev/null 2>/dev/null || pass show "$rel" >/dev/null
  done < <(find "$PASSWORD_STORE_DIR" -type f -name '*.gpg' ! -path '*/.git/*' -print0)

  # pass doesn't always reencrypt on show; force via init rewrite:
  # decrypt + encrypt using `gpg` recipients from .gpg-id
  local ids=()
  while read -r id; do
    [[ -n $id ]] && ids+=("$id")
  done <"$PASSWORD_STORE_DIR/.gpg-id"

  while IFS= read -r -d '' entry; do
    local plain tmp
    plain="$(mktemp)"
    tmp="$(mktemp)"
    if gpg --batch --quiet --decrypt "$entry" >"$plain" 2>/dev/null; then
      local args=()
      for id in "${ids[@]}"; do
        args+=(--recipient "$id")
      done
      # Also dual-encrypt reserved test paths to CI key when present.
      local rel="${entry#"$PASSWORD_STORE_DIR"/}"
      if [[ -f $CI_GPG_ID_FILE ]] && {
        [[ $rel == _bootstrap/* || $rel == test/* ]] ||
          [[ $rel == secretspec/shared/default/DEMO_* ]]
      }; then
        args+=(--recipient "$(tr -d '[:space:]' <"$CI_GPG_ID_FILE")")
      fi
      gpg --batch --yes --trust-model always --encrypt "${args[@]}" --output "$tmp" "$plain"
      mv "$tmp" "$entry"
    fi
    rm -f "$plain" "$tmp"
  done < <(find "$PASSWORD_STORE_DIR" -type f -name '*.gpg' ! -path '*/.git/*' -print0)
}

preset_passphrase() {
  local pp="$1"
  local preset
  preset="$(command -v gpg-preset-passphrase || true)"
  if [[ -z $preset ]]; then
    for c in /opt/homebrew/libexec/gpg-preset-passphrase \
      "$(dirname "$(command -v gpg)")/../libexec/gpg-preset-passphrase" \
      /run/current-system/sw/libexec/gpg-preset-passphrase; do
      [[ -x $c ]] && preset="$c" && break
    done
  fi
  [[ -n $preset ]] || return 0
  gpg --batch --with-colons --with-keygrip --list-secret-keys 2>/dev/null |
    awk -F: '/^grp:/ { print $10 }' |
    while read -r grip; do
      [[ -n $grip ]] || continue
      printf '%s' "$pp" | "$preset" --preset "$grip" 2>/dev/null || true
    done
}

phase1() {
  local old_fpr new_fpr
  old_fpr="$(current_fpr)"
  [[ -n $old_fpr ]] || die "no current fingerprint; run pass-genesis first"
  [[ -d $PASSWORD_STORE_DIR ]] || die "missing password store at $PASSWORD_STORE_DIR"

  local pending
  pending="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('pending_finalize', False))" 2>/dev/null || echo false)"
  if [[ $pending == "True" || $pending == "true" ]]; then
    die "rotation already pending finalize; run with --finalize first"
  fi

  echo "Phase 1: generating new GPG key (keeping $old_fpr during grace)..."
  local passphrase batch key_export
  passphrase="$(openssl rand -base64 32 | tr -d '\n')"
  batch="$(mktemp)"
  key_export="$(mktemp)"
  trap 'rm -f "$batch" "$key_export"' RETURN

  cat >"$batch" <<EOF
%echo Generating rotated Alex Spaulding pass key
Key-Type: eddsa
Key-Curve: Ed25519
Subkey-Type: ecdh
Subkey-Curve: Curve25519
Name-Real: ${GPG_NAME}
Name-Email: ${GPG_EMAIL}
Expire-Date: 0
Passphrase: ${passphrase}
%commit
%echo done
EOF
  gpg --batch --generate-key "$batch"
  new_fpr="$(gpg --batch --with-colons --list-secret-keys "$GPG_EMAIL" | awk -F: '/^fpr:/ { f=$10 } END { print f }')"
  # Prefer the newest secret key fingerprint that isn't the old one.
  new_fpr="$(gpg --batch --with-colons --list-secret-keys | awk -F: -v old="$old_fpr" '
    /^fpr:/ { f=$10 }
    /^sec:/ { created=$6; if (f != old && created >= best) { best=created; bestf=f } }
    END { print bestf }
  ')"
  [[ -n $new_fpr ]] || die "failed to resolve new fingerprint"
  echo "New fingerprint: $new_fpr"

  gpg --batch --yes --pinentry-mode loopback --passphrase "$passphrase" \
    --armor --export-secret-keys "$new_fpr" >"$key_export"

  echo "Moving current sops GPG material to previous slots..."
  local cur_key cur_pp
  cur_key="$(sops -d --extract '["gpg_private_key"]' "$SOPS_FILE")"
  cur_pp="$(sops -d --extract '["gpg_passphrase"]' "$SOPS_FILE")"
  sops set "$SOPS_FILE" '["gpg_private_key_previous"]' "$(printf '%s' "$cur_key" | json_str)"
  sops set "$SOPS_FILE" '["gpg_passphrase_previous"]' "$(printf '%s' "$cur_pp" | json_str)"
  sops set "$SOPS_FILE" '["gpg_private_key"]' "$(json_str <"$key_export")"
  sops set "$SOPS_FILE" '["gpg_passphrase"]' "$(printf '%s' "$passphrase" | json_str)"

  preset_passphrase "$passphrase"
  preset_passphrase "$cur_pp"

  {
    echo "$old_fpr"
    echo "$new_fpr"
  } >"$PASSWORD_STORE_DIR/.gpg-id"

  echo "Re-encrypting store for dual recipients..."
  reencrypt_all

  write_state "$new_fpr" true "$old_fpr"
  git -C "$PASSWORD_STORE_DIR" add -A
  git -C "$PASSWORD_STORE_DIR" commit -m "rotate: dual-encrypt for $new_fpr (grace with $old_fpr)" || true
  git -C "$PASSWORD_STORE_DIR" push || echo "warn: pass git push failed; push manually"

  echo
  echo "Phase 1 complete. Rebuild/activate all hosts, then run:"
  echo "  nix run .#pass-rotate -- --finalize"
}

phase2() {
  local fpr old pending
  [[ -f $STATE_FILE ]] || die "missing $STATE_FILE"
  pending="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('pending_finalize', False))")"
  [[ $pending == "True" || $pending == "true" ]] || die "no pending finalize; run phase 1 first"
  fpr="$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['fingerprint'])")"
  old="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('previous_fingerprint',''))")"

  echo "Phase 2: finalizing to $fpr only..."
  pass show _bootstrap/ok >/dev/null || die "canary decrypt failed; abort finalize"

  printf '%s\n' "$fpr" >"$PASSWORD_STORE_DIR/.gpg-id"
  reencrypt_all

  sops set "$SOPS_FILE" '["gpg_private_key_previous"]' '"placeholder"'
  sops set "$SOPS_FILE" '["gpg_passphrase_previous"]' '"placeholder"'

  if [[ -n $old ]]; then
    gpg --batch --yes --delete-secret-keys "$old" 2>/dev/null || true
    gpg --batch --yes --delete-keys "$old" 2>/dev/null || true
  fi

  write_state "$fpr" false
  git -C "$PASSWORD_STORE_DIR" add -A
  git -C "$PASSWORD_STORE_DIR" commit -m "rotate: finalize to $fpr" || true
  git -C "$PASSWORD_STORE_DIR" push || echo "warn: pass git push failed; push manually"

  echo "Phase 2 complete. Commit updated secrets/secrets.yaml in .dotfiles."
}

case "$MODE" in
--status | status) status ;;
--finalize | finalize) phase2 ;;
"" | --phase1 | phase1) phase1 ;;
-h | --help | help)
  echo "Usage: $0 [--status|--finalize]"
  ;;
*)
  die "unknown argument: $MODE (try --status or --finalize)"
  ;;
esac

#!/usr/bin/env bash
# Fetch the Alex-only age master from a private GitHub repo and materialize
# it for sops / sops-nix. Does not print the private key.
#
#   nix run .#secrets-bootstrap
#   nix run .#secrets-bootstrap -- --status
#
# Requires: gh authenticated as a user who can read the private artifact.
# Env overrides:
#   AGE_MASTER_OWNER  (default: aspauldingcode)
#   AGE_MASTER_REPO   (default: dendritic-age-master)
#   AGE_MASTER_PATH   (default: age-master.key)
#   SOPS_AGE_KEY_FILE (optional override for keys.txt path)
set -euo pipefail

die() {
  echo "fatal: $*" >&2
  exit 1
}

OWNER="${AGE_MASTER_OWNER:-aspauldingcode}"
REPO="${AGE_MASTER_REPO:-dendritic-age-master}"
PATH_IN_REPO="${AGE_MASTER_PATH:-age-master.key}"

if [[ -n ${SOPS_AGE_KEY_FILE:-} ]]; then
  AGE_KEY_FILE="$SOPS_AGE_KEY_FILE"
  AGE_KEY_DIR="$(dirname "$AGE_KEY_FILE")"
elif [[ $(uname -s) == Darwin ]]; then
  AGE_KEY_DIR="${HOME}/Library/Application Support/sops/age"
  AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"
else
  AGE_KEY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age"
  AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"
fi
MASTER_FILE="${AGE_KEY_DIR}/github-age-master.key"

STATUS_ONLY=0
for arg in "$@"; do
  case "$arg" in
  --status) STATUS_ONLY=1 ;;
  -h | --help)
    sed -n '1,20p' "$0"
    exit 0
    ;;
  *) die "unknown arg: $arg" ;;
  esac
done

command -v gh >/dev/null 2>&1 || die "gh not in PATH"
command -v python3 >/dev/null 2>&1 || die "python3 not in PATH"

if ! gh auth status -h github.com >/dev/null 2>&1; then
  die "gh is not authenticated for github.com — run: gh auth login"
fi

if [[ $STATUS_ONLY -eq 1 ]]; then
  if [[ -r $MASTER_FILE ]]; then
    echo "ok: master key present at $MASTER_FILE"
    if grep -q 'AGE-SECRET-KEY' "$MASTER_FILE" 2>/dev/null; then
      echo "ok: looks like an age private key file"
    else
      echo "warn: file exists but does not look like an age key" >&2
    fi
  else
    echo "missing: $MASTER_FILE — run: nix run .#secrets-bootstrap"
    exit 1
  fi
  exit 0
fi

echo "==> fetching ${OWNER}/${REPO}:${PATH_IN_REPO} via gh"
raw_json="$(gh api "repos/${OWNER}/${REPO}/contents/${PATH_IN_REPO}")" ||
  die "cannot read ${OWNER}/${REPO}/${PATH_IN_REPO} (private? auth as Alex?)"

tmp="$(mktemp)"
chmod 600 "$tmp"
printf '%s' "$raw_json" | python3 -c '
import base64, json, sys
data = json.load(sys.stdin)
content = data.get("content") or ""
encoding = data.get("encoding") or "base64"
if encoding != "base64":
    raise SystemExit(f"unsupported encoding: {encoding}")
sys.stdout.buffer.write(base64.b64decode(content))
' >"$tmp"

grep -q 'AGE-SECRET-KEY' "$tmp" || {
  rm -f "$tmp"
  die "downloaded file is not an age private key"
}

mkdir -p "$AGE_KEY_DIR"
chmod 700 "$AGE_KEY_DIR"
mv "$tmp" "$MASTER_FILE"
chmod 600 "$MASTER_FILE"

# Seed keys.txt from the master. HM activation merges ssh-to-age on rebuild
# when dendritic.secrets.includeSshAge is enabled (grace period).
cp "$MASTER_FILE" "$AGE_KEY_FILE"
chmod 600 "$AGE_KEY_FILE"

echo "ok: materialized age master (mode 0600)"
echo "    master: $MASTER_FILE"
echo "    keys:   $AGE_KEY_FILE"
echo "Next: nh/darwin-rebuild / home-manager switch so sops can decrypt."

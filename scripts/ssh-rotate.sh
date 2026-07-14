#!/usr/bin/env bash
# Rotate a host SSH identity used for login (+ optional sops age recipient).
#
#   nix run .#ssh-rotate -- --name mba --pubkey ~/.ssh/id_ed25519.pub
#   nix run .#ssh-rotate -- --name mba --finalize
#
# Grace: keeps old age recipient until --finalize drops it from .sops.yaml
# and rewraps. Pubkey in home/ssh-keys.nix is replaced immediately on rotate.
set -euo pipefail

die() {
  echo "fatal: $*" >&2
  exit 1
}

REPO_ROOT="${DOTFILES_ROOT:-}"
if [[ -z $REPO_ROOT || ! -f $REPO_ROOT/.sops.yaml ]]; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [[ -z $REPO_ROOT || ! -f $REPO_ROOT/.sops.yaml ]]; then
  die "cannot find .dotfiles root (set DOTFILES_ROOT or run from the checkout)"
fi
cd "$REPO_ROOT"

NAME=""
PUBKEY_PATH=""
FINALIZE=0
DO_SOPS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
  --name)
    NAME="${2:-}"
    shift 2
    ;;
  --pubkey)
    PUBKEY_PATH="${2:-}"
    shift 2
    ;;
  --finalize)
    FINALIZE=1
    shift
    ;;
  --no-sops)
    DO_SOPS=0
    shift
    ;;
  -h | --help)
    sed -n '1,18p' "$0"
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
done

[[ -n $NAME ]] || die "required: --name <host>"

if [[ $FINALIZE -eq 1 ]]; then
  [[ $DO_SOPS -eq 1 ]] || die "--finalize requires sops updates"
  ANCHOR="user_${NAME}"
  ANCHOR="$(printf '%s' "$ANCHOR" | tr -c 'A-Za-z0-9_' '_')"
  PREV="${ANCHOR}_previous"
  if grep -qE "^[[:space:]]*- &${PREV} |^[[:space:]]*- \\*${PREV}[[:space:]]*$" "$REPO_ROOT/.sops.yaml"; then
    python3 - "$REPO_ROOT/.sops.yaml" "$PREV" <<'PY'
import pathlib, re, sys
path, prev = sys.argv[1], sys.argv[2]
text = pathlib.Path(path).read_text()
text = re.sub(rf'(?m)^\s*- &{re.escape(prev)} .*\n', '', text)
text = re.sub(rf'(?m)^\s*- \*{re.escape(prev)}\s*\n', '', text)
pathlib.Path(path).write_text(text)
print(f"removed {prev} from .sops.yaml")
PY
    bash "$REPO_ROOT/scripts/sops-updatekeys.sh"
    echo "Finalized: dropped ${PREV}. Commit rewrapped secrets."
  else
    echo "nothing to finalize for $NAME (no ${PREV} in .sops.yaml)"
  fi
  exit 0
fi

[[ -n $PUBKEY_PATH ]] || die "required: --pubkey <path> (or --finalize)"
[[ -r $PUBKEY_PATH ]] || die "pubkey not readable: $PUBKEY_PATH"

# Rename existing anchor to _previous (exact token match), then enroll new key.
if [[ $DO_SOPS -eq 1 ]] && [[ -f $REPO_ROOT/.sops.yaml ]]; then
  ANCHOR="user_${NAME}"
  ANCHOR="$(printf '%s' "$ANCHOR" | tr -c 'A-Za-z0-9_' '_')"
  PREV="${ANCHOR}_previous"
  python3 - "$REPO_ROOT/.sops.yaml" "$ANCHOR" "$PREV" <<'PY'
import pathlib, re, sys
path, anchor, prev = sys.argv[1], sys.argv[2], sys.argv[3]
text = pathlib.Path(path).read_text()
# Drop any stale previous slot first.
text = re.sub(rf'(?m)^\s*- &{re.escape(prev)} .*\n', '', text)
text = re.sub(rf'(?m)^\s*- \*{re.escape(prev)}\s*\n', '', text)
# Rename current anchor -> previous (do not match prefix of longer names).
if re.search(rf'(?m)^\s*- &{re.escape(anchor)} ', text):
    text = re.sub(
        rf'(?m)^(\s*- &){re.escape(anchor)}( )',
        rf'\1{prev}\2',
        text,
    )
    text = re.sub(
        rf'(?m)^(\s*- \*){re.escape(anchor)}(\s*)$',
        rf'\1{prev}\2',
        text,
    )
    pathlib.Path(path).write_text(text)
    print(f"renamed &{anchor} -> &{prev}")
else:
    print(f"no existing &{anchor} to rename (first enroll via rotate)")
    pathlib.Path(path).write_text(text)
PY
fi

if [[ $DO_SOPS -eq 1 ]]; then
  exec bash "$REPO_ROOT/scripts/ssh-enroll.sh" --name "$NAME" --pubkey "$PUBKEY_PATH" --sops
else
  exec bash "$REPO_ROOT/scripts/ssh-enroll.sh" --name "$NAME" --pubkey "$PUBKEY_PATH" --no-sops
fi

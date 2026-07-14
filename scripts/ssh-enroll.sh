#!/usr/bin/env bash
# Enroll a host SSH pubkey for login (authorizedKeys) and optionally as a
# sops age recipient during grace migrations.
#
# Run on a machine that can already decrypt sops (or after GitHub age bootstrap).
#
#   nix run .#ssh-enroll -- --name sliceanddice --pubkey ~/.ssh/id_ed25519.pub
#   nix run .#ssh-enroll -- --name mba --pubkey ~/.ssh/id_ed25519.pub --no-sops
#
# Updates home/ssh-keys.nix. With --sops (default): appends age recipient to
# .sops.yaml under keys: + secrets/secrets.yaml creation_rules, then updatekeys.
set -euo pipefail

die() {
  echo "fatal: $*" >&2
  exit 1
}

# Prefer DOTFILES_ROOT (set by flake apps). BASH_SOURCE is a single-file store
# path under `nix run`, so dirname/.. is NOT the repo root.
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
DO_SOPS=1
COMMIT=0

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
  --no-sops)
    DO_SOPS=0
    shift
    ;;
  --sops)
    DO_SOPS=1
    shift
    ;;
  --commit)
    COMMIT=1
    shift
    ;;
  -h | --help)
    sed -n '1,20p' "$0"
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
done

[[ -n $NAME ]] || die "required: --name <host>"
[[ -n $PUBKEY_PATH ]] || die "required: --pubkey <path>"
[[ -r $PUBKEY_PATH ]] || die "pubkey not readable: $PUBKEY_PATH"

command -v ssh-to-age >/dev/null 2>&1 || die "ssh-to-age not in PATH"
command -v python3 >/dev/null 2>&1 || die "python3 not in PATH"

PUBKEY="$(tr -d '\n' <"$PUBKEY_PATH")"
[[ $PUBKEY == ssh-ed25519\ * ]] || die "expected ssh-ed25519 pubkey"

AGE_RECIPIENT="$(ssh-to-age <<<"$PUBKEY")"
[[ $AGE_RECIPIENT == age1* ]] || die "ssh-to-age failed"

KEYS_NIX="$REPO_ROOT/home/ssh-keys.nix"
[[ -f $KEYS_NIX ]] || die "missing $KEYS_NIX"

python3 - "$KEYS_NIX" "$NAME" "$PUBKEY" <<'PY'
import pathlib, re, sys
path, name, pubkey = sys.argv[1], sys.argv[2], sys.argv[3]
text = pathlib.Path(path).read_text()
attr = name if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) else f'"{name}"'
entry = f'  {attr} = "{pubkey}";\n'
if re.search(rf'(?m)^\s*("{re.escape(name)}"|{re.escape(name)})\s*=', text):
    text = re.sub(
        rf'(?m)^\s*("{re.escape(name)}"|{re.escape(name)})\s*=\s*"[^"]*"\s*;\s*$',
        entry.rstrip(),
        text,
    )
else:
    text = re.sub(r'\n\}\s*$', f'\n{entry}}}', text)
pathlib.Path(path).write_text(text if text.endswith("\n") else text + "\n")
print(f"updated {path} ({name})")
PY

if [[ $DO_SOPS -eq 1 ]]; then
  [[ -f $REPO_ROOT/.sops.yaml ]] || die "missing .sops.yaml"
  ANCHOR="user_${NAME}"
  ANCHOR="$(printf '%s' "$ANCHOR" | tr -c 'A-Za-z0-9_' '_')"
  python3 - "$REPO_ROOT/.sops.yaml" "$ANCHOR" "$AGE_RECIPIENT" <<'PY'
import pathlib, re, sys

path, anchor, recip = sys.argv[1], sys.argv[2], sys.argv[3]
text = pathlib.Path(path).read_text()

def has_key_def(src: str, name: str) -> bool:
    return re.search(rf'(?m)^\s*- &{re.escape(name)} ', src) is not None

changed = False
if not has_key_def(text, anchor):
    if "keys:\n" not in text:
        raise SystemExit("no keys: block in .sops.yaml")
    text = text.replace("keys:\n", f"keys:\n  - &{anchor} {recip}\n", 1)
    changed = True
    print(f"added keys entry &{anchor}")
else:
    # Refresh recipient value for existing anchor.
    text2, n = re.subn(
        rf'(?m)^(\s*- &{re.escape(anchor)} )age1\S+',
        rf"\1{recip}",
        text,
        count=1,
    )
    if n:
        text = text2
        changed = True
        print(f"updated keys entry &{anchor}")
    else:
        print(f"keys entry &{anchor} already present")

# Ensure secrets/secrets.yaml creation_rule references the anchor.
rule_pat = re.compile(
    r"(  - path_regex: secrets/secrets\\.yaml\$\n    age:\n)((?:      - \*[^\n]+\n)*)",
    re.MULTILINE,
)
m = rule_pat.search(text)
if not m:
    raise SystemExit("secrets/secrets.yaml creation_rule not found in .sops.yaml")
prefix, refs = m.group(1), m.group(2)
if not re.search(rf'(?m)^\s*- \*{re.escape(anchor)}\s*$', refs):
    refs = refs + f"      - *{anchor}\n"
    text = text[: m.start()] + prefix + refs + text[m.end() :]
    changed = True
    print(f"added creation_rule ref *{anchor}")
else:
    print(f"creation_rule already has *{anchor}")

if changed:
    pathlib.Path(path).write_text(text)
else:
    print("sops: no .sops.yaml changes needed")
PY
  bash "$REPO_ROOT/scripts/sops-updatekeys.sh"
  # Fail closed if the new recipient did not land in secrets.yaml.
  if ! grep -qF "$AGE_RECIPIENT" "$REPO_ROOT/secrets/secrets.yaml"; then
    die "sops updatekeys did not wrap secrets/secrets.yaml to $AGE_RECIPIENT (creation_rules missing ref?)"
  fi
fi

echo
echo "Enrolled $NAME"
echo "  pubkey: $PUBKEY"
echo "  age:    $AGE_RECIPIENT"
if [[ $COMMIT -eq 1 ]]; then
  git add home/ssh-keys.nix .sops.yaml secrets/*.yaml 2>/dev/null || true
  git commit -m "ssh: enroll $NAME"
else
  echo "Commit when ready: git add home/ssh-keys.nix .sops.yaml secrets && git commit"
fi

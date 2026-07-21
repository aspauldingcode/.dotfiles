#!/usr/bin/env bash
# Local flake Sync for dendritic tray:
#   fetch/rebase development, commit dirty (LLM changelog or fallback),
#   sync master↔development, push, flake update, local nh switch.
# Never force-push. No Cursor attribution.
set -euo pipefail

STATUS="${DENDRITIC_TRAY_STATUS:-${HOME}/.cache/dendritic-tray.status}"
LOCK="${HOME}/.cache/dendritic-tray.lock"
LOG="${HOME}/.cache/dendritic-tray-sync.log"
DOTFILES="${DOTFILES_ROOT:-${DENDRITIC_DOTFILES:-}}"
if [[ -z $DOTFILES ]]; then
  if [[ -d /etc/nix-darwin/.dotfiles/.git ]]; then
    DOTFILES=/etc/nix-darwin/.dotfiles
  elif [[ -d /etc/nixos/.dotfiles/.git ]]; then
    DOTFILES=/etc/nixos/.dotfiles
  else DOTFILES="$(git rev-parse --show-toplevel 2>/dev/null || true)"; fi
fi
HOST="$(hostname -s 2>/dev/null || hostname | cut -d. -f1)"
COLLECT="${DENDRITIC_TRAY_COLLECT:-dendritic-tray-collect}"

mkdir -p "$(dirname "$STATUS")" "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "==== dendritic-tray-sync $(date -u +%Y-%m-%dT%H:%M:%SZ) host=$HOST ===="

write_job() {
  local state="$1" msg="$2"
  python3 - "$STATUS" "$state" "$msg" <<'PY'
import json,sys
from pathlib import Path
from datetime import datetime,timezone
p=Path(sys.argv[1]); state=sys.argv[2]; msg=sys.argv[3]
d={}
if p.is_file():
  try: d=json.loads(p.read_text())
  except Exception: d={}
d.setdefault("schema",1)
d["updated_at"]=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
d["job"]={"state":state,"message":msg}
p.write_text(json.dumps(d,indent=2)+"\n")
PY
}

acquire_lock() {
  if mkdir "$LOCK" 2>/dev/null; then
    echo "$$" >"$LOCK/pid"
    return 0
  fi
  local old
  old="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [[ -n $old ]] && ! kill -0 "$old" 2>/dev/null; then
    rm -rf "$LOCK"
    mkdir "$LOCK" && echo "$$" >"$LOCK/pid" && return 0
  fi
  echo "dendritic-tray-sync: lock held; skip"
  write_job "error" "sync already running"
  return 1
}

release_lock() { rm -rf "$LOCK"; }

changelog_msg() {
  local fallback="auto-sync: ${HOST} $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local stat diff
  stat="$(git -C "$DOTFILES" diff --stat HEAD 2>/dev/null | head -40 || true)"
  diff="$(git -C "$DOTFILES" diff HEAD 2>/dev/null | head -c 4000 || true)"
  if ! command -v curl >/dev/null 2>&1; then
    echo "$fallback"
    return
  fi
  if ! curl -fsS --max-time 1 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo "$fallback"
    return
  fi
  local model
  model="$(curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags | python3 -c 'import json,sys; ms=json.load(sys.stdin).get("models") or []; print(ms[0]["name"] if ms else "")' 2>/dev/null || true)"
  [[ -z $model ]] && {
    echo "$fallback"
    return
  }
  local prompt
  prompt="Write a single Conventional Commit subject line (<=72 chars) for this .dotfiles nix flake change. No body. No markdown. No quotes.
stat:
$stat
diff (truncated):
$diff"
  local body
  body="$(python3 -c 'import json,sys; print(json.dumps({"model":sys.argv[1],"prompt":sys.argv[2],"stream":False,"options":{"temperature":0.2,"num_predict":48}}))' "$model" "$prompt")"
  local resp
  resp="$(curl -fsS --max-time 45 http://127.0.0.1:11434/api/generate -d "$body" 2>/dev/null || true)"
  local msg
  msg="$(printf '%s' "$resp" | python3 -c 'import json,sys,re
try:
  r=json.load(sys.stdin).get("response","")
except Exception:
  r=""
line=r.strip().splitlines()[0] if r.strip() else ""
line=line.strip().strip("`").strip("\"")
line=re.sub(r"^(Commit|Subject):\s*","",line,flags=re.I)
print(line[:72] if line else "")' 2>/dev/null || true)"
  if [[ -z $msg || $msg == *"Cursor"* ]]; then
    echo "$fallback"
  else
    echo "$msg"
  fi
}

cleanup() {
  local ec=$?
  if [[ $ec -ne 0 ]]; then
    write_job "error" "sync failed (see dendritic-tray-sync.log)"
  fi
  release_lock
}
trap cleanup EXIT

[[ -n $DOTFILES && -d "$DOTFILES/.git" ]] || {
  write_job "error" "no dotfiles checkout"
  exit 1
}
acquire_lock || exit 0

write_job "syncing" "fetch development"
git -C "$DOTFILES" fetch origin --prune

write_job "syncing" "rebase onto origin/development"
git -C "$DOTFILES" checkout development 2>/dev/null || git -C "$DOTFILES" checkout -B development origin/development
if ! git -C "$DOTFILES" pull --rebase --autostash origin development; then
  write_job "error" "rebase failed"
  exit 1
fi

if [[ -n "$(git -C "$DOTFILES" status --porcelain)" ]]; then
  write_job "syncing" "commit dirty tree"
  git -C "$DOTFILES" add -A
  # never stage secrets accidentally
  git -C "$DOTFILES" reset HEAD -- '*.env' '**/secrets.yaml' 2>/dev/null || true
  msg="$(changelog_msg)"
  if ! git -C "$DOTFILES" -c user.useConfigOnly=true commit -m "$msg"; then
    # empty commit after reset is ok
    if [[ -n "$(git -C "$DOTFILES" status --porcelain)" ]]; then
      write_job "error" "commit failed"
      exit 1
    fi
  fi
fi

write_job "syncing" "merge master ↔ development"
git -C "$DOTFILES" fetch origin master 2>/dev/null || true
git -C "$DOTFILES" merge origin/master --no-edit || true
git -C "$DOTFILES" push -u origin development
git -C "$DOTFILES" push origin development:master || {
  # master may reject non-ff; merge locally and push
  git -C "$DOTFILES" checkout master
  git -C "$DOTFILES" pull --ff-only origin master || true
  git -C "$DOTFILES" merge development --ff-only || git -C "$DOTFILES" merge development --no-edit
  git -C "$DOTFILES" push origin master
  git -C "$DOTFILES" checkout development
}

write_job "syncing" "nix flake update"
if ! (cd "$DOTFILES" && nix flake update 2>&1 | tee -a "$LOG"); then
  write_job "syncing" "flake update failed; continuing to switch"
fi
# commit lock bump if dirty
if [[ -n "$(git -C "$DOTFILES" status --porcelain flake.lock)" ]]; then
  git -C "$DOTFILES" add flake.lock
  git -C "$DOTFILES" -c user.useConfigOnly=true commit -m "chore(flake): update inputs" || true
  git -C "$DOTFILES" push origin development || true
  git -C "$DOTFILES" push origin development:master || true
fi

write_job "syncing" "local nh switch"
if [[ "$(uname -s)" == "Darwin" ]]; then
  nh darwin switch -H "${NH_FLAKE_HOST:-mba}" || nh darwin switch || true
else
  nh os switch -H "${NH_FLAKE_HOST:-sliceanddice}" || nh os switch || true
fi

write_job "idle" "sync ok"
if command -v "$COLLECT" >/dev/null 2>&1; then
  "$COLLECT" || true
elif [[ -x "${DOTFILES}/scripts/dendritic-tray-collect.sh" ]]; then
  bash "${DOTFILES}/scripts/dendritic-tray-collect.sh" || true
fi
echo "dendritic-tray-sync: done"

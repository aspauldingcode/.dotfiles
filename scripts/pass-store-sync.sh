#!/usr/bin/env bash
# Debounced password-store ↔ GitHub sync.
#
# Modes (PASS_STORE_SYNC_MODE):
#   full (default) — watchexec path: pull → CI dual-encrypt → commit → push
#   pull           — notify/catch-up: cheap ls-remote gate → pull only
#
# Never hard-fails the watcher: log and exit 0 on recoverable errors.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
LOCK_DIR="${PASS_STORE_SYNC_LOCK:-$HOME/.cache/pass-store-sync.lock}"
LOG_PREFIX="pass-store-sync"
MODE="${PASS_STORE_SYNC_MODE:-full}"

log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

# True if remote HEAD differs from local HEAD (needs pack transfer).
# Empty remote (network/auth) → treat as "not behind" and skip quietly.
remote_ahead() {
  local remote local_head
  remote="$(git ls-remote origin -q HEAD 2>/dev/null | cut -f1 || true)"
  local_head="$(git rev-parse HEAD 2>/dev/null || true)"
  [[ -n $remote && -n $local_head && $remote != "$local_head" ]]
}

# QtPass/pass re-encrypts to .gpg-id only. CI smoke needs Alex + CI canary on
# reserved template paths — restore dual recipients before commit/push.
ensure_ci_recipients() {
  local ci_id_file="$PASSWORD_STORE_DIR/.ci-gpg-id"
  local alex_id_file="$PASSWORD_STORE_DIR/.gpg-id"
  [[ -f $ci_id_file && -f $alex_id_file ]] || return 0

  local ci_fpr alex_fpr
  ci_fpr="$(tr -d '[:space:]' <"$ci_id_file")"
  alex_fpr="$(head -n1 "$alex_id_file" | tr -d '[:space:]')"
  [[ -n $ci_fpr && -n $alex_fpr ]] || return 0

  local entry rel n plain tmp fixed=0
  while IFS= read -r -d '' entry; do
    rel="${entry#"$PASSWORD_STORE_DIR"/}"
    case "$rel" in
    _bootstrap/*.gpg | test/*.gpg | secretspec/shared/default/DEMO_*.gpg) ;;
    *) continue ;;
    esac
    n="$(gpg --list-packets "$entry" 2>/dev/null | grep -c ':pubkey enc packet:' || true)"
    if [[ ${n:-0} -ge 2 ]]; then
      continue
    fi
    plain="$(mktemp)"
    tmp="$(mktemp)"
    if gpg --batch --quiet --decrypt "$entry" >"$plain" 2>/dev/null; then
      if gpg --batch --yes --trust-model always \
        --recipient "$alex_fpr" --recipient "$ci_fpr" \
        --encrypt --output "$tmp" "$plain" 2>/dev/null; then
        mv "$tmp" "$entry"
        fixed=$((fixed + 1))
        log "re-dual-encrypted $rel for CI canary"
      else
        warn "failed to re-encrypt $rel"
        rm -f "$tmp"
      fi
    else
      warn "failed to decrypt $rel for CI re-encrypt"
      rm -f "$tmp"
    fi
    rm -f "$plain"
  done < <(find "$PASSWORD_STORE_DIR" -type f -name '*.gpg' \
    ! -path '*/.git/*' -print0 2>/dev/null)

  if [[ $fixed -gt 0 ]]; then
    log "restored CI recipients on $fixed reserved path(s)"
  fi
}

if [[ ! -d "$PASSWORD_STORE_DIR/.git" ]]; then
  warn "no git store at $PASSWORD_STORE_DIR; skip"
  exit 0
fi

mkdir -p "$(dirname "$LOCK_DIR")"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  warn "lock held at $LOCK_DIR; skip"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

export GIT_TERMINAL_PROMPT=0
cd "$PASSWORD_STORE_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  warn "not a git work tree; skip"
  exit 0
fi

# ── pull-only (ntfy notify / agent catch-up) ─────────────────────────
if [[ $MODE == pull ]]; then
  if ! remote_ahead; then
    log "pull: up to date (ls-remote)"
    exit 0
  fi
  if ! git pull --rebase --autostash >/dev/null 2>&1; then
    warn "git pull --rebase failed (network/auth/conflict); will retry on next ping"
    exit 0
  fi
  log "pull: fetched remote updates"
  exit 0
fi

if [[ $MODE != full ]]; then
  warn "unknown PASS_STORE_SYNC_MODE=$MODE (use full|pull); skip"
  exit 0
fi

# ── full (watchexec local→push) ──────────────────────────────────────
# Pull remote first so local commits rebase cleanly.
if ! git pull --rebase --autostash >/dev/null 2>&1; then
  warn "git pull --rebase failed (network/auth/conflict); will retry on next event"
  exit 0
fi

ensure_ci_recipients

dirty="$(git status --porcelain || true)"
if [[ -n $dirty ]]; then
  git add -A
  git reset HEAD -- .DS_Store 2>/dev/null || true
  if git diff --cached --quiet; then
    exit 0
  fi
  host="$(hostname -s 2>/dev/null || hostname || echo unknown)"
  msg="auto-sync: ${host} $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if ! git -c user.useConfigOnly=true commit -m "$msg" >/dev/null 2>&1; then
    # Bare clones may lack user.name/email; fall back for agent commits only.
    if ! git -c user.name="pass-store-sync" -c user.email="pass-store-sync@localhost" \
      commit -m "$msg" >/dev/null 2>&1; then
      warn "git commit failed"
      exit 0
    fi
  fi
  log "committed local store changes ($msg)"
fi

ahead="$(git status -sb 2>/dev/null || true)"
if [[ $ahead == *ahead* ]]; then
  if ! git push >/dev/null 2>&1; then
    warn "git push failed (network/auth); will retry on next event"
    exit 0
  fi
  log "pushed to remote"
fi

exit 0

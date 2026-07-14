#!/usr/bin/env bash
# Debounced password-store ↔ GitHub sync.
#
# Modes (PASS_STORE_SYNC_MODE):
#   full (default) — watchexec path: pull → CI dual-encrypt → commit → push
#   pull           — notify/catch-up: cheap ls-remote gate → pull only
#
# Writes ~/.cache/pass-store-sync.status for the tray (no secret plaintext).
# Rematerializes secretspec→home files when secretspec/ paths change.
#
# Never hard-fails the watcher: log and exit 0 on recoverable errors.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
LOCK_DIR="${PASS_STORE_SYNC_LOCK:-$HOME/.cache/pass-store-sync.lock}"
STATUS_FILE="${PASS_STORE_SYNC_STATUS:-$HOME/.cache/pass-store-sync.status}"
LOG_PREFIX="pass-store-sync"
MODE="${PASS_STORE_SYNC_MODE:-full}"
MATERIALIZE_SCRIPT="${PASS_MATERIALIZE_SCRIPT:-}"

log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

utc_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Merge fields into status JSON atomically. Preserves unknown prior keys.
write_status() {
  local now tmp key val pair
  now="$(utc_now)"
  mkdir -p "$(dirname "$STATUS_FILE")"
  if [[ ! -f $STATUS_FILE ]]; then
    printf '%s\n' '{}' >"$STATUS_FILE"
  fi
  tmp="$(mktemp "${STATUS_FILE}.XXXXXX")"
  local -a jq_args=(-nc --slurpfile prev "$STATUS_FILE" --arg now "$now" --arg mode "$MODE")
  local jq_prog='($prev[0] // {}) + {updated_at:$now, mode:$mode'
  for pair in "$@"; do
    key="${pair%%=*}"
    val="${pair#*=}"
    case "$key" in
    state | direction | message | error | last_pull_at | last_push_at | ahead_behind)
      jq_args+=(--arg "$key" "$val")
      jq_prog+=", ${key}:\$${key}"
      ;;
    esac
  done
  jq_prog+='} | if .error == "" then .error = null else . end'
  if ! jq "${jq_args[@]}" "$jq_prog" >"$tmp" 2>/dev/null; then
    rm -f "$tmp"
    return 0
  fi
  mv "$tmp" "$STATUS_FILE"
}

ahead_behind_str() {
  local ab
  ab="$(git rev-list --left-right --count HEAD...origin/HEAD 2>/dev/null || true)"
  if [[ -z $ab ]]; then
    printf 'unknown'
    return
  fi
  # "N\tM" → ahead N, behind M
  printf 'ahead %s, behind %s' "$(printf '%s' "$ab" | cut -f1)" "$(printf '%s' "$ab" | cut -f2)"
}

maybe_materialize() {
  local before="$1" after="$2"
  [[ -n ${MATERIALIZE_SCRIPT:-} && -f $MATERIALIZE_SCRIPT ]] || return 0
  [[ -n $before && -n $after && $before != "$after" ]] || return 0
  if git diff --name-only "$before" "$after" 2>/dev/null | grep -q '^secretspec/'; then
    log "secretspec paths changed; rematerializing"
    bash "$MATERIALIZE_SCRIPT" || warn "materialize failed"
  fi
}

# Rematerialize unconditionally (mapped keys only — cheap). Used when pass
# already committed before sync started (no in-run HEAD delta).
force_materialize() {
  [[ -n ${MATERIALIZE_SCRIPT:-} && -f $MATERIALIZE_SCRIPT ]] || return 0
  log "rematerializing secretspec → home"
  bash "$MATERIALIZE_SCRIPT" || warn "materialize failed"
}

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
    write_status \
      "state=idle" \
      "direction=none" \
      "message=pull: up to date" \
      "error=" \
      "ahead_behind=$(ahead_behind_str)"
    exit 0
  fi
  write_status \
    "state=downloading" \
    "direction=down" \
    "message=pulling remote updates" \
    "error="
  head_before="$(git rev-parse HEAD 2>/dev/null || true)"
  if ! git pull --rebase --autostash >/dev/null 2>&1; then
    warn "git pull --rebase failed (network/auth/conflict); will retry on next ping"
    write_status \
      "state=error" \
      "direction=down" \
      "message=git pull failed" \
      "error=git pull --rebase failed"
    exit 0
  fi
  head_after="$(git rev-parse HEAD 2>/dev/null || true)"
  log "pull: fetched remote updates"
  write_status \
    "state=idle" \
    "direction=down" \
    "message=pull: fetched remote updates" \
    "last_pull_at=$(utc_now)" \
    "error=" \
    "ahead_behind=$(ahead_behind_str)"
  force_materialize
  exit 0
fi

if [[ $MODE != full ]]; then
  warn "unknown PASS_STORE_SYNC_MODE=$MODE (use full|pull); skip"
  exit 0
fi

# ── full (watchexec local→push) ──────────────────────────────────────
# Prefer uploading when local is dirty; otherwise may still pull first.
dirty_preview="$(git status --porcelain || true)"
if [[ -n $dirty_preview ]]; then
  write_status \
    "state=uploading" \
    "direction=up" \
    "message=syncing local changes" \
    "error="
else
  write_status \
    "state=downloading" \
    "direction=down" \
    "message=checking remote" \
    "error="
fi

head_before="$(git rev-parse HEAD 2>/dev/null || true)"
pulled=0
# Pull remote first so local commits rebase cleanly.
if ! git pull --rebase --autostash >/dev/null 2>&1; then
  warn "git pull --rebase failed (network/auth/conflict); will retry on next event"
  write_status \
    "state=error" \
    "direction=down" \
    "message=git pull failed" \
    "error=git pull --rebase failed"
  exit 0
fi
head_after_pull="$(git rev-parse HEAD 2>/dev/null || true)"
if [[ -n $head_before && -n $head_after_pull && $head_before != "$head_after_pull" ]]; then
  pulled=1
  write_status \
    "state=idle" \
    "direction=down" \
    "message=pulled remote updates" \
    "last_pull_at=$(utc_now)" \
    "error=" \
    "ahead_behind=$(ahead_behind_str)"
fi

ensure_ci_recipients

dirty="$(git status --porcelain || true)"
committed=0
if [[ -n $dirty ]]; then
  write_status \
    "state=uploading" \
    "direction=up" \
    "message=committing local changes" \
    "error="
  git add -A
  git reset HEAD -- .DS_Store 2>/dev/null || true
  if git diff --cached --quiet; then
    write_status \
      "state=idle" \
      "direction=none" \
      "message=nothing to commit" \
      "error=" \
      "ahead_behind=$(ahead_behind_str)"
    maybe_materialize "$head_before" "$head_after_pull"
    exit 0
  fi
  host="$(hostname -s 2>/dev/null || hostname || echo unknown)"
  msg="auto-sync: ${host} $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if ! git -c user.useConfigOnly=true commit -m "$msg" >/dev/null 2>&1; then
    # Bare clones may lack user.name/email; fall back for agent commits only.
    if ! git -c user.name="pass-store-sync" -c user.email="pass-store-sync@localhost" \
      commit -m "$msg" >/dev/null 2>&1; then
      warn "git commit failed"
      write_status \
        "state=error" \
        "direction=up" \
        "message=git commit failed" \
        "error=git commit failed"
      exit 0
    fi
  fi
  committed=1
  log "committed local store changes ($msg)"
fi

ahead="$(git status -sb 2>/dev/null || true)"
pushed=0
if [[ $ahead == *ahead* ]]; then
  write_status \
    "state=uploading" \
    "direction=up" \
    "message=pushing to remote" \
    "error="
  if ! git push >/dev/null 2>&1; then
    warn "git push failed (network/auth); will retry on next event"
    write_status \
      "state=error" \
      "direction=up" \
      "message=git push failed" \
      "error=git push failed"
    exit 0
  fi
  pushed=1
  log "pushed to remote"
  write_status \
    "state=idle" \
    "direction=up" \
    "message=pushed to remote" \
    "last_push_at=$(utc_now)" \
    "error=" \
    "ahead_behind=$(ahead_behind_str)"
else
  final_dir=none
  final_msg="up to date"
  if [[ $pulled -eq 1 ]]; then
    final_dir=down
    final_msg="pulled remote updates"
  fi
  write_status \
    "state=idle" \
    "direction=${final_dir}" \
    "message=${final_msg}" \
    "error=" \
    "ahead_behind=$(ahead_behind_str)"
fi

# Rematerialize after pull/commit/push (covers pass auto-commit before agent).
if [[ $pulled -eq 1 || $committed -eq 1 || $pushed -eq 1 || -n $dirty_preview ]]; then
  force_materialize
fi

exit 0

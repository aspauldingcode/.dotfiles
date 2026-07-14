#!/usr/bin/env bash
# Interactive tmux tutorial for the dendritic config.
# Opens inside `tmux display-popup` (prefix+F1) or as `tmux-learn` from the shell.
set -euo pipefail

PREFIX="Ctrl-a"
MARK="${HOME}/.cache/tmux-tutorial-seen"
mkdir -p "$(dirname "$MARK")"

pause() {
  printf '\n'
  read -r -p "Press Enter to continue… " _
  printf '\n'
}

clear 2>/dev/null || true
cat <<EOF
╭──────────────────────────────────────────────────────────╮
│           Dendritic tmux — interactive tutorial          │
╰──────────────────────────────────────────────────────────╯

Your prefix key is:  ${PREFIX}
  (press ${PREFIX}, release, then the next key)

This walkthrough takes ~2 minutes. You can quit anytime with q + Enter.

EOF
pause

cat <<EOF
── 1. The cheat sheet (which-key) ──────────────────────────

  ${PREFIX}  then  Space     → searchable action menu (best way to learn)
  ${PREFIX}  then  ?         → same menu (alias)
  ${PREFIX}  then  F1        → this tutorial again

Try it after you finish: press ${PREFIX}, release, then Space.
Navigate with letters shown in the menu. Esc closes it.

EOF
pause

cat <<EOF
── 2. Panes (split the window) ─────────────────────────────

  ${PREFIX}  |     → split left/right  (vertical bar)
  ${PREFIX}  -     → split top/bottom
  ${PREFIX}  x     → kill current pane
  ${PREFIX}  z     → zoom pane (fullscreen toggle)

Mouse works too: click panes, drag borders, scroll to copy-mode.

Vim-style move between panes (and Neovim splits):
  Ctrl-h / Ctrl-j / Ctrl-k / Ctrl-l

EOF
pause

cat <<EOF
── 3. Windows (tabs) ───────────────────────────────────────

  ${PREFIX}  c     → new window
  ${PREFIX}  n / p → next / previous
  ${PREFIX}  1..9  → jump to window number
  ${PREFIX}  ,     → rename window

EOF
pause

cat <<EOF
── 4. Copy mode (scroll + yank) ────────────────────────────

  ${PREFIX}  [     → enter copy-mode
  h j k l          → move
  v                → start selection
  y                → yank (system clipboard)
  ${PREFIX}  ]     → paste

Mouse: scroll wheel enters copy-mode; drag to select.

EOF
pause

cat <<EOF
── 5. Sessions (survive disconnects) ───────────────────────

  ${PREFIX}  d           → detach (tmux keeps running)
  tmux a                 → reattach last session
  t                      → shell alias: attach-or-create "main"

Auto-save every 15 min (continuum). Manual:
  ${PREFIX}  Ctrl-s      → save
  ${PREFIX}  Ctrl-r      → restore

EOF
pause

cat <<EOF
── 6. Quick start from the shell ───────────────────────────

  t              → enter/create session "main"
  tmux-learn     → this tutorial
  tmux ls        → list sessions

Done. Closing this popup returns you to tmux.

Next: ${PREFIX} then Space  → explore the which-key menu.
EOF

touch "$MARK"
pause
printf 'Tutorial complete. Happy multiplexing.\n'
sleep 0.6

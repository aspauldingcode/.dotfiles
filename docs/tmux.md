# Tmux Master Guide (dendritic)

Unified across **macOS** and **NixOS** via [`modules/apps/tmux.nix`](../modules/apps/tmux.nix).

## Quick start

Ghostty (and other interactive shells) **auto-attach** session `main`.
Escape hatch: `DENDRITIC_NO_TMUX=1` · Cursor/VS Code terminals are skipped.

```bash
t              # attach or create session "main" (manual)
tmux-learn     # interactive tutorial (popup)
```

Inside tmux (you will not remember F1 — use these):

| Keys                  | What                                    |
| --------------------- | --------------------------------------- |
| _(first attach)_      | Tutorial opens automatically once       |
| `Ctrl-a` then `T`     | Interactive tutorial (memorable)        |
| `Ctrl-a` then `Space` | **Which-key** menu — press `t` Tutorial |
| `Ctrl-a` then `?`     | Same which-key menu                     |
| `Ctrl-a` then `F1`    | Tutorial (same as `T`)                  |

From any shell: `tmuxhelp` or `tmux-learn`.

> `prefix` means: press `Ctrl-a`, release, then the next key.

First attach auto-opens the tutorial until you finish it once
(`~/.cache/tmux-tutorial-seen`). After that, `Ctrl-a` `T` or `tmuxhelp`.

---

## Prefix: `Ctrl-a`

Changed from stock `Ctrl-b` for ergonomics (Screen-style; common power-user default).

---

## Sessions & windows (dual tab bar)

Top status row = **sessions** · bottom = **windows** inside the current session.
Both are clickable (tmux `range=session` / `range=window`). Stylix-colored.

| Action         | How                                                                      |
| -------------- | ------------------------------------------------------------------------ |
| Switch session | click session pill · `prefix` `(`/`)` · `prefix` `o` (sessionx fuzzy)    |
| New session    | green **+** on top row · `prefix` `C` · right-click status → New Session |
| Kill session   | right-click session pill → Kill · `prefix` `X`                           |
| Switch window  | click window pill · `prefix` `n`/`p` · `Ctrl-Tab`                        |
| New window     | green **+** on bottom row · `prefix` `c`                                 |
| Kill window    | middle-click window pill · right-click → Kill · `prefix` `&`             |
| Rename         | right-click pill → Rename · `prefix` `,` (window) / `$` (session)        |

## Panes

| Action           | Keybind                  |
| ---------------- | ------------------------ |
| Split vertical   | `prefix` `\|`            |
| Split horizontal | `prefix` `-`             |
| Kill pane        | `prefix` `x`             |
| Zoom pane        | `prefix` `z`             |
| Resize pane      | `prefix` `H` `J` `K` `L` |

Mouse: click panes, drag borders, scroll → copy-mode.

Vim navigation between panes (and Neovim): `Ctrl-h/j/k/l`.

---

## Copy & paste (vi mode)

1. `prefix` `[` — copy-mode
2. `v` — select · `y` — yank to **system clipboard** · `prefix` `]` — paste

---

## Sessions

| Action   | How               |
| -------- | ----------------- |
| Detach   | `prefix` `d`      |
| Reattach | `t` or `tmux a`   |
| Save     | `prefix` `Ctrl-s` |
| Restore  | `prefix` `Ctrl-r` |

Continuum auto-saves every 15 minutes and restores on start.

---

## URLs

`prefix` `u` — fuzzy-find URLs in the pane (fzf-tmux-url).

---

## Design notes

- **which-key** is **prebuilt in Nix** and sourced directly (`source-file …/init.tmux`).
  Upstream `plugin.sh.tmux` is skipped: macOS BSD `realpath` lacks `--relative-to`,
  and the Nix store is read-only — both break the stock XDG autobuild path.
- Enabled by default on every host that imports `homeManager.dendritic`
  (`dendritic.apps.tmux.enable = true`).
- Defaults match common cross-platform practice: Ctrl-a, mouse, vi copy-mode,
  truecolor, resurrect/continuum, vim-tmux-navigator.

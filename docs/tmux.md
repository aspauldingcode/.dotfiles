# Tmux Master Guide (dendritic)

Unified across **macOS** and **NixOS** via [`modules/apps/tmux.nix`](../modules/apps/tmux.nix).

## Quick start

```bash
t              # attach or create session "main"
tmux-learn     # interactive tutorial (popup)
```

Inside tmux:

| Keys                  | What                                    |
| --------------------- | --------------------------------------- |
| `Ctrl-a` then `Space` | **Which-key** menu (searchable actions) |
| `Ctrl-a` then `?`     | Same which-key menu                     |
| `Ctrl-a` then `F1`    | Interactive tutorial popup              |
| Which-key → `t`       | Tutorial from the menu                  |

> `prefix` means: press `Ctrl-a`, release, then the next key.

On first attach you’ll see a tip until you’ve completed the tutorial once
(`~/.cache/tmux-tutorial-seen`).

---

## Prefix: `Ctrl-a`

Changed from stock `Ctrl-b` for ergonomics (Screen-style; common power-user default).

---

## Panes & windows

| Action                 | Keybind                  |
| ---------------------- | ------------------------ |
| Split vertical         | `prefix` `\|`            |
| Split horizontal       | `prefix` `-`             |
| Kill pane              | `prefix` `x`             |
| Zoom pane              | `prefix` `z`             |
| New window             | `prefix` `c`             |
| Next / previous window | `prefix` `n` / `p`       |
| Resize pane            | `prefix` `H` `J` `K` `L` |

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

# Dendritic menubar (pass-store-tray)

Native menubar applet (macOS NSStatusItem / Linux StatusNotifier). Same binary
and launchd/systemd labels as before (`pass-store-tray`) — pass sync status is
unchanged; dendritic fleet/theme/llm/wg/flake status is layered on top.

## Status files

| File                              | Writer                                              |
| --------------------------------- | --------------------------------------------------- |
| `~/.cache/pass-store-sync.status` | `pass-store-sync` (existing)                        |
| `~/.cache/dendritic-tray.status`  | `dendritic-tray-collect` / `dendritic tray collect` |

Tray polls both ~2s. Collect runs when dendritic status is older than ~45s.

## Menu

1. Dynamic status rows (omit healthy-ok noise)
2. Open QtPass / Open sync log
3. **Sync flake…** — local git sync + flake update + `nh` switch (LLM changelog when Ollama is up)
4. **Switch peer…** — SSH over WireGuard to peer, pull + `nh` switch
5. Quit

## CLI

```bash
dendritic tray collect
dendritic tray sync
dendritic tray switch-peer
# or:
dendritic-tray-collect
dendritic-tray-sync
dendritic-tray-switch-peer
```

Logs: `~/.cache/dendritic-tray-sync.log`

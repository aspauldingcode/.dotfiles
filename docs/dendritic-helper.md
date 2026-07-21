# Dendritic privileged helper

Monolithic Rust CLI (`dendritic`) plus a **root** helper daemon that performs
allowlisted privilege ops over a Unix socket. Replaces `osascript … with
administrator privileges` (the source of repeated macOS password prompts).

## Trust model

| Piece                                                                               | How it is trusted                                                              |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `com.aspauldingcode.dendritic-helper` (Darwin) / `dendritic-helper.service` (NixOS) | Installed as root by `nh darwin/os switch` — **one** sudo/Touch ID at activate |
| Socket `/var/run/dendritic/helper.sock`                                             | Mode `0660`, peer credentials checked; allowlisted methods only                |
| User `dendritic` CLI                                                                | Talks to the helper; never elevates via AppleScript                            |

**Allowlist (v1):** `wg.install-conf`, `wg.up`, `wg.down` for iface `dendritic` only.

## Commands

```bash
dendritic helper ping
dendritic wg ensure              # build conf (pass) + install/up via helper
dendritic wg ensure --no-up      # conf only (HM activation)
dendritic notify "Title" "Body"  # user notification (no osascript)
dendritic pass watch|sync|notify
dendritic gpg preset
dendritic fleet heartbeat
dendritic wifi ensure
dendritic eduroam ensure|rotate
dendritic auth rotate --auto --yes
dendritic android converge
dendritic power                  # Linux RAPL controller (root)
dendritic power --status
dendritic ide cursor-disable-attribution
```

## First switch

1. `nh darwin switch .#mba` / `nh os switch .#sliceanddice` (approve sudo once).
2. Helper starts: `launchctl print system/com.aspauldingcode.dendritic-helper` or `systemctl status dendritic-helper`.
3. Optional: grant **Notifications** to `dendritic` if macOS prompts on first `dendritic notify`.

After that, Cursor/agents can run `dendritic wg ensure` without password dialogs.

## Enable

```nix
dendritic.helper.enable = true;   # system (Darwin launchd / NixOS systemd)
dendritic.helper.enable = true;   # HM (installs CLI in user profile)
```

MBA and sliceanddice enable this alongside WireGuard.

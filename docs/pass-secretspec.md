# Pass + SecretSpec (public .dotfiles, Alex-only)

Developer/application secrets sync across macOS and NixOS via `pass` + a
private GitHub password-store. Machine/home secrets stay on sops-nix.

## Trust model

```
gh auth login (Alex GitHub + MFA)
        │
 private aspauldingcode/dendritic-age-master  (age master only)
        │
 secrets-bootstrap → sops age keys file
        │
 sops ciphertext in public .dotfiles
 (gpg_private_key / gpg_passphrase)
        │
   gpg-agent (preset passphrase)
        │
 ~/.password-store  ←→  private aspauldingcode/.password-store
        │
   SecretSpec (pass://…)
        │
   app env vars at runtime
```

Grace: SSH ed25519 → ssh-to-age recipients still listed in [`.sops.yaml`](../.sops.yaml)
until all hosts use GitHub bootstrap. See [`ssh-secrets.md`](./ssh-secrets.md).

- Public `.dotfiles` never holds plaintext secrets.
- Age recipients for GPG material are Alex-only (age master + temporary SSH age).
- GitHub Actions on the **private** password-store uses a **CI-only** GPG canary
  key that can decrypt template paths only — never Alex’s personal GPG key.
- Do **not** store GPG private key in `.password-store` or grant CI access to
  `dendritic-age-master`.

## Layers

| Layer           | Tool                      | Contents                             |
| --------------- | ------------------------- | ------------------------------------ |
| Declarations    | `secretspec.toml`         | Secret _names_ (git-safe)            |
| Developer vault | `pass` + private GH store | Encrypted values                     |
| Runtime         | `secretspec run`          | Env vars for child process           |
| Machine/home    | sops-nix                  | Existing wrappers (`gh`, chatgpt, …) |
| CI canaries     | private-repo Actions      | Template decrypt smoke               |

## Packages / HM feature

Enable with `dendritic.apps.pass.enable = true` (see hosts). Module:
[`modules/apps/pass.nix`](../modules/apps/pass.nix).

Provides: `pass` (+ otp), `gnupg` + agent preset, **QtPass GUI**, `browserpass`,
`secretspec`, activation that imports GPG from sops and clones/pulls the store,
and a **watchexec auto-sync agent** (default on).

### Auto-sync (kernel FS watcher + ntfy upstream)

`dendritic.apps.pass.autoSync.enable` defaults to `true`.

| Path                           | Agent                                              | Mechanism                                 |
| ------------------------------ | -------------------------------------------------- | ----------------------------------------- |
| Local edits → GitHub           | `pass-store-sync` (launchd / systemd user)         | watchexec → `PASS_STORE_SYNC_MODE=full`   |
| Push → peer wake (**primary**) | same `pass-store-sync` after successful `git push` | host-side `curl` one-byte publish to ntfy |
| GitHub → local                 | `pass-store-sync-notify`                           | one `curl` JSON long-poll → `MODE=pull`   |
| Push → peer wake (**backup**)  | Actions `notify-sync`                              | same ntfy publish if host wake failed     |

**Local (watchexec):** on store changes (ignoring `.git`), waits `autoSync.debounce`
(default `10sec`), then `git pull --rebase --autostash` → CI dual-encrypt on
reserved paths → commit if dirty → `push` → **ntfy wake**. Failures log under
`~/.cache/pass-store-sync*.log` and retry on the next event. Pull mode waits up
to 45s for the sync lock (clears stale PID locks) so a concurrent full sync
does not drop an upstream ping.

**Upstream (ntfy):** idle cost is one sleeping HTTPS long-poll (no timers, no
`ntfy` CLI). Agent order: **wait for sops topic file** (up to 120s, then exit
so KeepAlive retries; Darwin also `WatchPaths` the secrets dir) → **catch-up
`MODE=pull` on every subscribe and every reconnect** → subscribe. ntfy does
**not** retain missed events — the ping is for already-online peers; reconnect
catch-up is what brings a machine up to date after being offline. On each
published message, cheap `git ls-remote` vs `HEAD`; pull only if behind (with
short retries). Keepalive/`open` events are ignored.

Topic: sops `pass_store_ntfy_topic` (Alex-only) → HM writes a `0600` file the
agents read. Same value → Actions secret `PASS_STORE_NTFY_TOPIC` on the private
store. Template workflow (backup only):
[`scripts/password-store-notify-sync.yml`](../scripts/password-store-notify-sync.yml)
(copy into `.password-store` as `.github/workflows/notify-sync.yml`).

```bash
# Manual ping (both hosts should ls-remote; pull only if behind)
TOPIC="$(sops -d --extract '["pass_store_ntfy_topic"]' secrets/secrets.yaml)"
curl -fsS -d "1" "https://ntfy.sh/${TOPIC}"
```

Disable watcher with `dendritic.apps.pass.autoSync.enable = false`.
Disable ntfy only with `dendritic.apps.pass.autoSync.notify.enable = false`.

### Tray applet (Darwin + Linux)

`dendritic.apps.pass.tray.enable` defaults to `true`. One **Rust** native tray
applet (`tray-icon` / muda — NSMenu on macOS, StatusNotifier on Linux). No
windowed GUI: status lives in the menu; actions are only **Open QtPass** and
**Open sync log** (shared [`ui_contract`](../modules/apps/pass-store-tray/src/ui_contract.rs)).

| Icon | Meaning                                              |
| ---- | ---------------------------------------------------- |
| ↑    | Uploading local store changes to GitHub              |
| ↓    | Downloading remote updates                           |
| ✓    | Idle / last sync completed                           |
| ↻    | `nh` / `*-rebuild` in progress                       |
| !    | Error (see menu / `~/.cache/pass-store-sync.status`) |

Icons are **macOS menu-bar silhouettes** (template / monochrome — no green/blue
fills). AppKit tints them for light/dark menu bar; Linux uses a light symbolic
ink for dark panels.

Status file (no plaintext secrets): `~/.cache/pass-store-sync.status`.

Menu actions: Pull now, Rematerialize secrets, Open QtPass, Open sync log.

### Fast rematerialize (no `nh` switch)

Pass sync updates `~/.password-store` only. Home files that HM used to write
only on activation (e.g. `~/.shit`) are rematerialized **immediately** when
`secretspec/` paths change in a sync, via
[`scripts/pass-secretspec-materialize.sh`](../scripts/pass-secretspec-materialize.sh)
and the map [`home/pass-materialize.json`](../home/pass-materialize.json):

| SecretSpec key  | Home file |
| --------------- | --------- |
| `SHIT_PASSWORD` | `~/.shit` |
| `PEE_PASSWORD`  | `~/.pee`  |

```bash
# Change a mapped secret — after sync, home file updates without rebuild
printf '%s\n' 'new value' | pass insert -e secretspec/shared/default/SHIT_PASSWORD
# wait for watchexec debounce (~10s) or: pass-materialize
cat ~/.shit

# Still need nh * switch when you change Nix *declarations*, add a new map
# entry, or update sops age secrets — not for routine pass value edits.
```

Runtime secrets (`GH_*`, `FLAKEHUB_TOKEN`) stay live via wrappers — not copied to
home files. Pass never writes into `secrets/secrets.yaml`.

QtPass keeps `autoPull`/`autoPush` off so the watcher owns git traffic. Manual
`pass git push` / `pull` still works.

**CI canary caveat:** QtPass/`pass insert` encrypts only to `.gpg-id` (Alex).
Template paths used by private-repo smoke (`_bootstrap/*`, `test/*`,
`secretspec/shared/default/DEMO_*`) must stay dual-encrypted to Alex +
`.ci-gpg-id`. Full sync re-applies the CI recipient only on those paths — real
secrets under `secretspec/` (e.g. `GH_TOKEN`) stay Alex-only. Notify/`MODE=pull`
never runs that walk.

### Remote verify from mba (sliceanddice over SSH)

No walk-over. After flake changes:

```bash
nh darwin switch . -H mba
ssh sliceanddice 'cd /etc/nixos/.dotfiles && git pull --ff-only origin development && nh os switch'
```

Probes:

```bash
# mba
tail -f ~/.cache/pass-store-sync-notify.log
pgrep -lf 'pass-store-sync-notify|ntfy.sh/.*/json' || true

# sliceanddice
ssh sliceanddice 'systemctl --user status pass-store-sync-notify.service; pgrep -af "ntfy.sh/.*/json"'
ssh sliceanddice 'cd ~/.password-store && git rev-parse --short HEAD'
```

### QtPass GUI (macOS + NixOS)

`dendritic.apps.pass.gui.enable` defaults to `true`.

| Platform | How to open                                                                         | Config                                                       |
| -------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| macOS    | Spotlight / Dock / `open -a QtPass` / `~/Applications/Home Manager Apps/QtPass.app` | `defaults` domain `com.IJHack.QtPass` (seeded on activation) |
| NixOS    | app launcher / `qtpass`                                                             | `~/.config/IJHack/QtPass.conf`                               |

Preconfigured to use `~/.password-store` and Nix `pass` / `gpg` / `git` / `pwgen` binaries.

## Template entry map

| pass path                                     | value (fake)                          |
| --------------------------------------------- | ------------------------------------- |
| `_bootstrap/ok`                               | `ok`                                  |
| `test/example-login`                          | multiline demo login                  |
| `secretspec/shared/default/DEMO_API_KEY`      | `demo-not-a-real-key`                 |
| `secretspec/shared/default/DEMO_DATABASE_URL` | `postgres://demo:demo@localhost/demo` |
| `secretspec/shared/default/SHIT_PASSWORD`     | `poo password` → HM writes `~/.shit`  |

Public declarations: [`testdata/secretspec-demo/secretspec.toml`](../testdata/secretspec-demo/secretspec.toml).

## Commands

From the `.dotfiles` checkout:

```bash
# One-time (already run on primary machine during provision)
nix run .#pass-genesis
nix run .#pass-provision   # genesis + GH repo + templates + CI secrets

# Routine rotation
nix run .#pass-rotate -- --status
nix run .#pass-rotate                 # phase 1: dual-encrypt
# … rebuild/activate all hosts …
nix run .#pass-rotate -- --finalize   # phase 2: drop old key

# Day-to-day (auto-sync usually handles git; manual still fine)
pass insert some/secret
pass show _bootstrap/ok
cd testdata/secretspec-demo && secretspec run -- printenv DEMO_API_KEY

# Watcher / notify logs
tail -f ~/.cache/pass-store-sync.log
tail -f ~/.cache/pass-store-sync-notify.log
# Linux: journalctl --user -u pass-store-sync -u pass-store-sync-notify -f
```

Current fingerprint is recorded in [`pass-gpg-fingerprint.txt`](./pass-gpg-fingerprint.txt)
and [`pass-rotation-state.json`](./pass-rotation-state.json).

## New machine

1. `gh auth login` as Alex (MFA/passkeys on the GitHub account).
2. `nix run .#secrets-bootstrap` — fetches age master from private
   `aspauldingcode/dendritic-age-master` into the local sops age keys file.
3. `nix run github:aspauldingcode/.dotfiles#install` (or local switch).
4. HM activation imports GPG from sops, presets passphrase, clones
   `aspauldingcode/.password-store` into `~/.password-store`.
5. Optional: enroll host SSH pubkey for login — see [`ssh-secrets.md`](./ssh-secrets.md).

Do not bootstrap GPG from the password-store git repo (circular / weak).

## Secrets smoke CI

Private repo workflow: `.github/workflows/secrets-smoke.yml` inside
`aspauldingcode/.password-store`.

- Secrets: `CI_GPG_PRIVATE_KEY`, `CI_GPG_PASSPHRASE` (Actions secrets only).
- Asserts template decrypt + SecretSpec `DEMO_*`.
- Reserved paths stay dual-encrypted to Alex + CI (see `.ci-gpg-id` in the store).
- Public `.dotfiles` CI only checks declaration files (no private clone).

If CI fails after rotation: ensure test paths were re-dual-encrypted to
`.ci-gpg-id`, then `gh secret set` if the CI key itself was rotated.

## Rotation runbook

1. `nix run .#pass-rotate` — new key, sops previous slots filled, store dual-encrypted, push.
2. Activate/rebuild every trusted host (imports new key + pulls).
3. `nix run .#pass-rotate -- --finalize` — single recipient, clear previous sops slots.
4. Commit updated `secrets/secrets.yaml` + rotation state in `.dotfiles`.

Do not finalize until all hosts have pulled phase 1. Finalize is gated:

```bash
CONFIRM_FINALIZE=yes nix run .#pass-rotate -- --finalize
# optional: FORCE_FINALIZE=yes to skip the default 24h grace
```

Guards (refuse otherwise): previous sops GPG slots still present, `.gpg-id`
still lists **both** fingerprints, canary decrypt works. Annual reminder
agents notify to start phase 1; finalize stays explicit — never burn the old
key early.

Age recipient changes remain separate (`scripts/sops-updatekeys.sh`).

## CLI auth from pass (gh + fh)

Declarations in [`home/secretspec.toml`](../home/secretspec.toml):

| Secret                 | pass path                                        | Role                                     |
| ---------------------- | ------------------------------------------------ | ---------------------------------------- |
| `GH_APP_CLIENT_ID`     | `secretspec/shared/default/GH_APP_CLIENT_ID`     | GitHub App (API mint)                    |
| `GH_APP_CLIENT_SECRET` | `secretspec/shared/default/GH_APP_CLIENT_SECRET` | GitHub App secret                        |
| `GH_REFRESH_TOKEN`     | `secretspec/shared/default/GH_REFRESH_TOKEN`     | refresh → access via API (`ghr_`→`ghu_`) |
| `GH_TOKEN`             | `secretspec/shared/default/GH_TOKEN`             | Legacy classic PAT fallback              |
| `FLAKEHUB_TOKEN`       | `secretspec/shared/default/FLAKEHUB_TOKEN`       | FlakeHub / determinate-nixd              |

**GitHub — fully automated after one-time bootstrap (still uses pass):**

```bash
nix run .#pass-github-app-bootstrap   # manifest Create + OAuth (browser once)
# after that:
github-app-mint-token                 # mints access token from pass refresh_token
gh auth status                        # wrapper mints automatically
pass-rotate-cli-auth --github         # force API refresh
pass-rotate-cli-auth --auto           # weekly agent refreshes when due
```

Access tokens live in `~/.cache/dendritic/` (~8h). New refresh tokens are written
back to pass (and synced). If the refresh token expires (~6 months), mint falls
back to device flow + notification.

**FlakeHub — fully automated** (`determinate-nixd auth token device create`).

```bash
pass-rotate-cli-auth --status
pass-rotate-cli-auth --auto
pass-rotate-cli-auth --flakehub
```

## SecretSpec in a project

```toml
[providers]
pass = "pass://secretspec/shared/{profile}/{key}"

[profiles.default]
MY_API_KEY = { description = "…", providers = ["pass"] }
```

```bash
pass insert secretspec/shared/default/MY_API_KEY
secretspec run -- ./my-app
```

Do not commit `.env` values. Commit `secretspec.toml` declarations only.

## Home Manager depending on pass (SecretSpec)

Nix **evaluation** never decrypts pass (no plaintext in `/nix/store`). Instead,
HM **activation** reads via SecretSpec after GPG unlock + store pull.

Demo: [`home/secretspec.toml`](../home/secretspec.toml) declares `SHIT_PASSWORD`
and `PEE_PASSWORD`. With `dendritic.apps.pass.materialize.enable` (default
`true`), activation and post-sync rematerialize write `~/.shit` / `~/.pee`
(mode `0600`) per [`home/pass-materialize.json`](../home/pass-materialize.json).

```bash
printf '%s\n' 'poo password' | pass insert -e secretspec/shared/default/SHIT_PASSWORD
# after sync (or pass-materialize): cat ~/.shit — no nh switch required
```

# Pass + SecretSpec sync (public .dotfiles)

Cross-host **developer secrets** via `pass` + a **private** GitHub
password-store, with near-real-time peer sync over **ntfy**, plus
**SecretSpec** for runtime env injection. Machine/home secrets stay on
**sops-nix** (separate layer).

This document explains:

1. Exactly how the system works in this repository
2. How **you** can replicate it with **your own** private vault (without
   anyone else’s passwords)

---

## Public vs private (read this first)

| Lives in **public** `.dotfiles`                            | Lives only in **your private** vaults |
| ---------------------------------------------------------- | ------------------------------------- |
| Nix modules, sync scripts, workflow _templates_            | GPG private key + passphrase          |
| SecretSpec _declarations_ (`secretspec.toml` — names only) | All `pass` ciphertext (`.gpg` files)  |
| Materialize _map_ (which keys → which `$HOME` files)       | Age master / sops plaintext           |
| Docs, demo `DEMO_*` template paths                         | ntfy topic string                     |
| Fingerprint / rotation _metadata_ (not key material)       | GitHub App tokens, PATs, etc.         |

**Never** commit: plaintext passwords, GPG private keys, ntfy topics, or
clones of someone else’s private `.password-store`.

Forking this public repo does **not** give you Alex’s secrets. Those live
in private GitHub repos you cannot access. To replicate, you create
**your own** private store + **your own** GPG + **your own** ntfy topic.

---

## What problem this solves

| Need                                         | Mechanism                                      |
| -------------------------------------------- | ---------------------------------------------- |
| One vault on macOS + NixOS                   | Private git-backed `~/.password-store`         |
| Edit on one host → appear on another         | watchexec push + ntfy wake + peer pull         |
| Host offline during the edit                 | **Catch-up pull on every ntfy reconnect**      |
| Apps need env vars without committing `.env` | SecretSpec `pass://…` provider                 |
| Some secrets as `$HOME` files (no rebuild)   | Materialize map after sync                     |
| Public flake stays safe                      | Ciphertext only; GPG key via sops on each host |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  PUBLIC flake (this repo)                                       │
│  modules/apps/pass.nix · scripts/pass-store-*.sh                │
│  home/secretspec.toml (names) · home/pass-materialize.json      │
│  sops ciphertext: gpg key material + ntfy topic (Alex-only age) │
└───────────────┬─────────────────────────────┬───────────────────┘
                │ HM activation               │ agents
                ▼                             ▼
┌──────────────────────────┐    ┌─────────────────────────────────┐
│  Host (mba / NixOS / …)  │    │  Agents (launchd / systemd)     │
│  gpg-agent (preset + dendritic-pinentry) │    │  pass-store-sync (watchexec)    │
│  ~/.password-store       │◄──►│  pass-store-sync-notify (ntfy)  │
│  SecretSpec / QtPass     │    │  pass-store-tray (status)       │
└────────────┬─────────────┘    └───────────────┬─────────────────┘
             │ git push/pull                    │ publish / long-poll
             ▼                                  ▼
┌──────────────────────────┐    ┌─────────────────────────────────┐
│  PRIVATE GitHub          │    │  ntfy.sh/<YOUR_RANDOM_TOPIC>    │
│  you/.password-store     │    │  (no secret payload — wake only)│
│  + Actions: notify-sync  │    └─────────────────────────────────┘
│    (backup wake)         │
│  + Actions: secrets-smoke│
│    (CI canary GPG only)  │
└──────────────────────────┘
```

### Trust bootstrap (this repo’s instance)

```
gh auth login (owner MFA)
        │
 private age-master repo  (age key only — not the password-store)
        │
 secrets-bootstrap → local sops age keys
        │
 sops decrypt in public .dotfiles
 (gpg_private_key / gpg_passphrase / pass_store_ntfy_topic)
        │
   gpg-agent (preset + dendritic-pinentry — never GUI/Keychain)
        │
 ~/.password-store  ←→  private .password-store
        │
   SecretSpec (pass://…) / materialize / QtPass
```

**No human GPG passphrase prompts.** `dendritic-pinentry` serves
`gpg_passphrase` from sops; a launchd/systemd timer re-presets the agent and
(on macOS) deletes GnuPG Keychain items so pinentry-mac cannot come back.

Grace: SSH ed25519 → ssh-to-age recipients may still appear in
[`.sops.yaml`](../.sops.yaml). See [`ssh-secrets.md`](./ssh-secrets.md).

---

## Layers

| Layer           | Tool                        | Contents                                |
| --------------- | --------------------------- | --------------------------------------- |
| Declarations    | `secretspec.toml`           | Secret _names_ (git-safe)               |
| Developer vault | `pass` + private GH store   | GPG-encrypted values                    |
| Runtime         | `secretspec run` / wrappers | Env vars for child processes            |
| Home files      | materialize map             | Optional `$HOME` files (e.g. `~/.shit`) |
| Machine/home    | sops-nix                    | GPG key, ntfy topic, other host secrets |
| Peer wake       | ntfy (+ CI backup)          | Empty ping — not the password itself    |
| CI canaries     | private-repo Actions        | Template decrypt smoke (CI-only GPG)    |

If a mapped key is **empty or missing in pass**, materialize records a short
warning (`KEY empty → ~/path`) in `materialize_warnings` inside
`~/.cache/pass-store-sync.status`. The tray uses an error glyph when warnings
exist; the menu only lists non-zero issues (one row each — key truncated, no
path dump, no “Secrets: ok” filler). Healthy idle = actions only.

---

## Components → files (public repo)

| Piece                    | Path                                                                                      |
| ------------------------ | ----------------------------------------------------------------------------------------- |
| HM feature module        | [`modules/apps/pass.nix`](../modules/apps/pass.nix)                                       |
| Local→remote sync        | [`scripts/pass-store-sync.sh`](../scripts/pass-store-sync.sh)                             |
| Remote→local notify      | [`scripts/pass-store-sync-notify.sh`](../scripts/pass-store-sync-notify.sh)               |
| Rematerialize home files | [`scripts/pass-secretspec-materialize.sh`](../scripts/pass-secretspec-materialize.sh)     |
| Materialize map          | [`home/pass-materialize.json`](../home/pass-materialize.json)                             |
| SecretSpec declarations  | [`home/secretspec.toml`](../home/secretspec.toml)                                         |
| Tray applet              | [`modules/apps/pass-store-tray/`](../modules/apps/pass-store-tray/)                       |
| ntfy workflow template   | [`scripts/password-store-notify-sync.yml`](../scripts/password-store-notify-sync.yml)     |
| Smoke CI template        | [`scripts/password-store-secrets-smoke.yml`](../scripts/password-store-secrets-smoke.yml) |
| Genesis / provision      | `nix run .#pass-genesis` · `nix run .#pass-provision`                                     |
| Demo declarations        | [`testdata/secretspec-demo/`](../testdata/secretspec-demo/)                               |

Enable on a host: `dendritic.apps.pass.enable = true` (see `hosts/`).

Options (non-exhaustive):

| Option                                       | Default                          | Role                             |
| -------------------------------------------- | -------------------------------- | -------------------------------- |
| `dendritic.apps.pass.repo`                   | `aspauldingcode/.password-store` | **Change this** when replicating |
| `dendritic.apps.pass.autoSync.enable`        | `true`                           | watchexec full sync              |
| `dendritic.apps.pass.autoSync.notify.enable` | `true`                           | ntfy long-poll peer              |
| `dendritic.apps.pass.materialize.enable`     | `true`                           | map → `$HOME` files              |
| `dendritic.apps.pass.tray.enable`            | `true`                           | menu-bar / StatusNotifier status |
| `dendritic.apps.pass.gui.enable`             | `true`                           | QtPass                           |

---

## Sync data plane (exact behavior)

### Agents

| Path                           | Agent                                   | Mechanism                               |
| ------------------------------ | --------------------------------------- | --------------------------------------- |
| Local edits → GitHub           | `pass-store-sync`                       | watchexec → `PASS_STORE_SYNC_MODE=full` |
| Push → peer wake (**primary**) | same script after successful `git push` | host-side `curl -d 1` to ntfy           |
| GitHub → local                 | `pass-store-sync-notify`                | JSON long-poll → `MODE=pull`            |
| Push → peer wake (**backup**)  | Actions `notify-sync` on private store  | same ntfy publish if host wake failed   |

### Local path (`MODE=full`)

1. Debounce (~`10sec` default)
2. Acquire lock (PID file; stale cleanup)
3. `git pull --rebase --autostash`
4. Re-dual-encrypt **reserved** CI template paths only
5. Commit if dirty → `git push`
6. Rematerialize if `secretspec/` changed
7. **Publish ntfy wake** (primary)

Logs: `~/.cache/pass-store-sync.log`  
Status JSON (no secrets): `~/.cache/pass-store-sync.status`

### Upstream path (`MODE=pull` + notify agent)

1. Wait for sops topic file (up to 120s, else exit → Restart)
2. **Catch-up pull** (`ls-remote` vs `HEAD`; pull only if behind)
3. Subscribe: `curl -sN https://ntfy.sh/<topic>/json`
4. On `"event":"message"` → pull again (debounced)
5. If curl dies (offline, timeout): sleep backoff → **catch-up pull again** → resubscribe

**Critical:** ntfy does **not** retain missed wakes. The ping is for peers
already online. **Reconnect catch-up** is what makes “offline a month, then
online” converge without a new password change.

```
Online peer:     push → ntfy message → peer pull (~seconds)
Offline peer:    push → ntfy missed → peer reconnects → catch-up pull → caught up
```

### Manual ping

```bash
TOPIC="$(sops -d --extract '["pass_store_ntfy_topic"]' secrets/secrets.yaml)"
curl -fsS -d "1" "https://ntfy.sh/${TOPIC}"
```

Disable: `autoSync.enable = false` or `autoSync.notify.enable = false`.

---

## Materialize (pass → `$HOME` without `nh`)

Pass sync updates `~/.password-store` only. Mapped keys are written to home
files when `secretspec/` changes:

| SecretSpec key     | Home file                                                           |
| ------------------ | ------------------------------------------------------------------- |
| `SHIT_PASSWORD`    | `~/.shit`                                                           |
| `PEE_PASSWORD`     | `~/.pee`                                                            |
| `Bubbles`          | `~/.config/dendritic/wifi/Bubbles.psk` (dendritic.wifi)             |
| `WIFI_*`           | `~/.config/dendritic/wifi/<key>.psk` (see [`wifi.md`](wifi.md))     |
| `EDUROAM_IDENTITY` | `~/.config/dendritic/wifi/eduroam/identity`                         |
| `EDUROAM_PASSWORD` | `~/.config/dendritic/wifi/eduroam/password`                         |
| `EDUROAM_CA`       | `~/.config/dendritic/wifi/eduroam/ca.pem`                           |
| `EDUROAM_PROFILE`  | `~/.config/dendritic/wifi/eduroam/profile.json` (dendritic.eduroam) |
| `WG_PUBLIC_KEY_*`  | `~/.config/dendritic/wireguard/keys/<peer>.public`                  |
| `WG_PSK`           | `~/.config/dendritic/wireguard/psk`                                 |
| `WG_ENDPOINT_*`    | `~/.config/dendritic/wireguard/endpoints/<peer>` (`-` = unset)      |
| `WG_HOME`          | `~/.config/dendritic/wireguard/home`                                |

Map: [`home/pass-materialize.json`](../home/pass-materialize.json).
Eduroam apply: [`docs/wifi-eduroam.md`](wifi-eduroam.md).
WireGuard: [`docs/wireguard.md`](wireguard.md) (`WG_PRIVATE_KEY_*` stay in pass only).

```bash
printf '%s\n' 'new value' | pass insert -e secretspec/shared/default/SHIT_PASSWORD
# ~10s debounce, or: pass-materialize
cat ~/.shit
```

Adding a **new** map entry still needs a flake commit + rebuild. Changing a
mapped **value** does not.

Runtime tokens (`GH_*`, `FLAKEHUB_TOKEN`, `GCLOUD_*`) stay in pass / wrappers — not copied
to home files (except gcloud ADC rewritten under `~/.config/gcloud/` on activation).

---

## Tray + QtPass

Tray (`dendritic.apps.pass.tray.enable`): ↑ upload · ↓ download · ✓ idle · ↻
rebuild · ! error/warnings. Menu: only non-zero status rows (one fact each),
then Open QtPass · Open sync log · Quit. Healthy → actions only.

QtPass: Spotlight / Dock / `qtpass`. Auto pull/push **off** so watchexec owns
git. Store path: `~/.password-store`.

---

## CI on the private password-store

Templates in this public repo — **copy** into the private store:

| Template                                                                                  | Becomes in private store              |
| ----------------------------------------------------------------------------------------- | ------------------------------------- |
| [`scripts/password-store-notify-sync.yml`](../scripts/password-store-notify-sync.yml)     | `.github/workflows/notify-sync.yml`   |
| [`scripts/password-store-secrets-smoke.yml`](../scripts/password-store-secrets-smoke.yml) | `.github/workflows/secrets-smoke.yml` |

Actions secrets (private store only):

| Secret                  | Purpose                                        |
| ----------------------- | ---------------------------------------------- |
| `PASS_STORE_NTFY_TOPIC` | Same random topic as sops (never commit it)    |
| `CI_GPG_PRIVATE_KEY`    | **CI-only** canary key (not your personal GPG) |
| `CI_GPG_PASSPHRASE`     | Canary passphrase                              |

Reserved dual-encrypt paths (Alex + CI canary): `_bootstrap/*`, `test/*`,
`secretspec/shared/default/DEMO_*`. Real secrets stay personal-GPG-only.
`MODE=pull` never runs the dual-encrypt walk.

---

## Day-to-day commands

```bash
pass insert some/secret
pass show _bootstrap/ok
pass ls secretspec/shared/default

# SecretSpec demo (declarations only in public repo)
cd testdata/secretspec-demo && secretspec run -- printenv DEMO_API_KEY

tail -f ~/.cache/pass-store-sync.log
tail -f ~/.cache/pass-store-sync-notify.log
# Linux:
# journalctl --user -u pass-store-sync -u pass-store-sync-notify -f
```

### Cross-host verify

```bash
# After flake changes
nh darwin switch . -H mba   # or: nh os switch on NixOS
ssh other-host 'cd /etc/nixos/.dotfiles && git pull --ff-only && nh os switch'

# Probes
pgrep -lf 'pass-store-sync-notify|ntfy.sh/.*/json'
ssh other-host 'systemctl --user status pass-store-sync-notify.service'
ssh other-host 'cd ~/.password-store && git rev-parse --short HEAD'
```

---

## This repo’s instance (Alex)

| Resource               | Where                                                         |
| ---------------------- | ------------------------------------------------------------- |
| Public flake           | `aspauldingcode/.dotfiles`                                    |
| Private password-store | `aspauldingcode/.password-store`                              |
| Private age master     | `aspauldingcode/dendritic-age-master`                         |
| Pass GPG fingerprint   | [`docs/pass-gpg-fingerprint.txt`](./pass-gpg-fingerprint.txt) |
| Rotation state         | [`docs/pass-rotation-state.json`](./pass-rotation-state.json) |

**New Alex machine:** `gh auth login` → `nix run .#secrets-bootstrap` →
install/switch → HM imports GPG from sops, clones private store, starts agents.

Do **not** bootstrap GPG from the password-store git repo (circular / weak).

### Template entries (fake values in private store)

| pass path                                 | notes                       |
| ----------------------------------------- | --------------------------- |
| `_bootstrap/ok`                           | canary                      |
| `test/example-login`                      | multiline demo              |
| `secretspec/shared/default/DEMO_*`        | SecretSpec smoke            |
| `secretspec/shared/default/SHIT_PASSWORD` | → `~/.shit` via materialize |

### CLI auth secrets (declarations public, values private)

See [`home/secretspec.toml`](../home/secretspec.toml): `GH_*`, `FLAKEHUB_TOKEN`, `GCLOUD_*`, `VERCEL_*`.
Helpers:

| CLI      | One-time bootstrap                    | Mint / rotate                                             |
| -------- | ------------------------------------- | --------------------------------------------------------- |
| `gh`     | `nix run .#pass-github-app-bootstrap` | `github-app-mint-token` · `pass-rotate-cli-auth --github` |
| `fh`     | `nix run .#pass-flakehub-bootstrap`   | `flakehub-mint-token` · `pass-rotate-cli-auth --flakehub` |
| `gcloud` | `nix run .#pass-gcloud-bootstrap`     | `gcloud-mint-token` · `pass-rotate-cli-auth --gcloud`     |
| `vercel` | `nix run .#pass-vercel-bootstrap`     | `vercel-mint-token` · `pass-rotate-cli-auth --vercel`     |
| `wg`     | `nix run .#pass-wg-bootstrap`         | `dendritic-wg-ensure` · `pass-wg-set-home` · `--wg` rotate |

**FlakeHub:** Device JWTs (what lives in pass) can _list_ but not _create_ tokens. Bootstrap / rotate elevates with a short-lived FlakeHub _user_ token from https://flakehub.com/user/settings?editview=tokens, mints a device JWT into `FLAKEHUB_TOKEN`, logs determinate-nixd back in as the device token, and optionally revokes older `dendritic-cli-auth*` tokens. Weekly auto-rotate notifies if elevation is needed.

**gcloud:** OAuth refresh_token in pass → access token on each `gcloud` invoke (cached ~1h). Activation rewrites `~/.config/gcloud/application_default_credentials.json` for client libraries. Optional SA JSON fallback: `pass-gcloud-bootstrap --from-sa key.json`. Optional default project: `--project my-gcp-project`.

**vercel:** OAuth refresh_token in pass → access token on each `vercel` invoke (cached ~8h). Activation rewrites `auth.json` (`~/Library/Application Support/com.vercel.cli/` on Darwin, `~/.local/share/com.vercel.cli/` on Linux). Import existing login: `pass-vercel-bootstrap --from-auth-json`. Static PAT fallback: `pass-vercel-bootstrap --from-token TOKEN` or SecretSpec `VERCEL_TOKEN`. Optional team: `--team TEAM_ID`.

**wg:** WireGuard pairing keys + PSK in pass → `dendritic-wg-ensure` builds `/etc/wireguard/dendritic.conf`. On Bubbles, endpoints resolve via mDNS when `WG_ENDPOINT_*` is unset (`-`). Remote: `pass-wg-set-home --peer … --endpoint HOST:51820` (never commit public IPs). Rotate with `pass-rotate-cli-auth --wg` (not weekly auto). See [`docs/wireguard.md`](wireguard.md).

### Rotation runbook

1. `nix run .#pass-rotate` — dual-encrypt phase
2. Rebuild/activate every trusted host
3. `CONFIRM_FINALIZE=yes nix run .#pass-rotate -- --finalize`
4. Commit updated `secrets/secrets.yaml` + rotation state

Do not finalize until all hosts pulled phase 1.

---

## Replicate this yourself (your vault, your keys)

Goal: same _architecture_, zero shared secrets with this repo’s private data.

### 0. Prerequisites

- Nix flake / home-manager (or copy the module patterns into yours)
- GitHub account with MFA
- Ability to create **private** repos

### 1. Create private repos (yours)

```bash
# Password store (empty private repo)
gh repo create YOUR_USER/.password-store --private --confirm

# Optional but recommended: private age master for sops (do NOT put GPG here)
gh repo create YOUR_USER/my-age-master --private --confirm
```

### 2. Generate your GPG + ntfy topic

```bash
# Personal GPG for pass (example — use your own uid/policy)
gpg --full-generate-key
# note fingerprint → .gpg-id in the store later

# Random ntfy topic (treat like a password; never commit)
openssl rand -hex 16
# e.g. store as: dendritic-pass-<hex>
```

Put into **your** sops (encrypted to **your** age/SSH recipients):

- `gpg_private_key` / `gpg_passphrase` (export secret key armor)
- `pass_store_ntfy_topic` = the random topic

### 3. Wire the public module to _your_ store

In your host HM config:

```nix
dendritic.apps.pass.enable = true;
dendritic.apps.pass.repo = "YOUR_USER/.password-store";  # not aspauldingcode’s
```

Point sops secrets at your ciphertext files. Do **not** reuse this repo’s
`secrets/secrets.yaml` expecting to decrypt it — you are not an age recipient.

### 4. Provision the private store

Using this flake’s helpers (or equivalent):

```bash
nix run .#pass-genesis      # local store + gpg-id
nix run .#pass-provision    # remote + templates + CI secrets (adapt for your user)
```

Or manually: `pass init <FINGERPRINT>`, `pass git init`,
`pass git remote add origin git@github.com:YOUR_USER/.password-store.git`,
add dual-encrypt canary paths if you want CI smoke.

### 5. Copy workflow templates into the private store

```bash
cd ~/.password-store
mkdir -p .github/workflows
cp /path/to/.dotfiles/scripts/password-store-notify-sync.yml \
  .github/workflows/notify-sync.yml
# optional smoke:
cp /path/to/.dotfiles/scripts/password-store-secrets-smoke.yml \
  .github/workflows/secrets-smoke.yml
git add .github && git commit -m "ci: notify-sync (+ smoke)" && git push
```

Set Actions secrets on **your** private store:

```bash
gh secret set PASS_STORE_NTFY_TOPIC -R YOUR_USER/.password-store <<<"$YOUR_TOPIC"
# CI canary key — generate a separate GPG key used ONLY by Actions
gh secret set CI_GPG_PRIVATE_KEY -R YOUR_USER/.password-store < ci-canary.asc
gh secret set CI_GPG_PASSPHRASE -R YOUR_USER/.password-store <<<"…"
```

### 6. Rebuild both hosts and verify

```bash
nh darwin switch   # or nh os switch
# second machine: pull flake + switch; agents clone/pull your private store

# Host A
pass insert demo/from-a
# wait debounce / watch tray ↑ then ✓

# Host B (online): should pull via ntfy within seconds
pass show demo/from-a

# Host B offline during insert → come online: notify reconnect catch-up
# should pull without another insert
```

### 7. SecretSpec in _your_ projects

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

Commit the toml; never commit values.

### Replication checklist

- [ ] Private `.password-store` under **your** GitHub user/org
- [ ] Your GPG in **your** sops (not this repo’s ciphertext)
- [ ] Your random ntfy topic in sops + Actions secret
- [ ] `dendritic.apps.pass.repo` points at **your** store
- [ ] Workflows copied into the private store
- [ ] CI uses a **canary** GPG, never your daily driver private key
- [ ] No clone/fetch of `aspauldingcode/.password-store` or age-master

---

## SecretSpec quick reference

```bash
pass insert secretspec/shared/default/MY_API_KEY
secretspec run -- ./my-app
```

Nix evaluation never decrypts pass. HM activation / sync rematerialize reads
via GPG after unlock.

---

## Security footnotes

- Public `.dotfiles` never holds plaintext secrets.
- ntfy carries a one-byte wake, not ciphertext or passwords.
- Do not put GPG private key in `.password-store`.
- Do not grant CI access to your age-master or personal GPG.
- Age recipient changes: [`scripts/sops-updatekeys.sh`](../scripts/sops-updatekeys.sh).

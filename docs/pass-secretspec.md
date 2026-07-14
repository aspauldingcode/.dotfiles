# Pass + SecretSpec (public .dotfiles, Alex-only)

Developer/application secrets sync across macOS and NixOS via `pass` + a
private GitHub password-store. Machine/home secrets stay on sops-nix.

## Trust model

```
SSH ed25519 (Alex machines only)
        │
   ssh-to-age
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

- Public `.dotfiles` never holds plaintext secrets.
- Age recipients for GPG material are Alex-only (see [`.sops.yaml`](../.sops.yaml)).
- Possession of Alex’s SSH private key unlocks the vault (same as existing sops).
- GitHub Actions on the **private** password-store uses a **CI-only** GPG canary
  key that can decrypt template paths only — never Alex’s personal GPG key.

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

### Auto-sync (kernel FS watcher)

`dendritic.apps.pass.autoSync.enable` defaults to `true`.

| Platform | Agent                       | Mechanism            |
| -------- | --------------------------- | -------------------- |
| macOS    | `launchd` `pass-store-sync` | watchexec → FSEvents |
| NixOS    | `systemd --user` same unit  | watchexec → inotify  |

On store changes (ignoring `.git`), waits `autoSync.debounce` (default `10sec`),
then `git pull --rebase --autostash` → commit if dirty → `push`. Failures are
logged under `~/.cache/pass-store-sync*.log` and retried on the next event;
activation never hard-fails on sync errors.

QtPass keeps `autoPull`/`autoPush` off so the watcher owns git traffic. Manual
`pass git push` / `pull` still works.

Disable with `dendritic.apps.pass.autoSync.enable = false`.

**CI canary caveat:** QtPass/`pass insert` encrypts only to `.gpg-id` (Alex).
Template paths used by private-repo smoke (`_bootstrap/*`, `test/*`,
`secretspec/shared/default/DEMO_*`) must stay dual-encrypted to Alex +
`.ci-gpg-id`. Auto-sync re-applies the CI recipient only on those paths — real
secrets under `secretspec/` (e.g. `GH_TOKEN`) stay Alex-only.

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

# Watcher logs (macOS launchd / Linux journalctl --user -u pass-store-sync)
tail -f ~/.cache/pass-store-sync.log
```

Current fingerprint is recorded in [`pass-gpg-fingerprint.txt`](./pass-gpg-fingerprint.txt)
and [`pass-rotation-state.json`](./pass-rotation-state.json).

## New machine

1. SSH key present and able to decrypt sops (same as today).
2. `nix run github:aspauldingcode/.dotfiles#install` (or local switch).
3. HM activation imports GPG from sops, presets passphrase, clones
   `aspauldingcode/.password-store` into `~/.password-store`.

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

Do not finalize until all hosts have pulled phase 1. Annual reminder agents
notify to start phase 1; finalize stays explicit.

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

Demo: [`home/secretspec.toml`](../home/secretspec.toml) declares `SHIT_PASSWORD`.
With `dendritic.apps.pass.materializeShitFile` (default `true`), activation runs
`secretspec get SHIT_PASSWORD` and writes `~/.shit` mode `0600`.

```bash
printf '%s\n' 'poo password' | pass insert -e secretspec/shared/default/SHIT_PASSWORD
# then: nh darwin switch / nh os switch — check cat ~/.shit
```

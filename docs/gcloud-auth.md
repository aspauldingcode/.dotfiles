# gcloud CLI auth (pass + SecretSpec)

Same shape as GitHub App minting / FlakeHub device tokens: **declarations in the
public flake**, **values in the private password-store**, **wrappers mint
short-lived access**, weekly `pass-rotate-cli-auth` proves refresh still works.

## One-time bootstrap

```bash
# After rebuild so google-cloud-sdk + wrappers are on PATH:
nh darwin switch . -H mba   # or nh os switch

# Browser OAuth once → writes GCLOUD_* into pass + ADC file
nix run .#pass-gcloud-bootstrap
# optional default project:
nix run .#pass-gcloud-bootstrap -- --project YOUR_GCP_PROJECT

# Or import existing ADC / SA:
nix run .#pass-gcloud-bootstrap -- --from-adc
nix run .#pass-gcloud-bootstrap -- --from-sa ./sa-key.json
```

Pass paths (SecretSpec / `pass ls secretspec/shared/default`):

| Key                                         | Role                                                    |
| ------------------------------------------- | ------------------------------------------------------- |
| `GCLOUD_REFRESH_TOKEN`                      | OAuth refresh — mint access via `oauth2.googleapis.com` |
| `GCLOUD_CLIENT_ID` / `GCLOUD_CLIENT_SECRET` | OAuth client (defaults to public gcloud SDK client)     |
| `GCLOUD_ACCOUNT`                            | Email for `gcloud config set account`                   |
| `GCLOUD_PROJECT`                            | Optional default project                                |
| `GCLOUD_SA_KEY`                             | Optional service-account JSON fallback                  |

## Day-to-day

```bash
gcloud auth list
gcloud config get-value account
gcloud projects list

gcloud-mint-token --status
pass-rotate-cli-auth --status
pass-rotate-cli-auth --gcloud          # force refresh + rewrite ADC
pass-rotate-cli-auth --auto --yes      # weekly agent path
```

Wrapped `gcloud` sets `CLOUDSDK_AUTH_ACCESS_TOKEN` from the mint cache (or
`CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE` for SA). Activation also writes
`~/.config/gcloud/application_default_credentials.json` so ADC-aware tools work
without a separate login.

## Sync

Edits land in the private `.password-store` like other CLI secrets — watchexec
push + ntfy peer pull. No sops change required for token values (sops still
holds GPG / ntfy only).

## Re-auth

If Google revokes the refresh token:

```bash
nix run .#pass-gcloud-bootstrap -- --force
# or:
gcloud-mint-token --device
```

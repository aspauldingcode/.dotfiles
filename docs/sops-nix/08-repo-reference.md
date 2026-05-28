# 08 - Repository Reference (This Dotfiles Repo)

This chapter maps `sops-nix` concepts to exact files and patterns in this repository.

## Core integration files

- `flake.nix`
  - declares `inputs.sops-nix`
- `modules/secrets.nix`
  - single-class **Home Manager** export (`flake.modules.homeManager.dendritic`)
  - imports `inputs.sops-nix.homeManagerModules.sops`
  - declares the `dendritic.secrets.*` option surface (see below)
  - sets defaults under that surface:
    - `sops.defaultSopsFormat = "yaml"`
    - `sops.defaultSopsFile = config.dendritic.secrets.defaultSopsFile`
    - `sops.age.sshKeyPaths = [ config.dendritic.secrets.ageKeyPath ]`
- `modules/sops-validation.nix`
  - contributes `perSystem.checks.sops-files-parse`
  - validates every encrypted file structurally parses as a sops doc
  - runs as part of `nix flake check` (no decryption key needed)
- `scripts/sops-updatekeys.sh`
  - rewraps every sops-encrypted file against the current `.sops.yaml`

Because `modules/default.nix` auto-imports all module files, both
`modules/secrets.nix` and `modules/sops-validation.nix` are included
automatically.

### Why HM-only (and not NixOS / Darwin too)

Per [`docs/dendritic-nix/02-module-mechanics.md`](../dendritic-nix/02-module-mechanics.md)
"Class-selective exporting: Only export classes where feature applies."

Every `sops.secrets.*` consumer in this repo lives at HM level
(currently just `modules/editor.nix` anthropic_api_key). There were
previously sibling `nixos`/`darwin` class exports configured against
`/var/lib/sops-nix/key.txt`, but they had zero consumers and the key
file did not exist on the live Mac — pure dead code.

If a future system-level consumer lands, add a sibling
`flake.modules.{nixos,darwin}.dendritic` block following the same shape
(same option namespace, equivalent `sops.age.*` configuration for the
target context). The current single-class file is the dendritic norm,
not a special case.

## Option surface: `dendritic.secrets.*`

| Option                              | Type | Default                                          | Purpose                                                                  |
| ----------------------------------- | ---- | ------------------------------------------------ | ------------------------------------------------------------------------ |
| `dendritic.secrets.enable`          | bool | `true`                                           | Whether sops-nix is wired in for the HM profile.                         |
| `dendritic.secrets.ageKeyPath`      | str  | `"${config.home.homeDirectory}/.ssh/id_ed25519"` | SSH ed25519 private key that ssh-to-age derives the decryption key from. |
| `dendritic.secrets.defaultSopsFile` | path | `../secrets/secrets.yaml`                        | Sops-encrypted YAML file consumed by `sops.secrets.<name>` declarations. |

Hosts override these in their HM user block, e.g.:

```nix
home-manager.users."8amps" = {
  dendritic.secrets.ageKeyPath = "/Volumes/USB/keys/id_ed25519";
  dendritic.secrets.defaultSopsFile = ../../secrets/per-host/mba.yaml;
};
```

## Encrypted material in repo

- `secrets/secrets.yaml` (encrypted YAML)
  - currently includes `anthropic_api_key`
- `.sops.yaml` (creation + recipient rules)

## `.sops.yaml` policy in this repo

Current creation rules target:

- `secrets/secrets.yaml`

This means new encryption operations matching these paths inherit configured recipients automatically.

## Current consumers

### Editor module

- file: `modules/editor.nix`
- declaration:
  - `sops.secrets.anthropic_api_key = { };`
- consumption:
  - plugin config reads from `config.sops.secrets.anthropic_api_key.path`

## Key strategy in this repo

Unified across the single (HM) export class:

- `sops.age.sshKeyPaths = [ config.dendritic.secrets.ageKeyPath ]`
- HM packages: `sops`, `age`, `ssh-to-age`
- No separate `/var/lib/sops-nix/key.txt` to bootstrap or back up — the
  SSH ed25519 key IS the decryption credential, via ssh-to-age.

A new machine needs the same `~/.ssh/id_ed25519` registered as a
recipient in `.sops.yaml` (or have one of its existing recipients
re-encrypt files via `sops updatekeys`).

## Recommended consistency improvements: status

| #   | Item                                                          | Status | Location                                                                                                               |
| --- | ------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------- |
| 1   | Standardize one key strategy across all contexts              | Done   | HM-only export via ssh-to-age; system blocks removed as dead code                                                      |
| 2   | Mass `sops updatekeys` script over all encrypted files        | Done   | [`scripts/sops-updatekeys.sh`](../../scripts/sops-updatekeys.sh)                                                       |
| 3   | CI lint that encrypted files are valid SOPS documents         | Done   | [`modules/sops-validation.nix`](../../modules/sops-validation.nix) → `nix flake check`'s `sops-files-parse`            |
| 4   | Worked example of `sops.templates` + restart/reload semantics | Done   | [`docs/sops-nix/05-templates-and-services.md`](./05-templates-and-services.md) "Worked example: porting CodeCompanion" |

## Practical command reference (repo-specific)

Edit shared YAML secrets:

```bash
sops secrets/secrets.yaml
```

Rotate recipients for ALL current encrypted files (preferred):

```bash
bash scripts/sops-updatekeys.sh
```

…which is equivalent to running, by hand:

```bash
sops updatekeys --yes secrets/secrets.yaml
```

Validate every sops-encrypted file is structurally a sops doc:

```bash
nix flake check                                       # runs all checks
nix build .#checks.aarch64-darwin.sops-files-parse    # just this one
```

Apply changes on Darwin host:

```bash
nh darwin switch
```

Apply changes on NixOS host:

```bash
nh os switch
```

## Where to continue

- Architecture and concepts: [`01-architecture.md`](./01-architecture.md)
- Operations runbook: [`06-operations-and-rotation.md`](./06-operations-and-rotation.md)
- Troubleshooting: [`07-troubleshooting.md`](./07-troubleshooting.md)

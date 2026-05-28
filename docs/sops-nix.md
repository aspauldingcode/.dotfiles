# sops-nix Deep Dive

This is a deep, practical guide to how `sops-nix` works and how this repository uses it.

> For the full multi-file documentation set, start at [`docs/sops-nix/README.md`](./sops-nix/README.md).

Primary upstream references:

- [Mic92/sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md)
- [Mic92/sops-nix repository](https://github.com/Mic92/sops-nix)
- [sops-nix NixOS module implementation](https://github.com/Mic92/sops-nix/blob/master/modules/sops/default.nix)
- [sops-nix Home Manager module implementation](https://github.com/Mic92/sops-nix/blob/master/modules/home-manager/sops.nix)

---

## What sops-nix solves

`sops-nix` gives you declarative secret provisioning in Nix-based systems:

- Secrets are stored encrypted in git via `sops`.
- Decryption happens at activation/runtime, not in the Nix store.
- Secret files are materialized with declared owner/group/mode.
- Services and apps consume secret paths via `config.sops.secrets.<name>.path`.

This is exactly what you want in Nix:

- reproducible builds,
- versioned infra,
- no plaintext secrets committed,
- no plaintext secrets baked into derivations.

---

## How it works (high-level flow)

1. You commit encrypted secret files (YAML/JSON/INI/dotenv/binary).
2. You define secret entries in Nix (`sops.secrets.<name> = { ... };`).
3. Activation runs `sops-install-secrets`.
4. Secret files are decrypted into runtime locations with strict permissions.
5. Modules/services read secrets via stable path attributes.

Key point: decryption occurs outside the immutable Nix store, so plaintext does not leak into `/nix/store`.

---

## This repository's current architecture

This repo defines one dendritic `sops-nix` feature module at:

- `modules/secrets.nix`

It exports a **single class** — `flake.modules.homeManager.dendritic` —
because every `sops.secrets.*` consumer in this repo (currently the
`anthropic_api_key` in `modules/editor.nix`) is a HM-class declaration.
The dendritic pattern explicitly says
([docs/dendritic-nix/02-module-mechanics.md](./dendritic-nix/02-module-mechanics.md))
"Class-selective exporting: Only export classes where feature applies."

Earlier revisions of this repo also exported `nixos`/`darwin` system
classes pointing at `/var/lib/sops-nix/key.txt`. They had zero consumers
and the key file did not exist on the live Mac; treated as dead code and
removed. The pattern for re-adding a system-level class is one block in
`modules/secrets.nix` keyed off the same `dendritic.secrets.*` options.

### Inputs

`flake.nix` includes:

- `inputs.sops-nix.url = "github:Mic92/sops-nix";`

### Option surface: `dendritic.secrets.*`

| Option                              | Default                                          | Purpose                                                                  |
| ----------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------ |
| `dendritic.secrets.enable`          | `true`                                           | Whether sops-nix is wired in for the HM profile.                         |
| `dendritic.secrets.ageKeyPath`      | `"${config.home.homeDirectory}/.ssh/id_ed25519"` | SSH ed25519 key that ssh-to-age derives the decryption key from.         |
| `dendritic.secrets.defaultSopsFile` | `../secrets/secrets.yaml`                        | Sops-encrypted YAML file consumed by `sops.secrets.<name>` declarations. |

### Global defaults (after option resolution)

- `sops.defaultSopsFormat = "yaml"`
- `sops.defaultSopsFile = config.dendritic.secrets.defaultSopsFile`
- `sops.age.sshKeyPaths = [ config.dendritic.secrets.ageKeyPath ]`

### Key strategy used here

Unified ssh-to-age bridge:

- single class (HM): `sops.age.sshKeyPaths = [ <user's ed25519 key> ]`
- HM packages: `sops`, `age`, `ssh-to-age`

No separate age private key file to bootstrap, persist, or back up — the
SSH ed25519 key IS the decryption credential. Cross-platform (Darwin and
Linux HM use the same path expression).

---

## Files involved in this repo

### `secrets/secrets.yaml`

Encrypted SOPS document (tracked in git), currently containing at least:

- `anthropic_api_key`

This file includes SOPS metadata:

- recipient list
- `mac`
- `lastmodified`
- SOPS file format version

### `.sops.yaml`

SOPS policy/config file that controls:

- recipient identities
- path-based creation rules for new encrypted files

This repo currently defines creation rules for:

- `secrets/secrets.yaml` (general YAML secrets)

### Consumers

- `modules/editor.nix`:
  - declares `sops.secrets.anthropic_api_key = {};`
  - consumes via `config.sops.secrets.anthropic_api_key.path`

---

## Secret lifecycle in detail

### 1) Authoring

You add/edit encrypted values with `sops`:

```bash
sops secrets/secrets.yaml
```

Because `.sops.yaml` is present, recipient rules are applied automatically.

### 2) Commit and review

You commit ciphertext only. Reviewers can still inspect:

- key names,
- structural diffs,
- recipient metadata.

### 3) Activation

On `nh darwin switch` / `nh os switch` / HM activation:

- `sops-nix` decrypts requested secrets using configured key sources.
- files are written to runtime secret locations.

### 4) Runtime consumption

Modules read paths from `config.sops.secrets.<name>.path`.
Do not hardcode runtime directories manually; always use path attributes.

---

## NixOS, Darwin, and Home Manager behavior differences

Based on upstream behavior:

- System module (`nixos` / `darwin`) decrypts into system runtime secret space.
- Home Manager module runs user-level secret management (`sops-nix.service`).
- HM places secrets in user runtime dirs and symlinks stable paths under user config tree.

Upstream notes specifically call out HM runtime differences and `%r` expansion behavior (`$XDG_RUNTIME_DIR` on Linux and Darwin user temp dir on macOS) in templates and paths.

Source: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

---

## Declaring secrets correctly

Basic declaration:

```nix
sops.secrets.my_secret = {};
```

With explicit properties:

```nix
sops.secrets.my_secret = {
  owner = "myuser";
  group = "mygroup";
  mode = "0400";
  sopsFile = ../secrets/other.yaml;
};
```

Binary secret (no longer used in this repo — kept as a reference pattern):

```nix
sops.secrets."my-binary-key" = {
  format = "binary";
  sopsFile = ../secrets/my-binary-key.sops;
  mode = "0400";
};
```

---

## Templates: injecting secrets into config files

`sops-nix` supports rendering config files with secret placeholders:

```nix
sops.templates."service-config.toml".content = ''
  password = "${config.sops.placeholder.my_secret}"
'';
```

Then consume rendered config path:

```nix
systemd.services.myservice.serviceConfig.ExecStart =
  "${pkgs.myservice}/bin/myservice --config ${config.sops.templates."service-config.toml".path}";
```

You can also set ownership for rendered files:

```nix
sops.templates."service-config.toml".owner = "serviceuser";
```

Template workflow and path usage are documented in upstream README:
[sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

---

## Key management strategies (age)

`sops-nix` supports multiple age key sources.

## 1) Dedicated age key file

```nix
sops.age.keyFile = "/var/lib/sops-nix/key.txt";
sops.age.generateKey = true;
```

Pros:

- clear separation from SSH auth keys
- explicit rotation lifecycle

Cons:

- another private key artifact to persist/back up carefully

## 2) SSH private key paths via `ssh-to-age` bridge

```nix
sops.age.sshKeyPaths = [ "/home/user/.ssh/id_ed25519" ];
```

Pros:

- no extra key file if SSH key already exists

Cons:

- couples secret decryptability to SSH key lifecycle
- passphrase/availability constraints can complicate activation

Upstream also documents evolving native SSH key support discussions; treat current module options as source of truth:

- [PR #779](https://github.com/Mic92/sops-nix/pull/779)
- [Issue #744](https://github.com/Mic92/sops-nix/issues/744)

---

## Recipient management and rotation

In `.sops.yaml`, recipients are declared once and applied by path rules.

Typical rotation flow:

1. Add new recipient to `.sops.yaml`.
2. Rewrap existing files:

```bash
sops updatekeys secrets/secrets.yaml
```

3. Commit updated encrypted metadata.
4. Remove old recipients after rollout completes.

---

## Operational runbook for this repository

## Add a new text secret

1. Edit encrypted file:

```bash
sops secrets/secrets.yaml
```

2. Add secret key/value.
3. Declare in module where consumed:

```nix
sops.secrets.my_new_secret = {};
```

4. Consume via:

```nix
config.sops.secrets.my_new_secret.path
```

5. Rebuild (`nh darwin switch` or equivalent).

## Add a new binary secret

1. Encrypt source binary to a `.sops` file with matching `.sops.yaml` rule.
2. Declare:

```nix
sops.secrets."name" = {
  format = "binary";
  sopsFile = ./name.sops;
  mode = "0400";
};
```

3. Consume path from module activation script or service config.

## Rotate recipient key

1. Update `.sops.yaml` recipients.
2. Run `sops updatekeys` on each encrypted file.
3. Commit.
4. Verify activation on each host class (Darwin, Linux, HM-only if used).

---

## Security model and common mistakes

## Good practices

- Keep secret values only in encrypted files.
- Use strict file modes (`0400` or `0440`) unless broader access is required.
- Reference secrets by `config.sops.secrets.<name>.path`.
- Separate secrets by blast radius when useful (multiple sops files).
- Keep decryption keys out of git and out of world-readable paths.

## Common mistakes

- Embedding secret literals in Nix expressions.
- Using `builtins.readFile` on secret plaintext during evaluation.
- Writing rendered secrets into store-backed paths.
- Forgetting to update recipient metadata after key changes.
- Assuming HM and system secret runtime paths are identical.

---

## Home Manager caveats worth remembering

Upstream explicitly notes:

- HM module uses a user service (`sops-nix.service`).
- Runtime secret location differs from system module behavior.
- `home.homeDirectory` needs to be correctly set so secret symlink paths resolve as expected.

Source: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

---

## `neededForUsers` and early boot/user creation

Upstream supports `neededForUsers = true` for cases where secrets must exist before normal user setup (e.g., hashed password files consumed during user creation). This is a specialized boot-order/use-case option and should only be used when necessary.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

---

## Service restart/reload integration

For system services, you can attach:

- `restartUnits = [ ... ]`
- `reloadUnits = [ ... ]`

to specific secrets so updates propagate to dependent services.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

---

## Troubleshooting

## "Error getting data key: 0 successful groups required, got 0"

Usually means decryption key mismatch:

- secret encrypted to recipients unavailable on target host
- wrong key file path
- SSH-derived key expectations differ from actual file/key format

Check:

- `.sops.yaml` recipients
- target key file exists and readable by activation context
- secret has been rewrapped with current recipients (`sops updatekeys`)

Related context: [Issue #744](https://github.com/Mic92/sops-nix/issues/744).

## Secret path exists but app cannot read it

Check:

- file mode and owner/group on secret declaration
- service user identity
- whether consumer runs in system or user context

## Darwin-specific confusion around key location

Upstream notes common Darwin path convention for age keys:

- `$HOME/Library/Application Support/sops/age/keys.txt`

or configure custom location explicitly.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

---

## Suggested improvements: status

| #   | Item                                                        | Status | Notes                                                                                                                 |
| --- | ----------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------- |
| 1   | One primary age key strategy across classes                 | Done   | Single HM class via `sops.age.sshKeyPaths`. System-level classes removed; re-add when a real system consumer arrives. |
| 2   | Key-rotation script that rewraps all encrypted files        | Done   | [`scripts/sops-updatekeys.sh`](../scripts/sops-updatekeys.sh)                                                         |
| 3   | Split secrets by domain (`secrets/editor.yaml`, etc.)       | Open   | Not done. The `dendritic.secrets.defaultSopsFile` option lets a host or feature module override per-call once needed. |
| 4   | CI validation that encrypted files still parse as SOPS docs | Done   | [`modules/sops-validation.nix`](../modules/sops-validation.nix) → `nix flake check`'s `sops-files-parse` derivation.  |

---

## Quick reference snippets

### Secret declaration

```nix
sops.secrets.api_token = {};
```

### Secret consumption

```nix
programs.someapp.tokenFile = config.sops.secrets.api_token.path;
```

### Binary secret

```nix
sops.secrets."tls-key" = {
  format = "binary";
  sopsFile = ./tls-key.pem.sops;
  mode = "0400";
};
```

### Template

```nix
sops.templates."app.env".content = ''
  TOKEN=${config.sops.placeholder.api_token}
'';
```

### Service config using rendered template

```nix
systemd.services.app.serviceConfig.ExecStart =
  "${pkgs.app}/bin/app --env-file ${config.sops.templates."app.env".path}";
```

---

## Related docs in this repository

- [Dendritic Nix: Patterns, Den, and Dendrix](./dendritic-patterns.md)
- [Den - Deep Reference](./den.md)

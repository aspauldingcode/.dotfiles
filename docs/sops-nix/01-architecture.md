# 01 - Architecture

## What sops-nix is

`sops-nix` is a Nix module layer that takes encrypted SOPS files and materializes decrypted secrets at activation/runtime with declarative permissions.

It is designed for:

- encrypted secrets in git,
- no plaintext in `/nix/store`,
- reproducible config + runtime decryption.

## Core model

There are three planes:

1. **Authoring plane** - encrypted secret files (`*.yaml`, binary, etc.) in your repository.
2. **Evaluation plane** - Nix evaluates declarations like `sops.secrets.<name> = { ... };`.
3. **Activation/runtime plane** - `sops-install-secrets` decrypts files and writes runtime secret files.

This separation is the reason secrets stay out of derivations.

## End-to-end flow

1. Add/update encrypted SOPS file.
2. Declare secret in Nix module (`sops.secrets.<name>`).
3. Rebuild/switch.
4. Activation decrypts + writes secret files with configured ownership/mode.
5. Services/apps consume `config.sops.secrets.<name>.path`.

## Supported module contexts

`sops-nix` is available in:

- NixOS (`inputs.sops-nix.nixosModules.sops`)
- nix-darwin (`inputs.sops-nix.darwinModules.sops`)
- Home Manager (`inputs.sops-nix.homeManagerModules.sops`)

Each context has different activation mechanics and runtime locations.

## Runtime behavior by context

### NixOS and nix-darwin system modules

- Secrets are managed by the system activation/service path.
- Good for system services and root-owned secrets.

### Home Manager module

- Uses user-level `sops-nix.service`.
- Runtime secret location differs from system module behavior.
- Secret paths are still consumed through `config.sops.secrets.<name>.path`.

Upstream explicitly documents HM-specific behavior and requirements around `home.homeDirectory` and runtime dirs.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

## Why this is safe for Nix workflows

- Encrypted files can be committed safely.
- Nix store may contain encrypted SOPS files, not plaintext.
- Decrypted values are created at activation/runtime only.
- Access controls are declarative (`owner`, `group`, `mode`).

## What sops-nix does not do automatically

- It does not rotate your recipients for you.
- It does not choose your key lifecycle policy.
- It does not magically reload arbitrary apps unless you wire restart/reload behavior.
- It does not prevent all misuse if you manually read/write plaintext into store-backed paths.

Those are operational policy concerns, covered in later chapters.

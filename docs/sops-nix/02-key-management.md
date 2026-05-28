# 02 - Key Management

This chapter covers how `sops-nix` decrypts secrets and how to choose/manage key strategies.

## Key sources in sops-nix

Common age-based options:

- `sops.age.keyFile`
- `sops.age.generateKey`
- `sops.age.sshKeyPaths`

### Dedicated age key file

Example:

```nix
sops.age.keyFile = "/var/lib/sops-nix/key.txt";
sops.age.generateKey = true;
```

Pros:

- clear, explicit key artifact
- independent of SSH auth key lifecycle

Cons:

- extra secret artifact to back up/persist

### SSH key bridge (`ssh-to-age` style)

Example:

```nix
sops.age.sshKeyPaths = [ "/home/user/.ssh/id_ed25519" ];
```

Pros:

- no separate age key file to manage

Cons:

- couples decryption to SSH key lifecycle
- passphrase and activation-context nuances can break decryption

## Strategy in this repository

Unified ssh-to-age bridge in `modules/secrets.nix`:

- single class export: `flake.modules.homeManager.dendritic`
- `sops.age.sshKeyPaths = [ config.dendritic.secrets.ageKeyPath ]`
  where `dendritic.secrets.ageKeyPath` defaults to
  `"${config.home.homeDirectory}/.ssh/id_ed25519"`
- HM packages include `sops`, `age`, `ssh-to-age`

The earlier mixed strategy (system modules pinned to
`/var/lib/sops-nix/key.txt`; HM pinned to ssh-to-age) was removed when
the system-class blocks turned out to have zero consumers. If a future
system-level consumer lands, add a sibling
`flake.modules.{nixos,darwin}.dendritic` block keyed off the same
`dendritic.secrets.*` options surface.

## Recipient model and `.sops.yaml`

SOPS encrypts a data key to one or more recipients. Those recipient rules are managed in `.sops.yaml`:

- `keys:` aliases recipients
- `creation_rules:` maps file path regexes to recipient lists

If a secret file is not encrypted to a key available on target host/user context, decryption fails.

## Generating and inspecting keys

Age key generation:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Convert SSH public key to age recipient:

```bash
nix shell nixpkgs#ssh-to-age -c sh -lc 'ssh-to-age < ~/.ssh/id_ed25519.pub'
```

Upstream also notes Darwin-specific common location:

- `$HOME/Library/Application Support/sops/age/keys.txt`

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

## Rotation model

Rotation usually means:

1. Add new recipient(s) in `.sops.yaml`.
2. Rewrap existing files:

```bash
sops updatekeys secrets/secrets.yaml
```

3. Commit.
4. Roll out + verify.
5. Remove old recipients only after all hosts/users can decrypt with new recipients.

## Native SSH support notes

There is active upstream history around SSH-as-age handling and migration semantics:

- [PR #779](https://github.com/Mic92/sops-nix/pull/779)
- [Issue #744](https://github.com/Mic92/sops-nix/issues/744)

Treat the currently documented module options in the exact release you pin as authoritative.

## Recommended policy for this repo

If you want lowest operational surprise:

- use one primary key source strategy across system + HM contexts,
- document recipient ownership and rotation cadence,
- verify decryption in all host contexts after any key change.

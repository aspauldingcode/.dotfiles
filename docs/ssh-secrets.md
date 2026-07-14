# SSH identities + GitHub age unlock

Login SSH keys are declarative and rotatable. **Vault unlock** uses a GitHub
private age master — not peer-host enroll, and not the pass store.

## Trust model

```
gh auth login  (Alex GitHub + MFA/passkeys)
        │
 private aspauldingcode/dendritic-age-master
 (age-master.key only — never GPG / pass plaintext)
        │
 secrets-bootstrap → ~/.config/sops/age/ (or Darwin Library path)
        │
 sops ciphertext in public .dotfiles
 (gpg_private_key / gpg_passphrase)
        │
 gpg-agent → pass → SecretSpec
```

Grace period: SSH-derived age recipients remain in [`.sops.yaml`](../.sops.yaml)
(`user_8amps`, `user_alex`) and `dendritic.secrets.includeSshAge = true` merges
ssh-to-age into the keys file. After every host runs `secrets-bootstrap`, drop
SSH recipients and set `includeSshAge = false`.

**Threat model:** anyone who can authenticate as Alex on GitHub and read
`dendritic-age-master` can unlock sops → GPG → pass. Keep the repo private,
Alex-only, no Actions, MFA on GitHub. Do **not** put the GPG private key in
`.password-store` or in this age-master repo.

## Fresh machine

1. Install / switch the flake (gets `gh`, `secrets-bootstrap` on PATH when
   `dendritic.secrets.bootstrap.enable` — default).
2. `gh auth login` as Alex.
3. `nix run .#secrets-bootstrap` (or `secrets-bootstrap`).
4. Rebuild/activate → sops decrypts → pass imports GPG → store syncs.
5. Optional login enroll: on any decrypt-capable checkout,
   `nix run .#ssh-enroll -- --name <host> --pubkey ~/.ssh/id_ed25519.pub --no-sops`
   (use `--sops` only during grace if you still want SSH age recipients).

## Declarative SSH

| Piece   | Location                                                                   |
| ------- | -------------------------------------------------------------------------- |
| Pubkeys | [`home/ssh-keys.nix`](../home/ssh-keys.nix)                                |
| Module  | [`modules/apps/ssh.nix`](../modules/apps/ssh.nix) (`dendritic.ssh.enable`) |
| Enroll  | `nix run .#ssh-enroll -- --name HOST --pubkey PATH`                        |
| Rotate  | `nix run .#ssh-rotate -- --name HOST --pubkey PATH` then `--finalize`      |

NixOS hosts with `dendritic.ssh.enable` get the union of pubkeys as
`openssh.authorizedKeys`. Private keys are generated on disk if missing
(`generateKeyIfMissing`); never commit them.

## Commands

```bash
nix run .#secrets-bootstrap
nix run .#secrets-bootstrap -- --status

nix run .#ssh-enroll -- --name sliceanddice --pubkey ~/.ssh/id_ed25519.pub
nix run .#ssh-rotate -- --name mba --pubkey ~/.ssh/id_ed25519.pub
nix run .#ssh-rotate -- --name mba --finalize

bash scripts/sops-updatekeys.sh   # after .sops.yaml recipient edits
```

## Why not unlock via pass itself?

Pass entries are GPG ciphertext. Fetching GPG from the password-store repo is
circular (or means storing vault-master plaintext next to the vault). The age
master is a separate private GitHub artifact used only for bootstrap.

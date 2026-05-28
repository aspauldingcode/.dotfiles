# 03 - Authoring Secrets and File Layout

This chapter covers how to create/update encrypted files and how to structure them.

## Files in this repository

Current secret-related files:

- `.sops.yaml` - recipient + creation rules
- `secrets/secrets.yaml` - encrypted YAML secret store
- `modules/secrets.nix` - cross-class `sops-nix` defaults

## Editing encrypted files

Edit encrypted YAML:

```bash
sops secrets/secrets.yaml
```

Edit encrypted binary usually means re-encrypting from source artifact into `.sops` output, then committing only ciphertext output.

## Recommended naming conventions

- Shared app/service values: `secrets/secrets.yaml`
- Large domain split (optional as secret count grows):
  - `secrets/editor.yaml`
  - `secrets/apps.yaml`
  - `secrets/infra.yaml`
- Binary blobs:
  - `something.ext.sops` and declare `format = "binary"`

## Declaring secrets in modules

Minimum declaration:

```nix
sops.secrets.anthropic_api_key = {};
```

Explicit source file:

```nix
sops.secrets.anthropic_api_key = {
  sopsFile = ../secrets/secrets.yaml;
};
```

Binary declaration (reference pattern — no binary secrets currently in this repo):

```nix
sops.secrets."my-binary-key" = {
  format = "binary";
  sopsFile = ./my-binary-key.sops;
  mode = "0400";
};
```

## Choosing one file vs many files

### Single file benefits

- simple editing workflow
- easy grep for key names
- fewer moving parts

### Multi-file benefits

- smaller blast radius by domain
- clearer ownership boundaries
- easier selective access policies if you later split recipients by file

Either is valid. Optimize for your team/process size.

## Preventing accidental plaintext commits

Checklist:

- Never commit raw `.pem`, `.env`, or plaintext YAML with secrets.
- Keep `.sops.yaml` creation rules tight enough to match intended paths.
- Review diffs for encrypted payload + `sops` metadata only.

## Review patterns

During PR review, check:

- new secret key names are sensible,
- recipient list still correct,
- no plaintext values introduced outside encrypted payload,
- module declarations exist for any newly required consumers.

## Runtime path usage discipline

Never inline runtime secret path guesses like `/run/secrets/...`.
Always consume:

```nix
config.sops.secrets.<name>.path
```

This keeps code resilient to backend/path behavior differences across contexts.

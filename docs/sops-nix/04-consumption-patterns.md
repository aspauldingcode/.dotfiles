# 04 - Consuming Secrets in Nix Modules

This chapter focuses on practical consumption patterns: service args, app config, activation scripts, and module wiring.

## Golden rule

Declare secret, then consume `.path`.

```nix
sops.secrets.api_key = {};

programs.someapp.apiKeyFile = config.sops.secrets.api_key.path;
```

Do not use `builtins.readFile` on secret plaintext during evaluation.

## Pattern A - direct file path option

Many modules expect `...File` options:

```nix
services.example.tokenFile = config.sops.secrets.token.path;
```

This is ideal when supported.

## Pattern B - command substitution in app config

Sometimes app config supports `cmd:` indirection.

Example from this repo (`modules/editor.nix`):

```nix
api_key = "cmd:cat ${config.sops.secrets.anthropic_api_key.path}"
```

This keeps the secret off static config literals and uses runtime file reads.

## Pattern C - activation-time script consumption

In activation scripts, reference the secret path at runtime.

Example pattern (generic — no activation-script consumer in this repo currently):

```sh
KEY_PATH="${config.sops.secrets."my-binary-key".path}"
if [ ! -r "$KEY_PATH" ]; then
  echo "secret missing" >&2
  exit 1
fi
```

This is useful for signing, materializing policy files, or generating artifacts that must not be done at evaluation time.

## Pattern D - secret with strict permissions

```nix
sops.secrets.private_key = {
  mode = "0400";
  owner = "appuser";
  group = "appgroup";
};
```

Use this when service user is not root/default.

## Context boundary notes

System module and Home Manager module run in different activation contexts. Keep consumer and declaration in matching context unless you intentionally bridge them.

## This repository's concrete consumers

### Editor module

- Declaration: `sops.secrets.anthropic_api_key = {};`
- Consumption: command reads from `config.sops.secrets.anthropic_api_key.path`

## Safety checks before switch

Before running `nh ... switch`, verify:

1. secret is declared where used,
2. `sopsFile` resolves correctly (if overridden),
3. permission fields make sense for target runtime user,
4. consumer references `.path`, not plaintext values.

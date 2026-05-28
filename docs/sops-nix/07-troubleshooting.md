# 07 - Troubleshooting

This chapter maps common failures to likely causes and fixes.

## Error: `0 successful groups required, got 0`

Typical meaning: no usable decryption key matched secret recipients.

Check:

1. `.sops.yaml` recipient list includes current host/user key.
2. Secret file was rewrapped (`sops updatekeys`) after recipient changes.
3. Correct key source is configured (`keyFile` vs `sshKeyPaths`).
4. Key file permissions/readability are valid for activation context.

Related upstream discussion:

- [Issue #744](https://github.com/Mic92/sops-nix/issues/744)

## Secret declared but consumer cannot read file

Likely causes:

- wrong `owner`/`group`/`mode`,
- service runs as different user than expected,
- consumer in HM context but secret declared only in system context (or inverse),
- app expects text but secret is binary (or inverse).

Fix:

- align declaration context + consumer context,
- set explicit ownership fields,
- verify with app user permissions.

## Secret path changed unexpectedly

Cause:

- hardcoded runtime paths instead of using `config.sops.secrets.<name>.path`.

Fix:

- always consume generated path attribute.

## Home Manager secret service confusion

Symptoms:

- HM secret not available until user session/service state is healthy,
- restart hooks not behaving like system-unit expectations.

Fix:

- treat HM as user-service context,
- test in real login/session lifecycle,
- avoid assuming system-unit semantics apply unchanged.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

## Darwin key location confusion

Upstream common convention:

- `$HOME/Library/Application Support/sops/age/keys.txt`

If using custom locations, ensure your module configuration and actual file location match.

## Binary secret appears corrupted

Check:

- declaration has `format = "binary"`,
- source `.sops` file was produced from original binary correctly,
- consumer treats output as binary, not text.

## Activation succeeds but app still uses old secret

Likely causes:

- service not restarted/reloaded,
- app caches credentials,
- app reads another config source.

Fix:

- add `restartUnits` or `reloadUnits` where appropriate,
- confirm app startup args/path point to current secret/template paths.

## Debug process (fast path)

1. Confirm declaration exists (`sops.secrets.<name>`).
2. Confirm secret key exists in encrypted file.
3. Confirm recipient can decrypt.
4. Confirm path attribute is what consumer uses.
5. Confirm service user can read file.
6. Confirm service reload/restart behavior.

## Last-resort recovery strategy

If rotation caused lockout:

1. Re-add previous recipient in `.sops.yaml`.
2. `sops updatekeys` on all encrypted files.
3. Commit + deploy.
4. Re-run staged migration with explicit host verification at each stage.

# 06 - Operations and Rotation

This chapter is the operator runbook: day-to-day edits, onboarding, rotation, and rollout verification.

## Daily edit workflow

1. Edit encrypted secret file:

```bash
sops secrets/secrets.yaml
```

2. Commit encrypted changes.
3. Rebuild on target host(s):

```bash
nh darwin switch
# or
nh os switch
```

4. Verify consumer application behavior.

## Add a new secret (text)

1. Add key/value in `secrets/secrets.yaml` via `sops`.
2. Declare secret in relevant module:

```nix
sops.secrets.my_new_secret = {};
```

3. Consume via `.path`.
4. Rebuild and validate.

## Add a new secret (binary)

1. Encrypt binary into `*.sops`.
2. Add/confirm `.sops.yaml` creation rule for that path.
3. Declare with `format = "binary"`.
4. Consume via `.path`.
5. Rebuild and validate.

## Onboard a new machine/user recipient

1. Add recipient alias in `.sops.yaml` `keys:`.
2. Add that alias under matching `creation_rules`.
3. Rewrap existing files:

```bash
sops updatekeys secrets/secrets.yaml
```

4. Commit.
5. Verify decryption on that machine/user context.

## Rotate recipient keys

Safe sequence:

1. Add new recipients first.
2. Rewrap all secret files with `sops updatekeys`.
3. Deploy and validate all hosts.
4. Remove old recipients.
5. Rewrap + deploy again.

This avoids lockout during partial rollout.

## Verification checklist after key changes

- `sops` can still open every encrypted file locally.
- each host class can switch successfully:
  - Darwin
  - NixOS
  - HM context (if used standalone/system-wide)
- secret-consuming apps start/read as expected.

## Incident response: decryption failure during switch

Immediate checks:

1. Was recipient removed too early?
2. Is target key file present and readable?
3. Are you in the expected context (system vs HM user)?
4. Did you rewrap all files (`updatekeys`) or only some?

Rollback option:

- temporarily re-add previous recipient and rewrap,
- redeploy,
- then do staged migration again.

## Suggested automation (optional)

Create a helper script to rewrap all secret files in one command:

```bash
#!/usr/bin/env bash
set -euo pipefail
sops updatekeys secrets/secrets.yaml
```

This reduces forgotten-file errors during rotation.

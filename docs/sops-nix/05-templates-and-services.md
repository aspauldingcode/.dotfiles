# 05 - Templates and Service Integration

This chapter covers `sops.templates`, placeholders, and service reload/restart behavior.

## Why templates exist

Some apps need a single config file that contains both:

- non-secret config values,
- secret values.

`sops.templates` lets you render that file during activation while keeping source templates non-sensitive.

## Template basics

```nix
sops.secrets.db_password = {};

sops.templates."myapp/config.toml".content = ''
  [database]
  password = "${config.sops.placeholder.db_password}"
'';
```

The rendered path is available as:

```nix
config.sops.templates."myapp/config.toml".path
```

## Ownership and permissions for templates

You can set ownership/mode for generated template outputs:

```nix
sops.templates."myapp/config.toml" = {
  content = ''
    token = "${config.sops.placeholder.api_token}"
  '';
  owner = "myapp";
  group = "myapp";
  mode = "0400";
};
```

## Wiring templates into systemd services

```nix
systemd.services.myapp = {
  serviceConfig = {
    ExecStart =
      "${pkgs.myapp}/bin/myapp --config ${config.sops.templates."myapp/config.toml".path}";
    User = "myapp";
  };
};
```

This is the preferred pattern when an app cannot consume separate secret files.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

## Restart and reload hooks

Per-secret controls:

```nix
sops.secrets."home-assistant-secrets.yaml" = {
  restartUnits = [ "home-assistant.service" ];
  # or reloadUnits = [ "home-assistant.service" ];
};
```

Use `restartUnits` when service cannot hot-reload changed secret material.
Use `reloadUnits` when app supports safe reload semantics.

## Home Manager caveat

Upstream notes `restartUnits` semantics differ for systemd user services; treat HM user-service behavior explicitly and test.

## `%r` runtime placeholder

Upstream documents `%r` replacement for runtime dirs in HM scenarios:

- Linux: `$XDG_RUNTIME_DIR`
- Darwin: `getconf DARWIN_USER_TEMP_DIR`

This is useful for ephemeral user runtime files.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md).

## Recommended pattern in this repo

For applications that currently shell `cat` paths manually, consider incremental migration to:

- explicit `sops.templates` where app supports config files,
- path-only file options where app supports `...File`,
- restart/reload hooks only where needed.

## Worked example: porting CodeCompanion from `cmd:cat` to `sops.templates`

Today, [`modules/editor.nix`](../../modules/editor.nix) consumes the
`openai_api_key` secret via a `cmd:cat ${path}` shell indirection inside
the CodeCompanion plugin config. That works, but every plugin reload spawns
a `cat`, and the path is interpolated into a Lua string at HM eval time —
not great if the plugin ever caches the literal.

The dendritic-grade port uses `sops.templates` to render a runtime env file
that CodeCompanion can source directly. Sketch (illustrative — not applied):

```nix
flake.modules.homeManager.dendritic =
  { config, pkgs, lib, ... }:
  lib.mkIf config.dendritic.secrets.enable {
    sops.secrets.openai_api_key = { };

    # Renders a file at activation containing the plaintext secret, with
    # strict 0400 mode and owned by the HM user. Path is content-addressed
    # via config.sops.templates.<name>.path, never in /nix/store.
    sops.templates."codecompanion.env" = {
      mode = "0400";
      content = ''
        OPENAI_API_KEY=${config.sops.placeholder.openai_api_key}
      '';
    };

    # Reference the rendered path from the plugin config. The plugin
    # reads it once at editor startup.
    programs.nixvim.extraConfigLuaPre = ''
      vim.env.OPENAI_API_KEY = vim.fn.system(
        "set -a; . " ..
        vim.fn.shellescape("${config.sops.templates."codecompanion.env".path}") ..
        "; printenv OPENAI_API_KEY"
      ):gsub("\n$", "")
    '';
  };
```

Why this is better than `cmd:cat`:

- The plugin never sees a literal path interpolated into Lua source;
  it gets the value via `vim.env`, which is process-local.
- The rendered template is HM-managed, so removing the
  `sops.secrets.anthropic_api_key` declaration also removes the env file.
- `sops.templates` honors `restartUnits`/`reloadUnits` for system services,
  so if you later migrate to a daemon (e.g., a local `claude-code` HTTP
  proxy), wiring restart on secret change is one line:

```nix
sops.templates."codecompanion.env".restartUnits = [
  "my-claude-proxy.service"
];
```

## Home Manager restart semantics: what works and what does not

`restartUnits` / `reloadUnits` on a `sops.secrets.<name>` or `sops.templates.<name>` is unambiguous on **system** (`nixos`/`darwin`) sops modules — they map directly to systemd units.

On **Home Manager**, behavior is more constrained:

- Linux HM (under `systemd-user`): `restartUnits = [ "X.service" ]` works against systemd user units. Verified pattern.
- Darwin HM: there is no systemd user manager. `restartUnits` is silently no-op for `launchd` agents. If you need a Darwin app to pick up rotated secrets, do one of:
  - quit and relaunch the app from an HM activation hook (the Brave module's `braveStylixReload` script is the canonical example in this repo),
  - have the app re-read its secret file on a SIGHUP and send the signal from activation,
  - schedule a `launchd` agent restart via `launchctl kickstart -k`.

The rule of thumb: assume `restartUnits` is a systemd hint, not a portable contract.

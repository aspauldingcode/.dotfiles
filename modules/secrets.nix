# Dendritic sops-nix feature.
#
# Single-class HM-only export because every consumer in this repo (see
# `modules/editor.nix` openai_api_key) lives in the home-manager class.
# The dendritic pattern explicitly says "only export classes where feature
# applies"
# (docs/dendritic-nix/02-module-mechanics.md "Class-selective exporting").
#
# If a future system-level consumer (NixOS or nix-darwin sops.secrets.*
# declaration) lands, add a sibling `flake.modules.{nixos,darwin}.dendritic`
# block here following the same shape — keep options surface in
# `dendritic.secrets.*` either way.
#
# Key strategy: ssh-to-age bridge from the user's ed25519 key. No separate
# age private key to back up; the SSH key IS the secret.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      inputs,
      ...
    }:
    let
      ageKeyDir =
        if pkgs.stdenv.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/sops/age"
        else
          "${config.xdg.configHome}/sops/age";
      ageKeyFile = "${ageKeyDir}/keys.txt";
    in
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      options.dendritic.secrets = {
        enable = lib.mkEnableOption "sops-nix-managed secrets for this Home Manager profile" // {
          default = true;
        };

        ageKeyPath = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.ssh/id_ed25519";
          description = ''
            Path to the SSH ed25519 private key that sops-nix derives the
            age decryption key from (via ssh-to-age). Hosts can override
            this if they prefer a non-default SSH key location.
          '';
        };

        defaultSopsFile = lib.mkOption {
          type = lib.types.path;
          default = ../secrets/secrets.yaml;
          description = ''
            Default sops-encrypted YAML file consumed by
            `sops.secrets.<name>` declarations that don't override
            `sopsFile`. Hosts can point this at a host-scoped secrets
            file if they need per-machine isolation.
          '';
        };

        ageKeyFile = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = ageKeyFile;
          description = ''
            Read-only path where the activation script materializes an
            age keys file derived from `ageKeyPath` (via ssh-to-age) so
            the `sops` CLI can decrypt without `SOPS_AGE_*` env vars.
            Linux uses `$XDG_CONFIG_HOME/sops/age/keys.txt`; Darwin uses
            `~/Library/Application Support/sops/age/keys.txt` (sops's
            canonical Darwin default).
          '';
        };
      };

      config = lib.mkIf config.dendritic.secrets.enable {
        home.packages = with pkgs; [
          sops
          age
          ssh-to-age
        ];

        # sops-nix at activation: SSH → age conversion happens internally
        # against `sshKeyPaths`. This is the source of truth that NIX
        # decryption uses; it does NOT depend on the CLI keys.txt below.
        sops = {
          defaultSopsFormat = "yaml";
          defaultSopsFile = config.dendritic.secrets.defaultSopsFile;
          age.sshKeyPaths = [ config.dendritic.secrets.ageKeyPath ];
        };

        # sops CLI side: the CLI does NOT use sshKeyPaths. By default it
        # checks `SOPS_AGE_SSH_PRIVATE_KEY_FILE`, `/Users/$USER/.ssh/id_rsa`
        # (hardcoded, ignores id_ed25519), then a handful of env vars. To
        # make `sops edit secrets/...yaml` work out of the box with no
        # shell setup, materialize the derived age private key at the
        # location sops looks at by default on this platform. Idempotent;
        # overwritten on every activation from the current SSH key.
        home.activation.materializeSopsAgeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          _sshKey="${config.dendritic.secrets.ageKeyPath}"
          _ageDir=${lib.escapeShellArg ageKeyDir}
          _ageFile=${lib.escapeShellArg ageKeyFile}
          if [ -r "$_sshKey" ]; then
            mkdir -p "$_ageDir"
            chmod 0700 "$_ageDir"
            ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$_sshKey" -o "$_ageFile"
            chmod 0600 "$_ageFile"
          fi
        '';

        # Belt + suspenders: shells inherit a pointer to the keys file so
        # subprocess sops invocations (GUI launchers, agents, scripts)
        # find it even if Darwin's default-path probe ever changes.
        home.sessionVariables.SOPS_AGE_KEY_FILE = ageKeyFile;
      };
    };
}

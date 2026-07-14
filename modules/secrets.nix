# Dendritic sops-nix feature.
#
# Single-class HM-only export because every consumer in this repo (see
# `modules/editor.nix` openai_api_key) lives in the home-manager class.
#
# Unlock strategy (preferred):
#   GitHub private age master → secrets-bootstrap → age keys file → sops → GPG → pass
# Grace / legacy:
#   SSH ed25519 → ssh-to-age (still merged into keys.txt when includeSshAge)
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
      cfg = config.dendritic.secrets;
      ageKeyDir =
        if pkgs.stdenv.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/sops/age"
        else
          "${config.xdg.configHome}/sops/age";
      ageKeyFile = "${ageKeyDir}/keys.txt";
      masterKeyFile = "${ageKeyDir}/github-age-master.key";
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
            Path to the SSH ed25519 private key used when includeSshAge is true
            (grace: ssh-to-age merge into the age keys file).
          '';
        };

        includeSshAge = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            When true, activation merges an ssh-to-age private key into the age
            keys file alongside any GitHub age master. Keep true during the
            migration grace period; set false once all hosts unlock via
            secrets-bootstrap only.
          '';
        };

        defaultSopsFile = lib.mkOption {
          type = lib.types.path;
          default = ../secrets/secrets.yaml;
          description = ''
            Default sops-encrypted YAML file consumed by
            `sops.secrets.<name>` declarations that don't override
            `sopsFile`.
          '';
        };

        ageKeyFile = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = ageKeyFile;
          description = ''
            Path where activation materializes the age keys file for the sops
            CLI and sops-nix (`sops.age.keyFile`).
          '';
        };

        bootstrap = {
          enable = lib.mkEnableOption "GitHub age-master bootstrap helpers on PATH" // {
            default = true;
          };

          owner = lib.mkOption {
            type = lib.types.str;
            default = "aspauldingcode";
            description = "GitHub owner of the private age-master repository.";
          };

          repo = lib.mkOption {
            type = lib.types.str;
            default = "dendritic-age-master";
            description = "Private repository name holding age-master.key.";
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "age-master.key";
            description = "Path inside the private repository.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages =
          with pkgs;
          [
            sops
            age
            ssh-to-age
          ]
          ++ lib.optionals cfg.bootstrap.enable [
            (pkgs.writeShellApplication {
              name = "secrets-bootstrap";
              runtimeInputs = with pkgs; [
                coreutils
                gh
                python3
                gnugrep
                bash
              ];
              text = ''
                set -euo pipefail
                export AGE_MASTER_OWNER=${lib.escapeShellArg cfg.bootstrap.owner}
                export AGE_MASTER_REPO=${lib.escapeShellArg cfg.bootstrap.repo}
                export AGE_MASTER_PATH=${lib.escapeShellArg cfg.bootstrap.path}
                export SOPS_AGE_KEY_FILE=${lib.escapeShellArg ageKeyFile}
                exec bash ${../scripts/secrets-bootstrap.sh} "$@"
              '';
            })
          ];

        sops = {
          defaultSopsFormat = "yaml";
          defaultSopsFile = cfg.defaultSopsFile;
          age.keyFile = ageKeyFile;
          # Grace: also accept SSH-derived keys inside sops-nix until includeSshAge
          # is turned off and SSH recipients are dropped from .sops.yaml.
          age.sshKeyPaths = lib.mkIf cfg.includeSshAge [ cfg.ageKeyPath ];
        };

        home.activation.materializeSopsAgeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          _ageDir=${lib.escapeShellArg ageKeyDir}
          _ageFile=${lib.escapeShellArg ageKeyFile}
          _master=${lib.escapeShellArg masterKeyFile}
          _sshKey=${lib.escapeShellArg cfg.ageKeyPath}
          mkdir -p "$_ageDir"
          chmod 0700 "$_ageDir"
          _tmp="$_ageFile.tmp"
          : > "$_tmp"
          chmod 0600 "$_tmp"
          if [ -r "$_master" ]; then
            cat "$_master" >> "$_tmp"
            printf '\n' >> "$_tmp"
          fi
          ${lib.optionalString cfg.includeSshAge ''
            if [ -r "$_sshKey" ]; then
              ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$_sshKey" >> "$_tmp" || true
              printf '\n' >> "$_tmp"
            fi
          ''}
          if [ -s "$_tmp" ]; then
            mv "$_tmp" "$_ageFile"
            chmod 0600 "$_ageFile"
          else
            rm -f "$_tmp"
          fi
        '';

        home.sessionVariables.SOPS_AGE_KEY_FILE = ageKeyFile;
      };
    };
}

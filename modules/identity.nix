# Shared local account identity for NixOS + Windows (sliceanddice dual-boot).
#
# Password never enters the Nix store or sops YAML. It lives in the private
# pass store as secretspec/shared/default/LOGIN_PASSWORD, materialized to
# passwordFile (0600 under $HOME) by pass-secretspec-materialize.
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.identity;
      stateDir = "/var/lib/dendritic-identity";
      hashedPath = "${stateDir}/hashed-password";
    in
    {
      options.dendritic.identity = {
        enable = lib.mkEnableOption "shared declarative local username/password (NixOS + Windows)";

        username = lib.mkOption {
          type = lib.types.str;
          default = "alex";
          description = "Local account name on NixOS and Windows.";
        };

        passwordFile = lib.mkOption {
          type = lib.types.str;
          default = "/home/alex/.config/dendritic/identity/login.password";
          description = ''
            Plaintext password file materialized from pass (LOGIN_PASSWORD).
            Root-readable for chpasswd / Windows staging; never committed.
          '';
        };

        passKey = lib.mkOption {
          type = lib.types.str;
          default = "LOGIN_PASSWORD";
          description = "SecretSpec / pass key name under secretspec/shared/default/.";
        };

        manageNixosPassword = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Apply the pass-materialized password to the NixOS local account via chpasswd.";
        };
      };

      config = lib.mkIf cfg.enable {
        users.mutableUsers = lib.mkDefault true;

        users.users.${cfg.username} = {
          isNormalUser = lib.mkDefault true;
          description = lib.mkDefault "Alex Spaulding";
        };

        systemd.tmpfiles.rules = [
          "d ${stateDir} 0700 root root -"
        ];

        systemd.paths.dendritic-identity-apply-nixos-password = lib.mkIf cfg.manageNixosPassword {
          description = "Watch pass-materialized login password";
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathExists = cfg.passwordFile;
            PathModified = cfg.passwordFile;
          };
        };

        systemd.services.dendritic-identity-apply-nixos-password = lib.mkIf cfg.manageNixosPassword {
          description = "Apply pass-materialized login password to NixOS local account";
          after = [ "local-fs.target" ];
          unitConfig.ConditionPathExists = cfg.passwordFile;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "dendritic-identity-apply-nixos-password" ''
              set -euo pipefail
              pw=${lib.escapeShellArg cfg.passwordFile}
              user=${lib.escapeShellArg cfg.username}
              hash_out=${lib.escapeShellArg hashedPath}
              plain="$(tr -d '\n' <"$pw")"
              [[ -n $plain ]] || { echo "dendritic-identity: empty password file" >&2; exit 1; }
              ${pkgs.mkpasswd}/bin/mkpasswd -m yescrypt "$plain" >"$hash_out"
              chmod 600 "$hash_out"
              echo "$user:$plain" | ${pkgs.shadow}/bin/chpasswd
              echo "dendritic-identity: applied password for $user (from pass materialize)" >&2
            '';
          };
        };
      };
    };
}

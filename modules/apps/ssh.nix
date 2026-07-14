# Declarative SSH identities for Alex hosts (login / GitHub client).
#
# Pubkeys live in home/ssh-keys.nix (git-safe). Unlock for sops is GitHub age
# master (see dendritic.secrets.bootstrap) — SSH keys are not required for
# vault unlock after migration.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.ssh;
      sshKeys = import ../../home/ssh-keys.nix;
    in
    {
      options.dendritic.ssh = {
        enable = lib.mkEnableOption "declarative SSH pubkeys, authorizedKeys, and client Host blocks";

        keys = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = sshKeys;
          description = "Map of host name → ssh-ed25519 public key line.";
        };

        identityFile = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.ssh/id_ed25519";
          description = "Default IdentityFile for peer hosts and github.com.";
        };

        generateKeyIfMissing = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "On activation, create ed25519 IdentityFile if missing (empty passphrase).";
        };

        manageClientConfig = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Write programs.ssh Host blocks (disable if the host already manages SSH config).";
        };

        peerHosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                hostname = lib.mkOption {
                  type = lib.types.str;
                  description = "SSH Hostname (DNS or IP).";
                };
                user = lib.mkOption {
                  type = lib.types.str;
                  description = "Remote username.";
                };
              };
            }
          );
          default = {
            mba = {
              hostname = "mba.local";
              user = "8amps";
            };
            sliceanddice = {
              hostname = "sliceanddice.local";
              user = "alex";
            };
          };
          description = "programs.ssh Host blocks for peer machines.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          openssh
        ];

        home.activation.dendriticSshKeygen = lib.mkIf cfg.generateKeyIfMissing (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            _id=${lib.escapeShellArg cfg.identityFile}
            if [ ! -e "$_id" ]; then
              mkdir -p "$(dirname "$_id")"
              ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$_id" -N "" -C "${config.home.username}@dendritic"
              chmod 600 "$_id"
              chmod 644 "$_id.pub" || true
            fi
          ''
        );

        programs.ssh = lib.mkIf cfg.manageClientConfig {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            "*" = {
              ForwardAgent = false;
              AddKeysToAgent = "yes";
              IdentityFile = cfg.identityFile;
              IdentitiesOnly = true;
            };
            "github.com" = {
              User = "git";
              IdentityFile = cfg.identityFile;
              IdentitiesOnly = true;
            };
          }
          // lib.mapAttrs (_name: peer: {
            HostName = peer.hostname;
            User = peer.user;
            IdentityFile = cfg.identityFile;
            IdentitiesOnly = true;
          }) cfg.peerHosts;
        };
      };
    };

  flake.modules.nixos.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      sshKeys = import ../../home/ssh-keys.nix;
      allPubkeys = lib.unique (lib.attrValues sshKeys);
      hmUsers = config.home-manager.users or { };
      enabledUsers = lib.filterAttrs (_n: u: (u.dendritic.ssh.enable or false)) hmUsers;
    in
    {
      config = lib.mkIf (enabledUsers != { } && allPubkeys != [ ]) {
        users.users = lib.mapAttrs (_u: _: {
          openssh.authorizedKeys.keys = lib.mkDefault allPubkeys;
        }) enabledUsers;
      };
    };
}

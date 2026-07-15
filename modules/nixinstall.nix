# dendritic.nixinstall — on-disk NixOS installer partition (like wininstall).
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.nixinstall;
      stateDir = "/var/lib/dendritic-nixinstall";

      vaultScript = pkgs.writeShellApplication {
        name = "dendritic-vault-sync";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux
          rsync
          gnugrep
          hostname
          findutils
        ];
        text = builtins.readFile ./pkgs/_dendritic-vault.sh;
      };

      vaultRestore = pkgs.writeShellApplication {
        name = "dendritic-vault-restore";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux
          rsync
          gnugrep
          findutils
        ];
        text = ''
          exec bash ${./pkgs/_dendritic-vault.sh} restore "$@"
        '';
      };

      bootstrap = pkgs.writeShellApplication {
        name = "dendritic-nixinstall-bootstrap";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux # sfdisk, partx, blkid, mount
          gptfdisk
          parted
          e2fsprogs
          rsync
          nixos-install-tools
          nix
          gnugrep
          gawk
          systemd
        ];
        excludeShellChecks = [
          "SC2086"
          "SC2046"
          "SC2034"
          "SC2012"
          "SC2116"
        ];
        text = builtins.readFile ./pkgs/_dendritic-nixinstall-bootstrap.sh;
      };
    in
    {
      options.dendritic.nixinstall = {
        enable = lib.mkEnableOption "On-disk NixOS installer (nixinstall partition + boot entry)";

        disk = lib.mkOption {
          type = lib.types.str;
          default = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S62ANJ0R238724D";
        };

        mountPoint = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/nixinstall";
        };

        sizeGiB = lib.mkOption {
          type = lib.types.ints.positive;
          default = 8;
        };

        autoBootstrap = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Populate nixinstall after boot when not ready.";
        };

        flakeDir = lib.mkOption {
          type = lib.types.str;
          default = "/etc/nixos/.dotfiles";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          vaultScript
          vaultRestore
          bootstrap
        ];

        systemd.tmpfiles.rules = [
          "d ${stateDir} 0750 root root -"
          "d ${cfg.mountPoint} 0755 root root -"
        ];

        # Do not declare a fstab mount for nixinstall here — the partition may
        # not exist yet. Bootstrap mounts it; after disko install, disko owns it.

        systemd.timers.dendritic-nixinstall-bootstrap = lib.mkIf cfg.autoBootstrap {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "120s";
            Persistent = true;
            Unit = "dendritic-nixinstall-bootstrap.service";
          };
        };

        systemd.services.dendritic-nixinstall-bootstrap = lib.mkIf cfg.autoBootstrap {
          description = "Populate on-disk NixOS installer (nixinstall)";
          after = [
            "local-fs.target"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
          path = [
            pkgs.nix
            pkgs.git
            pkgs.coreutils
            config.nix.package
          ];
          unitConfig = {
            ConditionPathExists = "!${stateDir}/ready";
          };
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "3h";
            Restart = "no";
            # Built by the service at start so we don't eval installer at module time for every host.
            ExecStart = pkgs.writeShellScript "dendritic-nixinstall-bootstrap-wrap" ''
              set -euo pipefail
              echo "dendritic-nixinstall: building sliceanddice-installer toplevel…"
              # systemd runs as root; flake tree is owned by the interactive user.
              export HOME=/root
              ${pkgs.git}/bin/git config --global --add safe.directory ${lib.escapeShellArg cfg.flakeDir} || true
              top="$(nix build --no-link --print-out-paths ${lib.escapeShellArg cfg.flakeDir}#nixosConfigurations.sliceanddice-installer.config.system.build.toplevel)"
              export DENDRITIC_NIXINSTALL_DISK=${lib.escapeShellArg cfg.disk}
              export DENDRITIC_NIXINSTALL_MOUNT=${lib.escapeShellArg cfg.mountPoint}
              export DENDRITIC_NIXINSTALL_STATE=${lib.escapeShellArg stateDir}
              export DENDRITIC_FLAKE_DIR=${lib.escapeShellArg cfg.flakeDir}
              export DENDRITIC_INSTALLER_TOPLEVEL="$top"
              export DENDRITIC_NIXINSTALL_SIZE_GIB=${toString cfg.sizeGiB}
              export DENDRITIC_NIXINSTALL_ESP=/boot
              exec ${bootstrap}/bin/dendritic-nixinstall-bootstrap
            '';
          };
        };
      };
    };
}

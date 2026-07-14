# Fleet heartbeat: enrolled hosts phone home to private dendritic-fleet-status.
# Allowlisted fields only — never IP / FQDN / SSID / geo.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.fleet;
      fleetHosts = import ../../home/fleet-hosts.nix;
      platform =
        if pkgs.stdenv.isDarwin then
          "darwin"
        else if pkgs.stdenv.isLinux then
          "nixos"
        else
          "linux";
      defaultDotfiles =
        if pkgs.stdenv.isDarwin then "/etc/nix-darwin/.dotfiles" else "/etc/nixos/.dotfiles";
      heartbeatScript = pkgs.writeShellScript "fleet-heartbeat" ''
        export PATH="${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gh
            pkgs.jq
            pkgs.git
            pkgs.gnugrep
          ]
        }:$PATH"
        export FLEET_HOST_ID=${lib.escapeShellArg cfg.hostId}
        export FLEET_PLATFORM=${lib.escapeShellArg cfg.platform}
        export FLEET_STATUS_OWNER=${lib.escapeShellArg cfg.owner}
        export FLEET_STATUS_REPO=${lib.escapeShellArg cfg.repo}
        export FLEET_DOTFILES_ROOT=${lib.escapeShellArg cfg.dotfilesRoot}
        ${lib.optionalString cfg.useSopsToken ''
          export FLEET_STATUS_TOKEN_FILE=${lib.escapeShellArg config.sops.secrets.fleet_status_github_token.path}
        ''}
        exec ${pkgs.bash}/bin/bash ${../../scripts/fleet-heartbeat.sh}
      '';
      logDir = "${config.home.homeDirectory}/.cache";
    in
    {
      options.dendritic.fleet = {
        enable = lib.mkEnableOption "fleet heartbeat agent (private dendritic-fleet-status)";

        hostId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Enrolled host id (must match home/fleet-hosts.nix key).";
        };

        platform = lib.mkOption {
          type = lib.types.enum [
            "darwin"
            "nixos"
            "linux"
          ];
          default = platform;
          description = "Platform label reported in heartbeats.";
        };

        owner = lib.mkOption {
          type = lib.types.str;
          default = "aspauldingcode";
          description = "GitHub owner of the private fleet-status repo.";
        };

        repo = lib.mkOption {
          type = lib.types.str;
          default = "dendritic-fleet-status";
          description = "Private fleet-status repository name.";
        };

        dotfilesRoot = lib.mkOption {
          type = lib.types.str;
          default = defaultDotfiles;
          description = "Local .dotfiles checkout used for flake_rev.";
        };

        intervalSec = lib.mkOption {
          type = lib.types.ints.positive;
          default = 900;
          description = "Heartbeat interval in seconds (default 15m).";
        };

        useSopsToken = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Read GH token from sops secret fleet_status_github_token when present.";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = cfg.hostId != "";
                message = "dendritic.fleet.hostId must be set when fleet is enabled";
              }
              {
                assertion = fleetHosts ? ${cfg.hostId};
                message = "dendritic.fleet.hostId '${cfg.hostId}' is not in home/fleet-hosts.nix";
              }
            ];
          }

          (lib.mkIf cfg.useSopsToken {
            sops.secrets.fleet_status_github_token = {
              sopsFile = ../../secrets/secrets.yaml;
            };
          })

          (lib.mkIf pkgs.stdenv.isDarwin {
            launchd.agents.fleet-heartbeat = {
              enable = true;
              config = {
                Label = "com.aspaulding.fleet-heartbeat";
                ProgramArguments = [ "${heartbeatScript}" ];
                RunAtLoad = true;
                StartInterval = cfg.intervalSec;
                StandardOutPath = "${logDir}/fleet-heartbeat.log";
                StandardErrorPath = "${logDir}/fleet-heartbeat.err.log";
                EnvironmentVariables = {
                  HOME = config.home.homeDirectory;
                };
              };
            };
          })

          (lib.mkIf pkgs.stdenv.isLinux {
            systemd.user.services.fleet-heartbeat = {
              Unit = {
                Description = "Dendritic fleet heartbeat (no IP)";
                After = [ "default.target" ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${heartbeatScript}";
              };
            };
            systemd.user.timers.fleet-heartbeat = {
              Unit.Description = "Dendritic fleet heartbeat timer";
              Timer = {
                OnBootSec = "1min";
                OnUnitActiveSec = "${toString cfg.intervalSec}s";
                Persistent = true;
                Unit = "fleet-heartbeat.service";
              };
              Install.WantedBy = [ "timers.target" ];
            };
          })
        ]
      );
    };
}

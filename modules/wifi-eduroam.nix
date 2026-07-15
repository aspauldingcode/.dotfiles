# Dendritic EWU eduroam — zero-interaction User Mode 802.1X (1:1 with mba).
#
# Pass → materialize → ensure. No .mobileconfig, no Trust/pinentry UI for Wi-Fi.
# Darwin: preferred WPA2E + Keychain 802.1X + CA PEMs in login keychain.
# Linux/Asahi: keep NM+iwd; write /var/lib/iwd/eduroam.8021x (PEAP/MSCHAPv2).
#
# Secrets never enter the Nix store — only ~/.config/dendritic/wifi/eduroam/*.
{
  flake.modules.nixos.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.eduroam;
    in
    {
      options.dendritic.eduroam = {
        enable = lib.mkEnableOption "dendritic EWU eduroam (pass → iwd 802.1x)" // {
          default = true;
        };
        iwdDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/iwd";
          description = "iwd network directory (eduroam.8021x written here by ensure).";
        };
      };

      config = lib.mkIf cfg.enable {
        # Keep iwd as Wi-Fi backend (do not switch to wpa_supplicant for eduroam).
        networking.networkmanager.wifi.backend = lib.mkDefault "iwd";
        networking.wireless.iwd.settings = {
          General.EnableNetworkConfiguration = lib.mkDefault false;
        };
        systemd.tmpfiles.rules = [
          "d ${cfg.iwdDir} 0700 root root -"
        ];
      };
    };

  flake.modules.darwin.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.eduroam;
    in
    {
      options.dendritic.eduroam = {
        enable = lib.mkEnableOption "dendritic EWU eduroam (pass → Keychain 802.1X)" // {
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        system.activationScripts.postActivation.text = lib.mkAfter ''
          echo "dendritic.eduroam: Wi-Fi power on (AirPort) for eduroam readiness"
          for dev in $(/usr/sbin/networksetup -listallhardwareports \
            | /usr/bin/awk '/Wi-Fi|AirPort/{getline; print $2}'); do
            /usr/sbin/networksetup -setairportpower "$dev" on 2>/dev/null || true
          done
        '';
      };
    };

  flake.modules.homeManager.dendritic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.dendritic.eduroam;
      baseRel = ".config/dendritic/wifi/eduroam";
      basePath = "${config.home.homeDirectory}/${baseRel}";
      watchPaths = [
        "${basePath}/identity"
        "${basePath}/password"
        "${basePath}/ca.pem"
        "${basePath}/profile.json"
      ];

      ensureBin = pkgs.writeShellScriptBin "dendritic-eduroam-ensure" ''
        set -euo pipefail
        export PATH="${
          lib.makeBinPath (
            with pkgs;
            [
              coreutils
              gnugrep
              gawk
              gnused
              jq
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              networkmanager
              iwd
            ]
          )
        }:$PATH"
        exec ${pkgs.bash}/bin/bash ${../scripts/dendritic-eduroam-ensure.sh}
      '';

      rotateBin = pkgs.writeShellScriptBin "dendritic-eduroam-rotate" ''
        set -euo pipefail
        export PATH="${
          lib.makeBinPath (
            with pkgs;
            [
              coreutils
              gnugrep
              gawk
              gnused
              openssl
              pass
              jq
              bash
            ]
          )
        }:${ensureBin}/bin:${config.home.profileDirectory}/bin:$PATH"
        exec ${pkgs.bash}/bin/bash ${../scripts/dendritic-eduroam-rotate.sh}
      '';
    in
    {
      options.dendritic.eduroam = {
        enable = lib.mkEnableOption "dendritic EWU eduroam ensure (pass → OS)" // {
          default = true;
        };
        rotate.enable = lib.mkEnableOption "periodic online CA refresh into pass" // {
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          ensureBin
          rotateBin
        ];

        home.activation.dendriticEduroamEnsure =
          lib.hm.dag.entryAfter
            [
              "passMaterialize"
              "dendriticWifiEnsure"
              "writeBoundary"
            ]
            ''
              ${ensureBin}/bin/dendritic-eduroam-ensure || echo "dendritic.eduroam: ensure skipped/failed" >&2
            '';

        systemd.user.paths.dendritic-eduroam-ensure = lib.mkIf pkgs.stdenv.isLinux {
          Unit.Description = "Watch dendritic eduroam materialize files";
          Path.PathModified = "${basePath}/password";
          Path.PathExists = "${basePath}/password";
          Install.WantedBy = [ "default.target" ];
        };
        systemd.user.services.dendritic-eduroam-ensure = lib.mkIf pkgs.stdenv.isLinux {
          Unit.Description = "Ensure EWU eduroam via iwd 802.1x";
          Service = {
            Type = "oneshot";
            ExecStart = "${ensureBin}/bin/dendritic-eduroam-ensure";
            Environment = [ "DENDRITIC_EDUROAM_DIR=${basePath}" ];
          };
          Install.WantedBy = [ "default.target" ];
        };

        systemd.user.timers.dendritic-eduroam-rotate = lib.mkIf (pkgs.stdenv.isLinux && cfg.rotate.enable) {
          Unit.Description = "Periodic EWU eduroam CA rotate (when uplink exists)";
          Timer = {
            OnCalendar = "weekly";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
          Install.WantedBy = [ "timers.target" ];
        };
        systemd.user.services.dendritic-eduroam-rotate =
          lib.mkIf (pkgs.stdenv.isLinux && cfg.rotate.enable)
            {
              Unit.Description = "Refresh eduroam CA into pass and re-apply";
              Service = {
                Type = "oneshot";
                ExecStart = "${rotateBin}/bin/dendritic-eduroam-rotate";
              };
            };

        launchd.agents.dendritic-eduroam-ensure = lib.mkIf pkgs.stdenv.isDarwin {
          enable = true;
          config = {
            Label = "com.dendritic.eduroam-ensure";
            ProgramArguments = [ "${ensureBin}/bin/dendritic-eduroam-ensure" ];
            RunAtLoad = true;
            WatchPaths = watchPaths;
            EnvironmentVariables = {
              DENDRITIC_EDUROAM_DIR = basePath;
            };
            StandardOutPath = "${config.home.homeDirectory}/.cache/dendritic-eduroam-ensure.log";
            StandardErrorPath = "${config.home.homeDirectory}/.cache/dendritic-eduroam-ensure.err.log";
          };
        };

        launchd.agents.dendritic-eduroam-rotate = lib.mkIf (pkgs.stdenv.isDarwin && cfg.rotate.enable) {
          enable = true;
          config = {
            Label = "com.dendritic.eduroam-rotate";
            ProgramArguments = [ "${rotateBin}/bin/dendritic-eduroam-rotate" ];
            StartCalendarInterval = [
              {
                Weekday = 1;
                Hour = 10;
                Minute = 15;
              }
            ];
            StandardOutPath = "${config.home.homeDirectory}/.cache/dendritic-eduroam-rotate.log";
            StandardErrorPath = "${config.home.homeDirectory}/.cache/dendritic-eduroam-rotate.err.log";
          };
        };
      };
    };
}

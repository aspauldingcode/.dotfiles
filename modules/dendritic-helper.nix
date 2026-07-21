# Root privileged helper — one-time trust via launchd/systemd (no osascript).
{
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.helper;
      dendritic = pkgs.callPackage ../crates/dendritic/_package.nix { };
    in
    {
      options.dendritic.helper = {
        enable = lib.mkEnableOption "dendritic privileged helper daemon (Unix socket IPC)";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ dendritic ];

        launchd.daemons.dendritic-helper = {
          serviceConfig = {
            Label = "com.aspauldingcode.dendritic-helper";
            ProgramArguments = [
              (lib.getExe dendritic)
              "helper"
              "run"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/var/log/dendritic-helper.log";
            StandardErrorPath = "/var/log/dendritic-helper.err.log";
          };
        };

        system.activationScripts.postActivation.text = lib.mkAfter ''
          # Drop legacy reverse-DNS labels (pre-aspauldingcode rename).
          for legacy in \
            com.aspaulding.dendritic-helper \
            com.aspaulding.dendritic-appearance-watch \
            com.aspaulding.dendritic-wireguard \
            com.aspaulding.macrdp \
            com.aspaulding.macrdp-bonjour \
            com.aspaulding.macrdp-portfwd \
            com.aspaulding.ollama \
            com.aspaulding.ollama-model-loader \
            com.dendritic.dendritic-helper
          do
            /bin/launchctl bootout "system/$legacy" >/dev/null 2>&1 || true
            /bin/rm -f "/Library/LaunchDaemons/$legacy.plist" >/dev/null 2>&1 || true
          done
          /bin/launchctl bootout system/com.aspauldingcode.dendritic-helper >/dev/null 2>&1 || true
          /bin/launchctl bootstrap system /Library/LaunchDaemons/com.aspauldingcode.dendritic-helper.plist >/dev/null 2>&1 \
            || /bin/launchctl load -w /Library/LaunchDaemons/com.aspauldingcode.dendritic-helper.plist >/dev/null 2>&1 \
            || true
          /bin/launchctl kickstart -k system/com.aspauldingcode.dendritic-helper >/dev/null 2>&1 || true
        '';
      };
    };

  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.helper;
      dendritic = pkgs.callPackage ../crates/dendritic/_package.nix { };
    in
    {
      options.dendritic.helper = {
        enable = lib.mkEnableOption "dendritic privileged helper daemon (Unix socket IPC)";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ dendritic ];

        systemd.tmpfiles.rules = [
          "d /var/run/dendritic 0755 root root -"
        ];

        systemd.services.dendritic-helper = {
          description = "Dendritic privileged helper (allowlisted IPC)";
          wantedBy = [ "multi-user.target" ];
          after = [ "local-fs.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${lib.getExe dendritic} helper run";
            Restart = "always";
            RestartSec = 1;
          };
        };
      };
    };

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.helper;
      dendritic = pkgs.callPackage ../crates/dendritic/_package.nix { };
    in
    {
      options.dendritic.helper = {
        enable = lib.mkEnableOption "Install dendritic CLI in the user profile";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ dendritic ];

        # Boot out user agents that still carry pre-rename Labels.
        home.activation.bootoutLegacyLaunchdLabels = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            uid="$(${pkgs.coreutils}/bin/id -u)"
            domain="gui/$uid"
            for legacy in \
              com.aspaulding.pass-rotate-reminder \
              com.aspaulding.pass-store-sync \
              com.aspaulding.pass-store-sync-notify \
              com.aspaulding.pass-store-tray \
              com.aspaulding.pass-rotate-cli-auth \
              com.aspaulding.fleet-heartbeat \
              com.aspaulding.android-converge \
              com.aspaulding.dendritic-appearance \
              com.aspaulding.dendritic-wallpaper-daily \
              com.aspaulding.dendritic-avatar \
              com.dendritic.wifi-ensure \
              com.dendritic.eduroam-ensure \
              com.dendritic.eduroam-rotate \
              com.dendritic.gpg-preset-from-sops \
              com.dendritic.ghostty-hot-reload
            do
              /bin/launchctl bootout "$domain/$legacy" >/dev/null 2>&1 || true
            done
          ''
        );
      };
    };
}

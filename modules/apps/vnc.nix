# ── Dendritic VNC (macOS Screen Sharing + Bonjour) ──────────────────────
#
# Restores Apple Screen Sharing after macrdp (which disabled it). When
# enabled:
#   • root activation re-enables com.apple.screensharing (RFB :5900)
#   • launchd socket Bonjour key "rfb" advertises `_rfb._tcp`
#   • HM agent also dns-sd -R <bonjourName> for Finder / iPhone discovery
#
# Auth: macOS user login (System Settings → General → Sharing → Screen
# Sharing). Optional VNC viewers: open vnc://mba.local
{
  flake.modules.darwin.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.vnc;
    in
    {
      options.dendritic.apps.vnc = {
        enable = lib.mkEnableOption "Apple Screen Sharing (VNC) + Bonjour (_rfb._tcp)";

        port = lib.mkOption {
          type = lib.types.port;
          default = 5900;
          description = "VNC / RFB listen port (Apple Screen Sharing default).";
        };

        bonjourName = lib.mkOption {
          type = lib.types.str;
          default = config.networking.hostName or "mba";
          description = "DNS-SD instance name shown in Bonjour browsers.";
        };
      };

      config = lib.mkIf cfg.enable {
        # screensharingd already ships with SockServiceName=vnc-server and
        # Bonjour=rfb — just undo the launchctl disable left by macrdp.
        system.activationScripts.postActivation.text = lib.mkAfter ''
          echo "dendritic.vnc: enabling com.apple.screensharing (VNC :${toString cfg.port})"
          /bin/launchctl enable system/com.apple.screensharing 2>/dev/null || true
          if ! /bin/launchctl print system/com.apple.screensharing >/dev/null 2>&1; then
            /bin/launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist \
              2>/dev/null \
              || /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist \
              2>/dev/null \
              || true
          fi
          /bin/launchctl kickstart -k system/com.apple.screensharing 2>/dev/null || true
        '';
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
      cfg = config.dendritic.apps.vnc;
      bonjourName = cfg.bonjourName;
      port = cfg.port;
      # writeShellScriptBin so Login Items show `vnc-bonjour`, not HASH-….
      dnsSd = pkgs.writeShellScriptBin "vnc-bonjour" ''
        exec /usr/bin/dns-sd -R ${lib.escapeShellArg bonjourName} _rfb._tcp local ${toString port}
      '';
    in
    {
      options.dendritic.apps.vnc = {
        enable = lib.mkEnableOption "VNC Bonjour agent (_rfb._tcp via dns-sd)";

        port = lib.mkOption {
          type = lib.types.port;
          default = 5900;
          description = "Port advertised via Bonjour (matches Screen Sharing).";
        };

        bonjourName = lib.mkOption {
          type = lib.types.str;
          default = "mba";
          description = "DNS-SD instance name.";
        };
      };

      config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
        home.packages = [ dnsSd ];

        launchd.agents.vnc-bonjour = {
          enable = true;
          config = {
            Label = "com.aspauldingcode.vnc-bonjour";
            ProgramArguments = [ (lib.getExe dnsSd) ];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${config.home.homeDirectory}/.local/state/vnc/bonjour.log";
            StandardErrorPath = "${config.home.homeDirectory}/.local/state/vnc/bonjour.err.log";
          };
        };

        home.activation.vncStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${config.home.homeDirectory}/.local/state/vnc"
        '';
      };
    };
}

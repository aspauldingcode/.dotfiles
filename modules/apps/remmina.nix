# Remmina — GTK remote desktop client (VNC / RDP / Spice) for NixOS.
#
# nixpkgs remmina already links libvncserver + FreeRDP + Spice; no extra
# plugin packages. Ships with niri on Linux; hosts can mkForce false.
#
# mba Screen Sharing: profiles 8amps@mba.local and 8amps@10.87.0.1. Password
# is LOGIN_PASSWORD (pass → ~/.config/dendritic/identity/login.password),
# encrypted into the .remmina file with Remmina's 3DES secret — not
# gnome-keyring (locked login.keyring loops forever on this host).
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.remmina;
      niriOn = config.dendritic.apps.niri.enable or false;
      py = pkgs.python3.withPackages (ps: [ ps.pycryptodome ]);
      remminaAuth = pkgs.writeShellApplication {
        name = "dendritic-remmina-auth";
        runtimeInputs = [
          py
          pkgs.coreutils
        ];
        text = ''
          exec ${py}/bin/python3 ${../../scripts/dendritic-remmina-auth.py} "$@"
        '';
      };
      remminaBin = lib.getExe pkgs.remmina;
      nosecretPlugin = pkgs.stdenv.mkDerivation {
        pname = "remmina-plugin-nosecret";
        version = "1";
        src = ./_remmina-nosecret.c;
        dontUnpack = true;
        nativeBuildInputs = [
          pkgs.pkg-config
        ];
        buildInputs = [
          pkgs.gtk3
          pkgs.glib
          pkgs.remmina
        ];
        buildPhase = ''
          gcc -shared -fPIC -o remmina-plugin-nosecret.so "$src" \
            $(pkg-config --cflags gtk+-3.0 glib-2.0) \
            -I${pkgs.remmina}/include \
            $(pkg-config --libs gtk+-3.0 glib-2.0) \
            -lgmodule-2.0
        '';
        installPhase = ''
          install -Dm644 remmina-plugin-nosecret.so \
            $out/lib/remmina/plugins/remmina-plugin-nosecret.so
        '';
      };
      vncMba = pkgs.writeShellApplication {
        name = "dendritic-vnc-mba";
        runtimeInputs = [
          remminaAuth
          pkgs.remmina
        ];
        text = ''
          target=mba
          if [ "''${1:-}" = --wg ]; then
            target=mba-wg
            shift
          fi
          exec ${lib.getExe remminaAuth} --connect "$target" --remmina ${lib.escapeShellArg remminaBin} "$@"
        '';
      };
    in
    {
      options.dendritic.apps.remmina = {
        enable = lib.mkEnableOption ''
          Remmina remote desktop client (VNC / RDP / Spice) from nixpkgs.
        '';

        mba = {
          enable = lib.mkEnableOption ''
            Pre-auth Remmina VNC profiles for 8amps@mba (Screen Sharing).
          '';

          username = lib.mkOption {
            type = lib.types.str;
            default = "8amps";
            description = "macOS Screen Sharing user on mba.";
          };

          server = lib.mkOption {
            type = lib.types.str;
            default = "mba.local";
            description = "LAN / Bonjour host (docs/wireguard.md).";
          };

          wireguardServer = lib.mkOption {
            type = lib.types.str;
            default = "10.87.0.1";
            description = "mba overlay address when away from Bubbles.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 5900;
            description = "RFB port (Apple Screen Sharing default).";
          };

          passwordFile = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.config/dendritic/identity/login.password";
            description = ''
              Materialized LOGIN_PASSWORD (same secret as NixOS / Windows login).
              Used as the 8amps macOS Screen Sharing password. Never in the Nix store.
            '';
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (niriOn && pkgs.stdenv.isLinux) {
          dendritic.apps.remmina.enable = lib.mkDefault true;
        })

        (lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
          dendritic.apps.remmina.mba.enable = lib.mkDefault true;

          services.remmina = {
            enable = true;
            package = pkgs.remmina;
            # Client-only: skip remmina --icon so it does not occupy the niri tray.
            systemdService.enable = false;
          };

          xdg.mimeApps = {
            enable = true;
            defaultApplications = {
              "x-scheme-handler/vnc" = [ "org.remmina.Remmina.desktop" ];
              "x-scheme-handler/rdp" = [ "org.remmina.Remmina.desktop" ];
            };
          };
        })

        (lib.mkIf (cfg.enable && cfg.mba.enable && pkgs.stdenv.isLinux) {
          home.packages = [
            remminaAuth
            vncMba
          ];

          # Beat glibsecret (init_order 2000): no Login keyring unlock prompt.
          xdg.configFile."remmina/plugins/remmina-plugin-nosecret.so".source =
            "${nosecretPlugin}/lib/remmina/plugins/remmina-plugin-nosecret.so";

          xdg.desktopEntries.dendritic-vnc-mba = {
            name = "8amps@mba (VNC)";
            genericName = "Remote Desktop";
            comment = "Screen Sharing — 8amps@mba.local";
            exec = "dendritic-vnc-mba";
            icon = "org.remmina.Remmina";
            categories = [
              "Network"
              "RemoteAccess"
            ];
            startupNotify = true;
          };

          xdg.desktopEntries.dendritic-vnc-mba-wg = {
            name = "8amps@mba (VNC / WireGuard)";
            genericName = "Remote Desktop";
            comment = "Screen Sharing — 8amps@10.87.0.1";
            exec = "dendritic-vnc-mba --wg";
            icon = "org.remmina.Remmina";
            categories = [
              "Network"
              "RemoteAccess"
            ];
            startupNotify = true;
          };

          home.activation.remminaMba = lib.hm.dag.entryAfter [ "passMaterialize" "writeBoundary" ] ''
            ${lib.getExe remminaAuth} \
              --username ${lib.escapeShellArg cfg.mba.username} \
              --server ${lib.escapeShellArg cfg.mba.server} \
              --wg-server ${lib.escapeShellArg cfg.mba.wireguardServer} \
              --port ${toString cfg.mba.port} \
              --password-file ${lib.escapeShellArg cfg.mba.passwordFile} \
              || echo "remmina: mba profile skipped/failed" >&2
          '';
        })
      ];
    };
}

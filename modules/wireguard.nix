{
  # Dendritic WireGuard (wg-quick) — mba ↔ sliceanddice overlay.
  #
  # Secrets live in private pass (SecretSpec WG_*), not the Nix store / sops.
  # Public peer table: home/wireguard-peers.json (addresses + ports only).
  # Endpoints / home-hub role: pass-wg-set-home (never commit public IPs).
  #
  # On Bubbles/LAN: ensure resolves peer via mDNS (*.local) when WG_ENDPOINT_* empty.
  # Remote: set home endpoint in pass; traveler dials; RDP/SSH over 10.87.0.0/24.
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.wireguard;
    in
    {
      options.dendritic.wireguard = {
        enable = lib.mkEnableOption "WireGuard overlay (wg-quick dendritic) via pass/SecretSpec";
        interface = lib.mkOption {
          type = lib.types.str;
          default = "dendritic";
          description = "wg-quick interface name.";
        };
        listenPort = lib.mkOption {
          type = lib.types.port;
          default = 51820;
          description = "UDP listen port (must match home/wireguard-peers.json).";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          wireguard-tools
        ];

        networking.firewall.allowedUDPPorts = [ cfg.listenPort ];
        # RDP/SSH already opened for LAN; tunnel traffic uses AllowedIPs host routes.

        networking.wg-quick.interfaces.${cfg.interface} = {
          # Conf written by dendritic-wg-ensure from pass (never Nix store secrets).
          configFile = "/etc/wireguard/${cfg.interface}.conf";
        };

        # If conf is missing at boot (pre-bootstrap), don't fail the whole system.
        # Down-before-up: avoid "already exists" when ensure or a prior gen left the iface up.
        systemd.services."wg-quick-${cfg.interface}" = {
          unitConfig.ConditionPathExists = "/etc/wireguard/${cfg.interface}.conf";
          serviceConfig.ExecStartPre = [
            "-${pkgs.wireguard-tools}/bin/wg-quick down ${cfg.interface}"
          ];
        };
      };
    };

  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.wireguard;
      iface = cfg.interface;
      # writeShellScriptBin so Login Items show `dendritic-wg-quick-up`, not HASH-….
      wgQuickUp = pkgs.writeShellScriptBin "dendritic-wg-quick-up" ''
        set -euo pipefail
        conf=/etc/wireguard/${iface}.conf
        if [ ! -f "$conf" ]; then
          echo "dendritic.wireguard: $conf missing — run pass-wg-bootstrap + dendritic-wg-ensure" >&2
          exit 0
        fi
        ${pkgs.wireguard-tools}/bin/wg-quick down ${lib.escapeShellArg iface} 2>/dev/null || true
        exec ${pkgs.wireguard-tools}/bin/wg-quick up ${lib.escapeShellArg iface}
      '';
    in
    {
      options.dendritic.wireguard = {
        enable = lib.mkEnableOption "WireGuard overlay (wg-quick dendritic) via pass/SecretSpec";
        interface = lib.mkOption {
          type = lib.types.str;
          default = "dendritic";
        };
        listenPort = lib.mkOption {
          type = lib.types.port;
          default = 51820;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.wireguard-tools ];

        launchd.daemons.dendritic-wireguard = {
          serviceConfig = {
            Label = "com.aspauldingcode.dendritic-wireguard";
            ProgramArguments = [ (lib.getExe wgQuickUp) ];
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "/var/log/dendritic-wireguard.log";
            StandardErrorPath = "/var/log/dendritic-wireguard.err.log";
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
      cfg = config.dendritic.wireguard;
      # This file lives in modules/ (not modules/apps/) — one .. to repo root.
      peersJson = ../home/wireguard-peers.json;
      secretspecToml = ../home/secretspec.toml;
      passPackage = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      dendriticPkg = pkgs.callPackage ../crates/dendritic/_package.nix { };
      ensureBin = pkgs.writeShellApplication {
        name = "dendritic-wg-ensure";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          gnupg
          git
          hostname
          wireguard-tools
          python3
          passPackage
          secretspec
          dendriticPkg
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export WG_PEERS_JSON=${lib.escapeShellArg "${peersJson}"}
          export SECRETSPEC_TOML=${lib.escapeShellArg "${secretspecToml}"}
          export WG_IFACE=${lib.escapeShellArg cfg.interface}
          export WG_PEER_ID=${lib.escapeShellArg cfg.peerId}
          export DENDRITIC_BIN=${lib.getExe dendriticPkg}
          export WG_PREFER_DENDRITIC_HELPER=1
          exec bash ${../scripts/dendritic-wg-ensure.sh} "$@"
        '';
      };
      rdpBin = pkgs.writeShellApplication {
        name = "dendritic-wg-rdp";
        runtimeInputs = with pkgs; [
          python3
          freerdp
        ];
        text = ''
          set -euo pipefail
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export WG_PEERS_JSON=${lib.escapeShellArg "${peersJson}"}
          exec bash ${../scripts/dendritic-wg-rdp.sh} "$@"
        '';
      };
      bootstrapBin = pkgs.writeShellApplication {
        name = "pass-wg-bootstrap";
        runtimeInputs = with pkgs; [
          coreutils
          wireguard-tools
          python3
          git
          passPackage
          bash
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export WG_PEERS_JSON=${lib.escapeShellArg "${peersJson}"}
          exec bash ${../scripts/pass-wg-bootstrap.sh} "$@"
        '';
      };
      rotateBin = pkgs.writeShellApplication {
        name = "pass-wg-rotate";
        runtimeInputs = with pkgs; [
          coreutils
          wireguard-tools
          python3
          git
          passPackage
          bash
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export WG_PEERS_JSON=${lib.escapeShellArg "${peersJson}"}
          exec bash ${../scripts/pass-wg-rotate.sh} "$@"
        '';
      };
      setHomeBin = pkgs.writeShellApplication {
        name = "pass-wg-set-home";
        runtimeInputs = with pkgs; [
          coreutils
          python3
          git
          passPackage
          bash
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export WG_PEERS_JSON=${lib.escapeShellArg "${peersJson}"}
          exec bash ${../scripts/pass-wg-set-home.sh} "$@"
        '';
      };
    in
    {
      options.dendritic.wireguard = {
        enable = lib.mkEnableOption "WireGuard overlay helpers (ensure / RDP / pass rotate)";
        interface = lib.mkOption {
          type = lib.types.str;
          default = "dendritic";
        };
        peerId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Override peer id (mba|sliceanddice). Empty = hostname -s.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          dendriticPkg
          ensureBin
          rdpBin
          bootstrapBin
          rotateBin
          setHomeBin
          pkgs.wireguard-tools
          pkgs.freerdp
        ];

        # Write conf only during activation (no interactive sudo / Touch ID).
        # Bring-up via root helper IPC / NixOS wg-quick / Darwin launchd.
        home.activation.dendriticWireguard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ -d "$HOME/.password-store" ]; then
            ${lib.getExe dendriticPkg} wg ensure --no-up \
              || WG_ENSURE_NO_UP=1 WG_SUDO_INTERACTIVE=0 ${ensureBin}/bin/dendritic-wg-ensure \
              || echo "dendritic.wireguard: ensure skipped (bootstrap keys?)" >&2
          fi
        '';
      };
    };
}

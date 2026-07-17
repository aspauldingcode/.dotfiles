# ── Dendritic RDP (NixOS / Wayland) ─────────────────────────────────────
#
# Shares the *existing* niri Wayland session over real RDP — not a nested
# X11 login. Implemented with lamco-rdp-server (IronRDP + XDG Desktop Portal
# + PipeWire). xrdp is intentionally NOT used (it only starts a separate
# Xorg session and is useless on a Wayland-only host).
#
# Discovery: Avahi `_rdp._tcp` → connect as `sliceanddice.local` from iPhone
# Microsoft Remote Desktop (no IP typing).
#
# Auth: PAM (Linux account password). First connect may show a portal
# permission dialog once; run `lamco-rdp-server --grant-permission` if needed.
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.rdp;
      port = cfg.port;
      lamco = pkgs.callPackage ./rdp/_lamco-package.nix { };
    in
    {
      options.dendritic.apps.rdp = {
        enable = lib.mkEnableOption "Wayland RDP (lamco) + Bonjour/mDNS (_rdp._tcp)";

        port = lib.mkOption {
          type = lib.types.port;
          default = 3389;
          description = "RDP listen port (also advertised via Avahi).";
        };

        bonjourName = lib.mkOption {
          type = lib.types.str;
          default = config.networking.hostName;
          description = "DNS-SD / Bonjour instance name (shown in Microsoft Remote Desktop).";
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open the RDP TCP port in networking.firewall.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isx86_64;
            message = "dendritic.apps.rdp currently packages lamco's amd64 deb (x86_64-linux only).";
          }
        ];

        environment.systemPackages = [
          lamco
          pkgs.openssl
          pkgs.freerdp
        ];

        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ port ];

        # niri already pulls xdg-desktop-portal-gnome; keep RemoteDesktop usable.
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        };

        # Bonjour/mDNS discovery for iPhone Microsoft Remote Desktop (and dns-sd).
        # Force-on when RDP is enabled — do not leave this as a soft default.
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
          publish = {
            enable = true;
            addresses = true;
            domain = true;
            workstation = true;
          };
          # protocol=ipv4: clients often prefer AAAA from .local and fail when
          # IPv6 routes are broken; IPv4 advertisement matches mba Bonjour.
          extraServiceFiles.rdp = ''
            <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
              <name replace-wildcards="yes">${cfg.bonjourName}</name>
              <service protocol="ipv4">
                <type>_rdp._tcp</type>
                <port>${toString port}</port>
              </service>
            </service-group>
          '';
        };

        # Make sure xrdp stays off if something else enabled it historically.
        services.xrdp.enable = lib.mkForce false;
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
      cfg = config.dendritic.apps.rdp;
      lamco = pkgs.callPackage ./rdp/_lamco-package.nix { };
      port = cfg.port;
      cfgDir = "${config.home.homeDirectory}/.config/lamco-rdp-server";
    in
    {
      options.dendritic.apps.rdp = {
        enable = lib.mkEnableOption "lamco RDP user service (shares this Wayland session)";

        port = lib.mkOption {
          type = lib.types.port;
          default = 3389;
        };
      };

      config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
        home.packages = [ lamco ];

        # Generate a schema-valid config from the binary, then pin listen/auth/certs.
        # (Hand-written partial TOML breaks when lamco adds required fields.)
        home.activation.lamcoRdpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${cfgDir}"
          if [[ ! -s "${cfgDir}/cert.pem" || ! -s "${cfgDir}/key.pem" ]]; then
            ${lib.getExe pkgs.openssl} req -x509 -newkey rsa:2048 -sha256 -nodes -days 825 \
              -subj "/CN=${config.home.username}-lamco-rdp" \
              -keyout "${cfgDir}/key.pem" -out "${cfgDir}/cert.pem"
            chmod 600 "${cfgDir}/key.pem"
            chmod 644 "${cfgDir}/cert.pem"
          fi
          ${lib.getExe lamco} --generate-config > "${cfgDir}/config.toml"
          ${pkgs.python3}/bin/python3 - "${cfgDir}/config.toml" "${toString port}" "${cfgDir}" <<'PY'
          from pathlib import Path
          import sys
          path, port, cfgdir = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
          text = path.read_text()
          # Minimal deterministic overrides (keep the rest of the generated schema).
          reps = {
              'listen_addr = "[::]:3389"': f'listen_addr = "0.0.0.0:{port}"',
              'listen_addr = "0.0.0.0:3389"': f'listen_addr = "0.0.0.0:{port}"',
              'auth_method = "none"': 'auth_method = "pam"',
              'security_mode = "auto"': 'security_mode = "tls"',
              # niri exposes wlr screencopy + virtual pointer, but GNOME's
              # RemoteDesktop portal is unreliable here — prefer direct wlr.
              'use_portals = true': 'use_portals = false',
              'input_protocol = "auto"': 'input_protocol = "wlr"',
          }
          for a, b in reps.items():
              text = text.replace(a, b)
          # Force cert paths to this user's config dir.
          import re
          text = re.sub(r'(?m)^cert_path = ".*"$', f'cert_path = "{cfgdir}/cert.pem"', text, count=1)
          text = re.sub(r'(?m)^key_path = ".*"$', f'key_path = "{cfgdir}/key.pem"', text, count=1)
          path.write_text(text)
          PY
          chmod 600 "${cfgDir}/config.toml" || true
        '';

        systemd.user.services.lamco-rdp-server = {
          Unit = {
            Description = "Lamco Wayland RDP server (dendritic)";
            Documentation = [ "https://github.com/lamco-admin/lamco-rdp-server" ];
            After = [
              "graphical-session.target"
              "pipewire.service"
            ];
            Wants = [ "graphical-session.target" ];
            # Need an active Wayland session to share.
            ConditionEnvironment = "WAYLAND_DISPLAY";
            # StartLimit* belongs in [Unit] — under [Service] systemd ignores it
            # (was causing endless Restart=on-failure storms every 15s).
            StartLimitIntervalSec = 120;
            StartLimitBurst = 3;
          };
          Service = {
            Type = "simple";
            # Avoid EADDRINUSE restart storms when a previous instance still holds :3389.
            ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.procps}/bin/pkill -x lamco-rdp-server || ${pkgs.procps}/bin/pkill -f lamco-rdp-server || true; sleep 0.3'";
            ExecStart = "${lib.getExe lamco} --config ${cfgDir}/config.toml";
            # Crash-looping on SIGTERM/session teardown is not "failure worth retry".
            Restart = "on-abnormal";
            RestartSec = "15";
            Environment = [ "RUST_LOG=info" ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}

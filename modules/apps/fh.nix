{
  # FlakeHub / Determinate Nix auth from pass (SecretSpec).
  #
  # Login: activation reads FLAKEHUB_TOKEN from pass → determinate-nixd login.
  # Rotate: fully automated via `determinate-nixd auth token device create`
  #   (weekly agent + activation when within autoRotate.daysBefore of expiry).
  #   nix run .#pass-rotate-cli-auth -- --status
  #   nix run .#pass-rotate-cli-auth -- --auto
  # GitHub classic PATs still need a one-shot paste when due:
  #   nix run .#pass-rotate-cli-auth -- --github
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.dendritic.apps.fh;
      passCfg = config.dendritic.apps.pass;
      secretspecToml = ../../home/secretspec.toml;
      passPackage = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      storeDir = "${config.home.homeDirectory}/.password-store";
      secretspecBin = "${pkgs.secretspec}/bin/secretspec";
      passPath = lib.makeBinPath [
        passPackage
        pkgs.gnupg
        pkgs.secretspec
        pkgs.coreutils
      ];
      org = if cfg.organization != null then cfg.organization else "aspauldingcode";
      rotateCliAuth = pkgs.writeShellApplication {
        name = "pass-rotate-cli-auth";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          gnugrep
          gnupg
          git
          python3
          passPackage
          fh
          gh
          bash
          (pkgs.writeShellApplication {
            name = "github-app-mint-token";
            runtimeInputs = with pkgs; [
              coreutils
              curl
              gnugrep
              gnupg
              git
              python3
              passPackage
              bash
            ];
            text = ''
              set -euo pipefail
              export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
              exec bash ${../../scripts/github-app-mint-token.sh} "$@"
            '';
          })
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
          export FLAKEHUB_ORG=${lib.escapeShellArg org}
          export DOTFILES_ROOT=${lib.escapeShellArg (toString ../..)}
          exec bash ${../../scripts/pass-rotate-cli-auth.sh} "$@"
        '';
      };
      autoRotateCmd = pkgs.writeShellScript "pass-rotate-cli-auth-auto" ''
        export PATH="${
          lib.makeBinPath [
            rotateCliAuth
            pkgs.coreutils
          ]
        }:$PATH"
        # determinate-nixd comes from the system profile when present.
        exec pass-rotate-cli-auth --auto --yes \
          --days ${toString cfg.autoRotate.daysBefore} \
          --org ${lib.escapeShellArg org}
      '';
      loginScript = pkgs.writeShellScript "flakehub-pass-login" ''
        set -euo pipefail
        export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
        export PATH="${passPath}:$PATH"

        if ! command -v determinate-nixd >/dev/null 2>&1; then
          echo "flakehub-auth: determinate-nixd not on PATH; skip" >&2
          exit 0
        fi

        _token="$(${secretspecBin} get -f ${secretspecToml} FLAKEHUB_TOKEN 2>/dev/null || true)"
        if [ -z "$_token" ] || [ "$_token" = "placeholder" ]; then
          echo "flakehub-auth: FLAKEHUB_TOKEN missing in pass; skip" >&2
          exit 0
        fi

        _tf="$(mktemp)"
        trap 'rm -f "$_tf"' EXIT
        umask 077
        printf '%s\n' "$_token" > "$_tf"

        if determinate-nixd login token --token-file "$_tf" 2>/dev/null \
          || determinate-nixd auth login token --token-file "$_tf" 2>/dev/null; then
          echo "flakehub-auth: logged in via pass FLAKEHUB_TOKEN"
        else
          echo "flakehub-auth: login failed; check token" >&2
          exit 0
        fi

        determinate-nixd auth bind ${lib.escapeShellArg org} 2>/dev/null \
          || echo "flakehub-auth: bind ${org} failed (non-fatal)" >&2
      '';
      realFh = pkgs.fh;
      fh = pkgs.writeShellScriptBin "fh" ''
        if command -v determinate-nixd >/dev/null 2>&1; then
          if ! determinate-nixd status 2>/dev/null | grep -q 'Logged in: true'; then
            ${loginScript} || true
          fi
        elif ! ${realFh}/bin/fh status 2>/dev/null | grep -q 'Logged in: true'; then
          export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
          export PATH="${passPath}:$PATH"
          _token="$(${secretspecBin} get -f ${secretspecToml} FLAKEHUB_TOKEN 2>/dev/null || true)"
          if [ -n "$_token" ] && [ "$_token" != "placeholder" ]; then
            _tf="$(mktemp)"
            printf '%s\n' "$_token" > "$_tf"
            ${realFh}/bin/fh login --token-file "$_tf" --skip-status 2>/dev/null || true
            rm -f "$_tf"
          fi
        fi
        exec ${realFh}/bin/fh "$@"
      '';
    in
    {
      options.dendritic.apps.fh = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install fh wrapper and pass-backed FlakeHub login on activation.";
        };
        organization = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "aspauldingcode";
          description = "FlakeHub org for auth bind + device-token rotation.";
        };
        autoRotate = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Automatically mint a new FlakeHub device token into pass when the
              current token is within daysBefore of expiry (activation + weekly agent).
              GitHub classic PATs cannot be auto-minted; you get a notification instead.
            '';
          };
          daysBefore = lib.mkOption {
            type = lib.types.ints.positive;
            default = 14;
            description = "Rotate (or notify) when expiry is within this many days.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          fh
          rotateCliAuth
        ];

        home.activation.flakehubPassAuth = lib.mkIf passCfg.enable (
          lib.hm.dag.entryAfter [ "passBootstrap" ] ''
            ${loginScript} || true
            ${lib.optionalString cfg.autoRotate.enable ''
              ${autoRotateCmd} || true
            ''}
          ''
        );

        launchd.agents.pass-rotate-cli-auth =
          lib.mkIf (passCfg.enable && cfg.autoRotate.enable && pkgs.stdenv.isDarwin)
            {
              enable = true;
              config = {
                Label = "com.aspaulding.pass-rotate-cli-auth";
                ProgramArguments = [ "${autoRotateCmd}" ];
                StartCalendarInterval = {
                  Weekday = 1; # Monday
                  Hour = 10;
                  Minute = 15;
                };
                StandardOutPath = "${config.home.homeDirectory}/.cache/pass-rotate-cli-auth.log";
                StandardErrorPath = "${config.home.homeDirectory}/.cache/pass-rotate-cli-auth.err.log";
              };
            };

        systemd.user.services.pass-rotate-cli-auth =
          lib.mkIf (passCfg.enable && cfg.autoRotate.enable && pkgs.stdenv.isLinux)
            {
              Unit.Description = "Auto-rotate FlakeHub (and remind GitHub) CLI tokens in pass";
              Service = {
                Type = "oneshot";
                ExecStart = "${autoRotateCmd}";
              };
            };
        systemd.user.timers.pass-rotate-cli-auth =
          lib.mkIf (passCfg.enable && cfg.autoRotate.enable && pkgs.stdenv.isLinux)
            {
              Unit.Description = "Weekly CLI auth token rotation check";
              Timer = {
                OnCalendar = "weekly";
                Persistent = true;
              };
              Install.WantedBy = [ "timers.target" ];
            };
      };
    };
}

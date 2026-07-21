{
  # Vercel CLI auth via pass (SecretSpec) — mirrors gcloud OAuth minting.
  #
  # Priority for the wrapped `vercel` process only:
  #   1. env VERCEL_TOKEN already set
  #   2. OAuth mint (pass refresh_token → access token)  [fully automated]
  #   3. pass VERCEL_TOKEN (static PAT fallback)
  #
  # One-time setup: nix run .#pass-vercel-bootstrap
  # Status / rotate: pass-rotate-cli-auth --status|--vercel
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.dendritic.apps.vercel;
      passCfg = config.dendritic.apps.pass;
      secretspecToml = ../../home/secretspec.toml;
      passPackage = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      storeDir = "${config.home.homeDirectory}/.password-store";
      realVercel = import ../pkgs/_vercel.nix { inherit pkgs; };
      authJsonPath =
        if pkgs.stdenv.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/com.vercel.cli/auth.json"
        else
          "${config.home.homeDirectory}/.local/share/com.vercel.cli/auth.json";
      mintBin = pkgs.writeShellApplication {
        name = "vercel-mint-token";
        runtimeInputs = with pkgs; [
          coreutils # timeout(1) for pass/gpg + curl bounds
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
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export VERCEL_AUTH_JSON=${lib.escapeShellArg authJsonPath}
          # Prefer nix coreutils timeout on PATH (macOS /usr/bin has none).
          export PATH="${pkgs.coreutils}/bin:$PATH"
          exec bash ${../../scripts/vercel-mint-token.sh} "$@"
        '';
      };
      bootstrapBin = pkgs.writeShellApplication {
        name = "pass-vercel-bootstrap";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          gnupg
          git
          python3
          passPackage
          bash
          mintBin
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export VERCEL_AUTH_JSON=${lib.escapeShellArg authJsonPath}
          exec bash ${../../scripts/pass-vercel-bootstrap.sh} "$@"
        '';
      };
      passPath = lib.makeBinPath [
        passPackage
        pkgs.gnupg
        pkgs.secretspec
        pkgs.coreutils # timeout(1) — macOS /usr/bin has none
        pkgs.curl
        pkgs.git
        pkgs.python3
        mintBin
      ];
      loginScript = pkgs.writeShellScript "vercel-pass-login" ''
        set -euo pipefail
        export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
        export PATH="${passPath}:$PATH"
        export VERCEL_AUTH_JSON=${lib.escapeShellArg authJsonPath}

        _auth=${lib.escapeShellArg authJsonPath}
        _store=${lib.escapeShellArg storeDir}
        mkdir -p "$(dirname "$_auth")"
        chmod 0700 "$(dirname "$_auth")" 2>/dev/null || true

        # Existence via .gpg — never `pass show` here (gpg/pinentry can hang activation).
        if [ -f "$_store/secretspec/shared/default/VERCEL_REFRESH_TOKEN.gpg" ]; then
          # One shot: mint + atomic auth.json (never truncate on failure).
          if ${pkgs.coreutils}/bin/timeout 60 ${mintBin}/bin/vercel-mint-token --write-auth >/dev/null; then
            echo "vercel-auth: auth.json from pass OAuth"
          else
            echo "vercel-auth: mint failed — run: pass-vercel-bootstrap or vercel-mint-token --device" >&2
          fi
        elif [ -f "$_store/secretspec/shared/default/VERCEL_TOKEN.gpg" ]; then
          echo "vercel-auth: static VERCEL_TOKEN in pass (wrapper exports on invoke)"
        else
          echo "vercel-auth: no VERCEL_REFRESH_TOKEN / VERCEL_TOKEN in pass; skip" >&2
          exit 0
        fi
      '';
      vercel = pkgs.writeShellScriptBin "vercel" ''
        if [ -z "''${VERCEL_TOKEN:-}" ]; then
          if [ -d ${lib.escapeShellArg storeDir} ]; then
            export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
            export PATH="${passPath}:$PATH"
            export VERCEL_AUTH_JSON=${lib.escapeShellArg authJsonPath}
            _token=""
            _mint_err="$(${pkgs.coreutils}/bin/mktemp)"
            _store=${lib.escapeShellArg storeDir}
            # .gpg probe only — decrypt happens inside mint under timeout.
            if [ -f "$_store/secretspec/shared/default/VERCEL_REFRESH_TOKEN.gpg" ]; then
              # Single mint under lock + atomic auth.json. Bound wait so a hung
              # curl/pass never blocks `vercel` forever (macOS has no system timeout).
              _token="$(${pkgs.coreutils}/bin/timeout 60 ${mintBin}/bin/vercel-mint-token --write-auth 2>"$_mint_err" || true)"
              if [ -z "$_token" ] && [ -s "$_mint_err" ]; then
                echo "vercel-wrapper: mint failed:" >&2
                ${pkgs.coreutils}/bin/sed 's/^/  /' "$_mint_err" >&2 || true
                echo "vercel-wrapper: re-auth: pass-vercel-bootstrap  (or: vercel-mint-token --device)" >&2
              fi
            fi
            rm -f "$_mint_err"
            if [ -z "$_token" ]; then
              _token="$(${pkgs.secretspec}/bin/secretspec get -f ${secretspecToml} VERCEL_TOKEN 2>/dev/null || true)"
            fi
            if [ -n "$_token" ] && [ "$_token" != "placeholder" ]; then
              VERCEL_TOKEN="$_token"
              export VERCEL_TOKEN
            fi
          fi
        fi
        if [ -z "''${VERCEL_ORG_ID:-}" ] && [ -z "''${VERCEL_TEAM_ID:-}" ]; then
          if [ -d ${lib.escapeShellArg storeDir} ]; then
            export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
            _team="$(${pkgs.secretspec}/bin/secretspec get -f ${secretspecToml} VERCEL_TEAM_ID 2>/dev/null || true)"
            if [ -n "$_team" ] && [ "$_team" != "placeholder" ]; then
              VERCEL_TEAM_ID="$_team"
              export VERCEL_TEAM_ID
            fi
          fi
        fi
        exec ${realVercel}/bin/vercel "$@"
      '';
      vc = pkgs.writeShellScriptBin "vc" ''
        exec ${vercel}/bin/vercel "$@"
      '';
    in
    {
      options.dendritic.apps.vercel = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install vercel wrapper and pass-backed Vercel CLI auth on activation.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          vercel
          vc
          mintBin
          bootstrapBin
        ];

        home.activation.vercelPassAuth = lib.mkIf passCfg.enable (
          lib.hm.dag.entryAfter [ "passBootstrap" ] ''
            ${loginScript} || true
          ''
        );
      };
    };
}

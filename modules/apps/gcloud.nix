{
  # Google Cloud SDK auth via pass (SecretSpec) — mirrors gh App minting.
  #
  # Priority for the wrapped `gcloud` process only:
  #   1. env CLOUDSDK_AUTH_ACCESS_TOKEN already set
  #   2. OAuth mint (pass refresh_token → access token)  [fully automated]
  #   3. pass GCLOUD_SA_KEY (service-account JSON fallback)
  #
  # One-time setup: nix run .#pass-gcloud-bootstrap
  # Status / rotate: pass-rotate-cli-auth --status|--gcloud
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.dendritic.apps.gcloud;
      passCfg = config.dendritic.apps.pass;
      secretspecToml = ../../home/secretspec.toml;
      passPackage = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      storeDir = "${config.home.homeDirectory}/.password-store";
      realGcloud = pkgs.google-cloud-sdk;
      gcloudConfigDir = "${config.home.homeDirectory}/.config/gcloud";
      adcPath = "${gcloudConfigDir}/application_default_credentials.json";
      mintBin = pkgs.writeShellApplication {
        name = "gcloud-mint-token";
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
          export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
          export OAUTH_SERVER_PY=${../../scripts/gcloud-oauth-server.py}
          exec bash ${../../scripts/gcloud-mint-token.sh} "$@"
        '';
      };
      bootstrapBin = pkgs.writeShellApplication {
        name = "pass-gcloud-bootstrap";
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
          export OAUTH_SERVER_PY=${../../scripts/gcloud-oauth-server.py}
          exec bash ${../../scripts/pass-gcloud-bootstrap.sh} "$@"
        '';
      };
      passPath = lib.makeBinPath [
        passPackage
        pkgs.gnupg
        pkgs.secretspec
        pkgs.coreutils
        pkgs.curl
        pkgs.git
        pkgs.python3
        mintBin
      ];
      # Rebuild ADC + account/project config from pass (no secrets printed).
      loginScript = pkgs.writeShellScript "gcloud-pass-login" ''
        set -euo pipefail
        export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
        export PATH="${passPath}:$PATH"

        _cfg=${lib.escapeShellArg gcloudConfigDir}
        _adc=${lib.escapeShellArg adcPath}
        mkdir -p "$_cfg"
        chmod 0700 "$_cfg"

        if pass show secretspec/shared/default/GCLOUD_REFRESH_TOKEN >/dev/null 2>&1; then
          umask 077
          ${mintBin}/bin/gcloud-mint-token --adc >"$_adc" 2>/dev/null || true
          chmod 0600 "$_adc" 2>/dev/null || true
          _account="$(${pkgs.secretspec}/bin/secretspec get -f ${secretspecToml} GCLOUD_ACCOUNT 2>/dev/null || true)"
          _project="$(${pkgs.secretspec}/bin/secretspec get -f ${secretspecToml} GCLOUD_PROJECT 2>/dev/null || true)"
          _refresh="$(pass show secretspec/shared/default/GCLOUD_REFRESH_TOKEN 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
          if [ -n "$_account" ] && [ "$_account" != "placeholder" ]; then
            ${realGcloud}/bin/gcloud config set account "$_account" >/dev/null 2>&1 || true
            if [ -n "$_refresh" ]; then
              # Populate credentials.db so `gcloud auth list` shows the account
              # (authorized_user ADC is not accepted by auth login --cred-file).
              printf '%s\n' "$_refresh" | ${realGcloud}/bin/gcloud auth activate-refresh-token "$_account" >/dev/null 2>&1 || true
            fi
          fi
          if [ -n "$_project" ] && [ "$_project" != "placeholder" ]; then
            ${realGcloud}/bin/gcloud config set project "$_project" >/dev/null 2>&1 || true
            ${realGcloud}/bin/gcloud auth application-default set-quota-project "$_project" >/dev/null 2>&1 || true
          fi
          echo "gcloud-auth: ADC + refresh-token activate from pass OAuth"
        elif pass show secretspec/shared/default/GCLOUD_SA_KEY >/dev/null 2>&1; then
          umask 077
          pass show secretspec/shared/default/GCLOUD_SA_KEY >"$_adc"
          chmod 0600 "$_adc"
          _email="$(${pkgs.python3}/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("client_email",""))' "$_adc" 2>/dev/null || true)"
          if [ -n "$_email" ]; then
            ${realGcloud}/bin/gcloud auth activate-service-account "$_email" --key-file="$_adc" --quiet >/dev/null 2>&1 || true
          else
            ${realGcloud}/bin/gcloud auth activate-service-account --key-file="$_adc" --quiet >/dev/null 2>&1 || true
          fi
          _project="$(${pkgs.secretspec}/bin/secretspec get -f ${secretspecToml} GCLOUD_PROJECT 2>/dev/null || true)"
          if [ -n "$_project" ] && [ "$_project" != "placeholder" ]; then
            ${realGcloud}/bin/gcloud config set project "$_project" >/dev/null 2>&1 || true
          fi
          echo "gcloud-auth: SA key from pass"
        else
          echo "gcloud-auth: no GCLOUD_REFRESH_TOKEN / GCLOUD_SA_KEY in pass; skip" >&2
          exit 0
        fi
      '';
      gcloud = pkgs.writeShellScriptBin "gcloud" ''
        if [ -z "''${CLOUDSDK_AUTH_ACCESS_TOKEN:-}" ]; then
          if [ -d ${lib.escapeShellArg storeDir} ]; then
            export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
            export PATH="${passPath}:$PATH"
            _token=""
            if pass show secretspec/shared/default/GCLOUD_REFRESH_TOKEN >/dev/null 2>&1; then
              _token="$(${mintBin}/bin/gcloud-mint-token 2>/dev/null || true)"
            fi
            if [ -n "$_token" ]; then
              CLOUDSDK_AUTH_ACCESS_TOKEN="$_token"
              export CLOUDSDK_AUTH_ACCESS_TOKEN
            elif pass show secretspec/shared/default/GCLOUD_SA_KEY >/dev/null 2>&1; then
              _tf="$(mktemp)"
              umask 077
              pass show secretspec/shared/default/GCLOUD_SA_KEY >"$_tf"
              chmod 0600 "$_tf"
              CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$_tf"
              export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE
              trap 'rm -f "$_tf"' EXIT
            fi
          fi
        fi
        # Prefer pass-backed ADC for client-library-compatible commands.
        if [ -z "''${GOOGLE_APPLICATION_CREDENTIALS:-}" ] && [ -r ${lib.escapeShellArg adcPath} ]; then
          GOOGLE_APPLICATION_CREDENTIALS=${lib.escapeShellArg adcPath}
          export GOOGLE_APPLICATION_CREDENTIALS
        fi
        exec ${realGcloud}/bin/gcloud "$@"
      '';
    in
    {
      options.dendritic.apps.gcloud = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install gcloud wrapper and pass-backed Google Cloud auth on activation.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          gcloud
          mintBin
          bootstrapBin
        ];

        home.sessionVariables = {
          CLOUDSDK_CONFIG = gcloudConfigDir;
        };

        home.activation.gcloudPassAuth = lib.mkIf passCfg.enable (
          lib.hm.dag.entryAfter [ "passBootstrap" ] ''
            ${loginScript} || true
          ''
        );
      };
    };
}

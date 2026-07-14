{
  # GitHub CLI auth via pass.
  #
  # Priority for the wrapped `gh` process only (never exported globally):
  #   1. env GH_TOKEN / GITHUB_TOKEN already set
  #   2. GitHub App mint (pass refresh_token → access token)  [fully automated]
  #   3. pass GH_TOKEN (legacy classic PAT)
  #   4. sops-nix gh_token
  #   5. gh hosts.yml / keychain
  #
  # One-time App setup: nix run .#pass-github-app-bootstrap
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      tokenPath = config.sops.secrets.gh_token.path;
      secretspecToml = ../../home/secretspec.toml;
      passPackage = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      realGh = pkgs.gh;
      storeDir = "${config.home.homeDirectory}/.password-store";
      mintBin = pkgs.writeShellApplication {
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
      };
      bootstrapBin = pkgs.writeShellApplication {
        name = "pass-github-app-bootstrap";
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
          export DOTFILES_ROOT=${lib.escapeShellArg (toString ../..)}
          export MANIFEST_PATH=${../../home/github-app-manifest.json}
          export SERVER_PY=${../../scripts/github-app-manifest-server.py}
          exec bash ${../../scripts/pass-github-app-bootstrap.sh} "$@"
        '';
      };
      gh = pkgs.writeShellScriptBin "gh" ''
        if [ -z "''${GH_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
          _token=""
          if [ -d ${lib.escapeShellArg storeDir} ]; then
            export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
            export PATH="${
              lib.makeBinPath [
                passPackage
                pkgs.gnupg
                pkgs.secretspec
                pkgs.coreutils
                pkgs.curl
                pkgs.git
                pkgs.python3
                mintBin
              ]
            }:$PATH"
            # 1) GitHub App automated mint (refresh_token in pass)
            if pass show secretspec/shared/default/GH_REFRESH_TOKEN >/dev/null 2>&1; then
              _token="$(${mintBin}/bin/github-app-mint-token 2>/dev/null || true)"
            fi
            # 2) Legacy classic PAT in pass
            if [ -z "$_token" ]; then
              _token="$(${pkgs.secretspec}/bin/secretspec get -f ${secretspecToml} GH_TOKEN 2>/dev/null || true)"
            fi
          fi
          if [ -z "$_token" ] && [ -r "${tokenPath}" ]; then
            _token="$(tr -d '[:space:]' < "${tokenPath}")"
          fi
          if [ -n "$_token" ] && [ "$_token" != "placeholder" ]; then
            GH_TOKEN="$_token"
            export GH_TOKEN
          fi
        fi
        exec ${realGh}/bin/gh "$@"
      '';
    in
    {
      sops.secrets.gh_token = { };
      home.packages = [
        gh
        mintBin
        bootstrapBin
      ];
    };
}

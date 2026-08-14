# Stripe CLI, Cursor plugin/skills, MCP (via _ide-mcp.nix), and pass/SecretSpec.
#
# Cursor discovers Stripe in three declarative places after `nh darwin switch`:
#   1. ~/.cursor/plugins/local/stripe  — official Stripe plugin (skills + MCP + rules)
#   2. ~/.cursor/skills/stripe-*       — same skills for agent discovery
#   3. ~/.cursor/mcp.json              — https://mcp.stripe.com (OAuth in Cursor)
#
# Secret key never lands in $HOME files: pass path
#   secretspec/shared/default/STRIPE_SECRET_KEY
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.cursor;
      passPackage = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      storeDir = "${config.home.homeDirectory}/.password-store";
      secretspecToml = ../../home/secretspec.toml;
      stripePlugin = ../../.cursor/plugins/stripe;
      stripeRule = ../../.cursor/rules/stripe.mdc;
      skillEntries = builtins.readDir "${stripePlugin}/skills";
      skillDirs = lib.filterAttrs (_n: t: t == "directory") skillEntries;
      skillHomeFiles = lib.mapAttrs' (name: _: {
        name = ".cursor/skills/${name}";
        value = {
          source = "${stripePlugin}/skills/${name}";
          recursive = true;
        };
      }) skillDirs;
      bootstrap = pkgs.writeShellApplication {
        name = "pass-stripe-bootstrap";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnupg
          passPackage
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
          exec ${pkgs.bash}/bin/bash ${../../scripts/pass-stripe-bootstrap.sh} "$@"
        '';
      };
      stripeEnv = pkgs.writeShellApplication {
        name = "stripe-with-pass";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnupg
          pkgs.secretspec
          passPackage
          pkgs.stripe-cli
        ];
        text = ''
          set -euo pipefail
          export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
          if [ -z "''${STRIPE_SECRET_KEY:-}" ]; then
            if command -v secretspec >/dev/null 2>&1; then
              STRIPE_SECRET_KEY="$(secretspec get -f ${lib.escapeShellArg secretspecToml} STRIPE_SECRET_KEY 2>/dev/null || true)"
            fi
          fi
          if [ -z "''${STRIPE_SECRET_KEY:-}" ]; then
            STRIPE_SECRET_KEY="$(pass show secretspec/shared/default/STRIPE_SECRET_KEY 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
          fi
          if [ -z "''${STRIPE_SECRET_KEY:-}" ]; then
            echo "stripe-with-pass: missing STRIPE_SECRET_KEY — run pass-stripe-bootstrap" >&2
            exit 1
          fi
          export STRIPE_SECRET_KEY
          export STRIPE_API_KEY="$STRIPE_SECRET_KEY"
          exec stripe "$@"
        '';
      };
    in
    {
      config = lib.mkIf cfg.enable {
        home.packages = [
          pkgs.stripe-cli
          bootstrap
          stripeEnv
        ];

        home.file = skillHomeFiles // {
          # Official Stripe Cursor plugin (skills + rules). MCP lives only in
          # ~/.cursor/mcp.json from _ide-mcp.nix so we do not double-register
          # https://mcp.stripe.com.
          ".cursor/plugins/local/stripe" = {
            source = pkgs.runCommand "cursor-plugin-stripe" { } ''
              mkdir -p "$out"
              cp -R ${stripePlugin}/. "$out/"
              rm -f "$out/mcp.json"
            '';
            recursive = true;
          };
          ".cursor/rules/stripe.mdc".source = stripeRule;
        };
      };
    };
}

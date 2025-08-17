# Packages Module
{ inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      packages = {
        # Custom packages can be defined here
        default = pkgs.writeShellScriptBin "dotfiles-info" ''
          echo "Alex's Universal Dotfiles"
          echo "========================="
          echo "Systems supported:"
          echo "  - macOS (aarch64-darwin): NIXY"
          echo "  - NixOS x86_64: NIXSTATION64"
          echo "  - NixOS aarch64: NIXY2"
          echo "  - Mobile NixOS: NIXEDUP (OnePlus 6T)"
          echo ""
          echo "Available configurations:"
          nix flake show
        '';

        # Nixible CLI for 8AMPS iPhone configuration
        "8AMPS" =
          let
            nixible_lib = inputs.nixible.lib {
              inherit pkgs;
              lib = pkgs.lib;
            };
          in
          nixible_lib.mkNixibleCli ../playbooks/remote-device-setup.nix;

        # Dialog-based secrets manager for sops-nix
        secrets-manager = pkgs.callPackage ../packages/secrets-manager.nix { };

        # Mobile NixOS installer helper
        mobile-installer = pkgs.writeShellScriptBin "mobile-installer" ''
          set -e
          echo "Mobile NixOS Installer for OnePlus 6T"
          echo "====================================="
          echo ""
          echo "Prerequisites:"
          echo "1. Device in fastboot mode"
          echo "2. Bootloader unlocked"
          echo "3. USB debugging enabled"
          echo ""
          echo "Building Mobile NixOS image..."
          nix build .#nixosConfigurations.NIXEDUP.config.system.build.android-bootimg
          echo ""
          echo "Flash with: fastboot flash boot result/boot.img"
          echo "Then: fastboot reboot"
        '';

        # Update README with code statistics using tokei
        update-readme = pkgs.writeShellScriptBin "update-readme" ''
          set -e
          echo "📊 Updating README.md with code statistics..."

          # Ensure we're in the dotfiles directory
          if [[ ! -f "flake.nix" ]]; then
            echo "❌ Error: Must be run from the dotfiles root directory"
            exit 1
          fi

          DATE=$(date)
          TOKEI_JSON=$(${pkgs.tokei}/bin/tokei . --output json | ${pkgs.jq}/bin/jq '{ CSS, JSON, Lua, Markdown, Nix, Python, Shell, "Plain Text", TOML, "Vim script", YAML }')

          # Start building the new format
          TABLE="<!-- BEGIN CODE STATS -->\n"
          TABLE+="## How much code?\n"
          TABLE+="\n"
          TABLE+="👨‍💻 Code Statistics:\n\n"

          TOTAL_FILES=0
          TOTAL_CODE=0
          TOTAL_COMMENTS=0
          TOTAL_BLANKS=0

          # Build detailed table content for the expandable section
          DETAIL_TABLE="| Language   | Files | Lines | Code  | Comments | Blanks |\n"
          DETAIL_TABLE+="|------------|-------|-------|-------|----------|--------|\n"

          while IFS=$'\t' read -r LANG FILES CODE COMMENTS BLANKS; do
            LINES=$((CODE + COMMENTS + BLANKS))
            DETAIL_TABLE+="| $LANG | $FILES | $LINES | $CODE | $COMMENTS | $BLANKS |\n"
            TOTAL_FILES=$((TOTAL_FILES + FILES))
            TOTAL_CODE=$((TOTAL_CODE + CODE))
            TOTAL_COMMENTS=$((TOTAL_COMMENTS + COMMENTS))
            TOTAL_BLANKS=$((TOTAL_BLANKS + BLANKS))
          done < <(echo "$TOKEI_JSON" | ${pkgs.jq}/bin/jq -r '
            to_entries[]
            | select(.key | IN("CSS", "JSON", "Lua", "Markdown", "Nix", "Python", "Shell", "Plain Text", "TOML", "Vim script", "YAML"))
            | [.key, (.value.reports | length), .value.code, .value.comments, .value.blanks]
            | @tsv')

          TOTAL_LINES=$((TOTAL_CODE + TOTAL_COMMENTS + TOTAL_BLANKS))
          DETAIL_TABLE+="| **Total**  | $TOTAL_FILES | $TOTAL_LINES | $TOTAL_CODE | $TOTAL_COMMENTS | $TOTAL_BLANKS |\n"

          # Add the preview format with total LOC at top and expandable section
          TABLE+="_Total LOC (including blanks, comments): **$TOTAL_LINES**_\n\n"
          TABLE+="<details>\n"
          TABLE+="<summary>🔍 Click to expand code stats.</summary>\n\n"
          TABLE+="$DETAIL_TABLE\n"
          TABLE+="</details>\n\n"
          TABLE+="Last updated: $DATE\n"
          TABLE+="<!-- END CODE STATS -->"

          TMPFILE=$(mktemp)
          echo -e "$TABLE" > "$TMPFILE"

          # Update README.md with new statistics
          ${pkgs.perl}/bin/perl -0777 -i -pe "
            my \$table = do { local \$/; open my \$fh, '<', '$TMPFILE' or die \$!; <\$fh> };
            \$table =~ s/\n+\z//;  # Remove trailing newlines
            s|<!-- BEGIN CODE STATS -->.*?<!-- END CODE STATS -->|\$table|s;
          " README.md

          rm "$TMPFILE"

          echo "✅ README.md updated with latest code statistics"
          echo "📈 Total lines of code: $TOTAL_LINES"

          # Format the updated file
          echo "🎨 Formatting README.md..."
          ${pkgs.treefmt}/bin/treefmt README.md || echo "⚠️  treefmt not available, skipping formatting"

          echo "🎉 Code statistics update complete!"
        '';
      };
    };
}

{ pkgs, allApps, masPackage, lib }:

pkgs.writeShellScriptBin "mas-sync" ''
  set -euo pipefail
  export PATH="${lib.makeBinPath [ masPackage pkgs.coreutils pkgs.gnugrep ]}:$PATH"
  export MAS_NO_AUTO_INDEX=1

  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  Mac App Store — Declarative Sync via mas"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo "  ℹ  You must be signed into the Mac App Store GUI."
  echo "     (mas signin is disabled on modern macOS)"
  echo ""

  INSTALLED=$(mas list 2>/dev/null || true)

  echo "  ⤓ Checking for Mac App Store updates..."
  mas upgrade || echo "  ⚠️  Some updates could not be applied automatically."

  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: id: ''
    if echo "$INSTALLED" | grep -q "^${toString id} "; then
      echo "  ✓ ${name} (${toString id}) — already installed"
    else
      echo "  ⤓ Installing ${name} (${toString id})..."
      if mas purchase ${toString id}; then
        echo "  ✓ ${name} — installed successfully"
      elif mas install ${toString id}; then
        echo "  ✓ ${name} — re-installed successfully"
      else
        echo "  ✗ ${name} — install failed (check App Store sign-in)" >&2
      fi
    fi
  '') allApps)}

  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  Mac App Store sync complete."
  echo "══════════════════════════════════════════════════════════"
''

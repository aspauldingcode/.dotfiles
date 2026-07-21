# Silicon Motion macOS InstantView — upstream nixpkgs only.
#
# Package: `pkgs.macos-instantview` (overlaid from nixpkgs-unstable →
# 3.24R0004 / nixpkgs#530053). 26.05 still carries 3.22R0002.
#
# GC note: with `targets.darwin.linkApps`, Launch Services writes
# `com.apple.macl` onto the store `.app`. That xattr makes
# `nix store gc`'s pre-delete `fchmodat` fail with EPERM
# (NixOS/nix#6765). Darwin activation strips it (see below);
# overlay also clears quarantine/macl at build time.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = lib.mkIf pkgs.stdenv.isDarwin {
        home.packages = [ pkgs.macos-instantview ];

        # User-context belt-and-suspenders after linkApps; store writes
        # may need the root darwin activation below.
        home.activation.stripInstantViewMacl = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          app="${pkgs.macos-instantview}/Applications/macOS InstantView.app"
          if [ -d "$app" ]; then
            /usr/bin/xattr -d com.apple.macl "$app" 2>/dev/null || true
          fi
        '';
      };
    };

  flake.modules.darwin.dendritic =
    {
      lib,
      ...
    }:
    {
      # Root activation: strip macl from every store-linked .app so GC
      # can chmod/delete them. InstantView is the canary; Beeper/etc.
      # hit the same Launch Services path via linkApps.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "  🧹 Stripping com.apple.macl from nix-store .app bundles (GC hygiene)..." >&2
        for app in /nix/store/*/Applications/*.app; do
          [ -d "$app" ] || continue
          /usr/bin/xattr -d com.apple.macl "$app" 2>/dev/null || true
        done
      '';
    };
}

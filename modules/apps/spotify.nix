{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      inputs,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.spotify;
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      tintedInject = pkgs.callPackage ./tinted-inject { };
      isSupported = !(pkgs.stdenv.isLinux && pkgs.stdenv.isAarch64);
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];

      options.dendritic.apps.spotify = {
        enable = lib.mkEnableOption "Spotify via Spicetify + dendritic tint" // {
          default = true;
        };
      };

      config = lib.mkMerge [
        # Native Spotify colors; LUT rewriter tints them (TintedBrowse).
        { stylix.targets.spicetify.enable = lib.mkForce false; }
        (lib.mkIf (cfg.enable && isSupported) {
          programs.spicetify = {
            enable = true;
            spotifyPackage = pkgs.spotify;

            enabledExtensions =
              (with spicePkgs.extensions; [
                adblock
                adblockify
                hidePodcasts
                shuffle
              ])
              ++ [
                {
                  src = tintedInject;
                  name = "dendritic-tint.js";
                }
              ];

            enabledCustomApps = with spicePkgs.apps; [
              lyricsPlus
              marketplace
            ];
          };
        })
        (lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
          home.activation.disableSpotifyUpdates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            SPOTIFY_UPDATE_DIR=~/Library/Application\ Support/Spotify/PersistentCache/Update
            if ! /usr/bin/stat -f "%Sf" "$SPOTIFY_UPDATE_DIR" 2> /dev/null | grep -q uchg; then
              rm -rf "$SPOTIFY_UPDATE_DIR"
              mkdir -p "$SPOTIFY_UPDATE_DIR"
              /usr/bin/chflags uchg "$SPOTIFY_UPDATE_DIR"
            fi
          '';

          # Writable clone so appearance can drop tinted-palette.json into xpui.
          # ditto-v1: never `cp -R` onto an existing .app (nests Spotify.app
          # inside itself; Dock launches the outer husk → "damaged or incomplete").
          home.activation.dendriticSpotifyClone = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            src="$HOME/Applications/Home Manager Apps/Spotify.app"
            dest="$HOME/.local/state/dendritic/Spotify.app"
            staging="$HOME/.local/state/dendritic/Spotify.app.staging"
            marker="$HOME/.local/state/dendritic/spotify-src"
            _spotify_bundle_ok() {
              [ -f "$1/Contents/MacOS/Spotify" ] && [ ! -e "$1/Spotify.app" ]
            }
            if [ ! -e "$src" ]; then
              echo "dendritic-appearance: no Spotify.app yet, skip clone"
              exit 0
            fi
            $DRY_RUN_CMD mkdir -p "$HOME/.local/state/dendritic"
            src_real="$(${pkgs.coreutils}/bin/readlink -f "$src")"
            want="$(${pkgs.coreutils}/bin/printf '%s\nditto-v1\n' "$src_real")"
            if [ "$(cat "$marker" 2>/dev/null || true)" != "$want" ] || ! _spotify_bundle_ok "$dest"; then
              $DRY_RUN_CMD /usr/bin/chflags -R nouchg,noschg "$dest" "$staging" 2>/dev/null || true
              $DRY_RUN_CMD /bin/chmod -R u+w "$dest" "$staging" 2>/dev/null || true
              $DRY_RUN_CMD rm -rf "$staging"
              $DRY_RUN_CMD /usr/bin/ditto "$src_real" "$staging"
              if [ -n "$DRY_RUN_CMD" ] || [ -f "$staging/Contents/MacOS/Spotify" ]; then
                $DRY_RUN_CMD /bin/chmod -R u+w "$staging"
                $DRY_RUN_CMD /usr/bin/xattr -cr "$staging" 2>/dev/null || true
                $DRY_RUN_CMD /usr/bin/codesign --force --sign - "$staging" 2>/dev/null || true
                $DRY_RUN_CMD rm -rf "$dest"
                $DRY_RUN_CMD /bin/mv "$staging" "$dest"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '%s\nditto-v1\n' "$src_real" > "$marker"
              else
                echo "dendritic-appearance: Spotify ditto incomplete, leaving previous dest" >&2
                $DRY_RUN_CMD rm -rf "$staging"
              fi
            fi
          '';
        })
      ];
    };

  flake.modules.darwin.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      enabled = config.home-manager.users.${user}.dendritic.apps.spotify.enable or false;
    in
    lib.mkIf enabled {
      dendritic.dock.apps = lib.mkOrder 120 [
        "/Users/${user}/.local/state/dendritic/Spotify.app"
      ];
    };
}

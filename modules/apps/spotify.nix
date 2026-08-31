{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      inputs,
      ...
    }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      tintedInject = pkgs.callPackage ./tinted-inject { };
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];

      config =
        let
          isSupported = !(pkgs.stdenv.isLinux && pkgs.stdenv.isAarch64);
        in
        lib.mkMerge [
          # Native Spotify colors; LUT rewriter tints them (TintedBrowse).
          { stylix.targets.spicetify.enable = lib.mkForce false; }
          (lib.mkIf isSupported {
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
          (lib.mkIf pkgs.stdenv.isDarwin {
            home.activation.disableSpotifyUpdates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              SPOTIFY_UPDATE_DIR=~/Library/Application\ Support/Spotify/PersistentCache/Update
              if ! /usr/bin/stat -f "%Sf" "$SPOTIFY_UPDATE_DIR" 2> /dev/null | grep -q uchg; then
                rm -rf "$SPOTIFY_UPDATE_DIR"
                mkdir -p "$SPOTIFY_UPDATE_DIR"
                /usr/bin/chflags uchg "$SPOTIFY_UPDATE_DIR"
              fi
            '';

            # Clone so appearance can drop tinted-palette.json into xpui.
            # lut-v1 marker forces a re-clone off the old Stylix colors.css.
            home.activation.dendriticSpotifyClone = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
              src="$HOME/Applications/Home Manager Apps/Spotify.app"
              dest="$HOME/.local/state/dendritic/Spotify.app"
              marker="$HOME/.local/state/dendritic/spotify-src"
              if [ ! -e "$src" ]; then
                echo "dendritic-appearance: no Spotify.app yet, skip clone"
                exit 0
              fi
              $DRY_RUN_CMD mkdir -p "$HOME/.local/state/dendritic"
              src_real="$(${pkgs.coreutils}/bin/readlink -f "$src")"
              want="$(${pkgs.coreutils}/bin/printf '%s\nlut-v1\n' "$src_real")"
              if [ "$(cat "$marker" 2>/dev/null || true)" != "$want" ]; then
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+w "$dest" 2>/dev/null || true
                $DRY_RUN_CMD rm -rf "$dest"
                $DRY_RUN_CMD /bin/cp -cR "$src_real" "$dest"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+w "$dest"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '%s\nlut-v1\n' "$src_real" > "$marker"
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
    in
    {
      dendritic.dock.apps = lib.mkOrder 120 [
        "/Users/${user}/.local/state/dendritic/Spotify.app"
      ];
    };
}

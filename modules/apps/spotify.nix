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
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];

      config =
        let
          # Spotify is not available for aarch64-linux
          isSupported = !(pkgs.stdenv.isLinux && pkgs.stdenv.isAarch64);
        in
        lib.mkMerge [
          { stylix.targets.spicetify.enable = isSupported; }
          (lib.mkIf isSupported {
            programs.spicetify = {
              enable = true;
              spotifyPackage = pkgs.spotify;
              # colorScheme and theme are managed by Stylix; set defaults only
              # colorScheme = "Everforest";  # Stylix will override this
              # theme = spicePkgs.themes.comfy;  # Stylix will override this

              enabledExtensions = with spicePkgs.extensions; [
                adblock
                adblockify
                hidePodcasts
                shuffle
              ];

              enabledCustomApps = with spicePkgs.apps; [
                lyricsPlus
                marketplace
              ];
            };
          })
          (lib.mkIf pkgs.stdenv.isDarwin {
            # MacOS Spotify auto-update prevention fix
            home.activation.disableSpotifyUpdates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              SPOTIFY_UPDATE_DIR=~/Library/Application\ Support/Spotify/PersistentCache/Update
              if ! /usr/bin/stat -f "%Sf" "$SPOTIFY_UPDATE_DIR" 2> /dev/null | grep -q uchg; then
                rm -rf "$SPOTIFY_UPDATE_DIR"
                mkdir -p "$SPOTIFY_UPDATE_DIR"
                /usr/bin/chflags uchg "$SPOTIFY_UPDATE_DIR"
              fi
            '';
          })
        ];
    };

  # Dock registration: Spotify owns its dock entry (order 120 in `dock.nix`).
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
        "${config.home-manager.users.${user}.programs.spicetify.spicedSpotify}/Applications/Spotify.app"
      ];
    };
}

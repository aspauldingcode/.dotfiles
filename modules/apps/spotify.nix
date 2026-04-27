{
  flake.modules.homeManager.spotify = { pkgs, lib, inputs, ... }: let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    # Spotify is not available for aarch64-linux
    isSupported = !(pkgs.stdenv.isLinux && pkgs.stdenv.isAarch64);
  in {
    imports = lib.optional isSupported inputs.spicetify-nix.homeManagerModules.default;

    stylix.targets.spicetify.enable = isSupported;

    programs.spicetify = lib.mkIf isSupported {
      enable = true;
      spotifyPackage = pkgs.spotify;
      colorScheme = lib.mkForce "catppuccin-macchiato";

      # Using the built-in comfy theme
      theme = lib.mkForce spicePkgs.themes.comfy;

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

    # MacOS Spotify auto-update prevention fix
    home.activation.disableSpotifyUpdates = lib.mkIf pkgs.stdenv.isDarwin
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        SPOTIFY_UPDATE_DIR=~/Library/Application\ Support/Spotify/PersistentCache/Update
        if ! /usr/bin/stat -f "%Sf" "$SPOTIFY_UPDATE_DIR" 2> /dev/null | grep -q uchg; then
          rm -rf "$SPOTIFY_UPDATE_DIR"
          mkdir -p "$SPOTIFY_UPDATE_DIR"
          /usr/bin/chflags uchg "$SPOTIFY_UPDATE_DIR"
        fi
      '');
  };
}

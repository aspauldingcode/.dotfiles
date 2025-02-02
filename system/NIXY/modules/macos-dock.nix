{ config, pkgs, ... }:

{
  system.defaults.dock.persistent-apps = [
    "/System/Applications/Launchpad.app"
    "${pkgs.spotify}/Applications/Spotify.app"
    "${pkgs.obsidian}/Applications/Obsidian.app"
    "${pkgs.firefox-bin}/Applications/Firefox.app"
    "${pkgs.brave}/Applications/Brave Browser.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Facetime.app"
    # "${pkgs.cursor}/Applications/Cursor.app" #FIXME: nixpkgs not merged yet:
    "${pkgs.alacritty}/Applications/Alacritty.app"
  ];
}

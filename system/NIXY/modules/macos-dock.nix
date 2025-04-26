{ config, pkgs, ... }:

{
  system.defaults.dock.persistent-apps = [
    "/System/Applications/Launchpad.app"
    # "/Applications/Nix\ Apps/Spotify.app"
    "${config.programs.spicetify.spicedSpotify}/Applications/Spotify.app"
    "${pkgs.obsidian}/Applications/Obsidian.app"
    "${pkgs.librewolf}/Applications/Librewolf.app"
    "${pkgs.brave}/Applications/Brave Browser.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Facetime.app"
    "/Applications/Windows App.app"
    "${pkgs.alacritty}/Applications/Alacritty.app"
  ];
}

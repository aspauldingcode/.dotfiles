{ config, lib, pkgs, ... }:

{
  programs.unmenu = {
    enable = true;
    settings = {
    hotkey.qwerty_hotkey = "alt-d";
      find_apps = true;
      find_executables = true;
    #   dirs = [
    #     "/Applications/"
    #     "/System/Applications/"
    #     "/System/Applications/Utilities/"
    #     "/System/Library/CoreServices/"
    #   ];
    };
  };
}

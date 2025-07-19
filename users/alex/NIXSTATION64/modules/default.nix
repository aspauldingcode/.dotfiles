{ pkgs, ... }:
{
  imports = [
    ./fuzzel
    ./mimeapps
    ./niri
    ./packages
    ./sway
    ./theme
    ./waybar
  ];
}

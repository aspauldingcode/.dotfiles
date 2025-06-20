{
  pkgs,
  ...
}:

{
  imports = [
    ./bemenu
    ./mako
    ./mimeapps
    ./packages
    ./sway
    ./swayr
    ./theme
    ./waybar
  ];
}

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
    ./theme
    ./waybar
  ];
}

{
  pkgs,
  ...
}:

{
  imports = [
    ./airplay
    ./cursor
    ./eduroam
    ./greetd
    ./kanata
    ./packages
    ./sddm-themes
    ./sway-configuration
    ./theme
    ./virtual-machines
    ./way-displays
    ./wg-quick
  ];
}

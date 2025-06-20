{
  pkgs,
  ...
}:

{
  imports = [
    ./airplay
    ./eduroam
    ./greetd
    ./kanata
    ./packages
    ./sway-configuration
    ./theme
    ./virtual-machines
    ./way-displays
    ./wg-quick
  ];
}

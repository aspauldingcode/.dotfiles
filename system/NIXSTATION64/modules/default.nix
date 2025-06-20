{
  pkgs,
  ...
}:

{
  imports = [
    ./packages
    ./sddm-themes
    ./sway-configuration
    ./theme
    ./virtual-machines
    ./way-displays
    ./wg-quick
    ./greetd
  ];
}

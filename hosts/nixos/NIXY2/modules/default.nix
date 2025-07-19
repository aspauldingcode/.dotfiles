{ pkgs, ... }:
{
  imports = [
    ./airplay
    ./eduroam
    # ./greetd  # Commented out - greetd configuration moved back to main config
    ./kanata
    ./packages
    ./sway-configuration
    ./theme
    ./virtual-machines
    ./way-displays
    # ./wg-quick  # Commented out due to missing private key files
  ];
}

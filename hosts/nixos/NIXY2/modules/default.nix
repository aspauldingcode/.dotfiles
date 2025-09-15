{pkgs, ...}: {
  imports = [
    ./airplay
    ./eduroam
    ./kanata
    ./packages
    ./theme
    # Removed: greetd, sway-configuration, virtual-machines, way-displays
    # ./wg-quick  # Commented out due to missing private key files
  ];
}

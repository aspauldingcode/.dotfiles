{pkgs, ...}: {
  imports = [
    ./fuzzel
    ./mimeapps
    ./niri
    ./packages
    ./theme
    # Removed: sway, waybar
  ];
}

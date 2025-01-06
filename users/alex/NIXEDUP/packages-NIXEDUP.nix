{
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../packages-UNIVERSAL.nix
  ];
  home = {
    pointerCursor = {
      # change theme for NIXEDUP!
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 22;
    };
    packages = with pkgs; [
      #xvkb? swipe-xvkv?
      #sway/sxmo? STARDUSTXR?????????????????????
      xorg.xf86videosiliconmotion # usb hub for phone
    ];
  };
}

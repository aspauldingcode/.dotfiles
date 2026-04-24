{
  flake.modules.nixos.linux-desktop = { pkgs, ... }: {
    services.displayManager.ly.enable = true;

    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      extraPackages = with pkgs; [
        swaylock
        swayidle
        wl-clipboard
        mako # notification daemon
        alacritty # default terminal
        dmenu # application launcher
      ];
    };
  };
}

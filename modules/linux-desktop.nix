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

  flake.modules.homeManager.linux-desktop = { pkgs, lib, ... }: {
    options.dendritic.apps.linux-desktop = {
      enable = lib.mkEnableOption "Linux Desktop (Sway)";
    };
    config = {
      # Home Manager specific linux desktop config (empty for now)
    };
  };
}

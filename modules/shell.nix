{
  flake.modules.nixos.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
    environment.systemPackages = [ pkgs.nh pkgs.yazi ];
  };

  flake.modules.darwin.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
    environment.systemPackages = [ pkgs.nh pkgs.yazi ];
  };

  flake.modules.homeManager.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
    
    # Yazi minimal configuration
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    home.packages = with pkgs; [ 
      nh 
    ];
  };
}

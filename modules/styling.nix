{
  flake.modules.nixos.styling = { pkgs, inputs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    environment.systemPackages = [ pkgs.gowall ];

    stylix = {
      enable = true;
      image = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png";
        sha256 = "18yjk22h01x40a7a40rns88v1ssyly095hw8jnd7am3b145d5z3a";
      };
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
      targets.gnome.enable = false;
    };

    specialisation = {
      light.configuration = {
        stylix.base16Scheme = inputs.nixpkgs.lib.mkForce "${pkgs.base16-schemes}/share/themes/gruvbox-light-medium.yaml";
      };
    };
  };

  flake.modules.darwin.styling = { pkgs, inputs, ... }: {
    imports = [ inputs.stylix.darwinModules.stylix ];

    environment.systemPackages = [ pkgs.gowall ];

    stylix = {
      enable = true;
      image = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png";
        sha256 = "18yjk22h01x40a7a40rns88v1ssyly095hw8jnd7am3b145d5z3a";
      };
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    };
  };

  flake.modules.homeManager.styling = { pkgs, inputs, lib, ... }: {
    home.packages = [ pkgs.gowall ];
    stylix.targets.xresources.enable = lib.mkForce false;
    xresources.properties = lib.mkForce {};
    xresources.extraConfig = lib.mkForce "";
  };
}

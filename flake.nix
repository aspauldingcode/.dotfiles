{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url =       "github:nixos/nixpkgs/nixos-unstable";
    darwin.url =        "github:lnl7/nix-darwin";
    nix-darwin.url =    "github:LnL7/nix-darwin";
    home-manager.url =  "github:nix-community/home-manager";
    nixvim.url =        "github:nix-community/nixvim";
    nix-colors.url =    "github:misterio77/nix-colors"; 
  };

  outputs = { self, nixpkgs, darwin, nix-darwin, home-manager, nixvim, flake-parts, nix-colors }: 
  let inherit (self) inputs;
    # Define common specialArgs for nixosConfigurations and homeConfigurations
    commonSpecialArgs = { inherit inputs nixvim flake-parts nix-colors self; };
    darwinSpecialArgs = { inherit nix-darwin self; };
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    # Define NixOS configurations
    nixosConfigurations = {
      NIXSTATION64 = nixpkgs.lib.nixosSystem {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        specialArgs = commonSpecialArgs;
        modules = [ ./system/NIXSTATION64/configuration.nix ];
      };
      NIXEDUP = nixpkgs.lib.nixosSystem {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        specialArgs = commonSpecialArgs;
        modules = [ ./system/NIXEDUP/configuration.nix ];
      };
    };

    # Define Darwin (macOS) configurations
    darwinConfigurations = {
      NIXY = darwin.lib.darwinSystem {
        specialArgs = [ commonSpecialArgs darwinSpecialArgs ];
        modules = [ ./system/NIXY/darwin-configuration.nix ];
      };
    };

    # Define home-manager configurations for Users
    homeConfigurations = {

      # User: "Alex"
      "alex@NIXY" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = [ commonSpecialArgs darwinSpecialArgs ];
        modules = [ ./users/alex/NIXY/home-NIXY.nix ];
      };

      "alex@NIXEDUP" = home-manager.lib.homeManagerConfiguration { 
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        extraSpecialArgs = commonSpecialArgs;
        modules = [ ./users/alex/NIXEDUP/home-NIXEDUP.nix];
      };

      "alex@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = commonSpecialArgs;
        modules = [ ./users/alex/NIXSTATION64/home-NIXSTATION64.nix ];
      };

    # User: "Su Su"
    "susu@NIXY" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = [ commonSpecialArgs darwinSpecialArgs ];
      modules = [ ./users/susu/home-NIXY.nix ];
    };

    "susu@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = commonSpecialArgs;
      modules = [ ./users/susu/home-NIXSTATION64.nix ];
    };
  };
  in {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      homeConfigurations = homeConfigurations;
      darwinConfigurations = darwinConfigurations;
      apps = eachSystem (pkgs: {
      default = let
        setup = pkgs.writeScriptBin "setup" /* bash */ '' 
        #!/bin/bash

        # CLONE THE REPO TO ~/.dotfiles!
        ${pkgs.git}/bin/git clone git@github.com:aspauldingcode/.dotfiles $HOME/.dotfiles
        # run the rebuild!
        rebuild -r -f #FIXME: allow -r -f on NIXSTATION64

        '';
      in {
        type = "app";
        program = "${setup}/bin/setup";
      };
    });
  };
}

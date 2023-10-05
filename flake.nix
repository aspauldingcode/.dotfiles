{
  description = "Universal Flake by Alex - macOS and NixOS";

  # Universal inputs for NixOS and Darwin
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, home-manager, darwin }: 
    let
      inherit (self) inputs;

      # Define common specialArgs for nixosConfigurations and homeConfigurations
      commonSpecialArgs = { inherit inputs self; };

      # Define NixOS configurations
      nixosConfigurations = {
        NIXSTATION64 = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXSTATION64/configuration.nix ];
        };
        NIXEDUP = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXEDUP/configuration.nix ];
        };
      };

      # Define home-manager configurations for NIXY (aarch64-darwin)
      homeConfigurations = {
        "alex@NIXY" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs;
          extraSpecialArgs = commonSpecialArgs;
          modules = [ ./users/alex/home.nix ];
        };
        "susu@NIXY" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs;
          extraSpecialArgs = commonSpecialArgs;
          modules = [ ./users/susu/home.nix ];
        };
      };

      # Define Darwin (macOS) configurations
      darwinConfigurations = {
        NIXY = darwin.lib.darwinSystem {
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXY/darwin-configuration.nix ];
        };
      };
    in {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      homeConfigurations = homeConfigurations;
      darwinConfigurations = darwinConfigurations;
    };
}


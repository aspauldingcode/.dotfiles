{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, darwin, home-manager }: 
    let
      inherit (self) inputs;

      # Define common specialArgs for nixosConfigurations and homeConfigurations
      commonSpecialArgs = { inherit inputs self; };

      # Define NixOS configurations
      nixosConfigurations = {
        NIXSTATION64 = nixpkgs.legacyPackages.x86_64-linux.lib.nixosSystem {
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXSTATION64/configuration.nix ];
        };
        NIXEDUP = nixpkgs.legacyPackages.aarch64-linux.lib.nixosSystem {
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXEDUP/configuration.nix ];
        };
      };

      # Define Darwin (macOS) configurations
      darwinConfigurations = {
        NIXY = darwin.lib.darwinSystem {
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXY/darwin-configuration.nix ];
        };
      };

      # Define home-manager configurations for Users
      homeConfigurations = {

      	# User: Alex
        "alex@NIXY" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = commonSpecialArgs;
          modules = [ ./users/alex/home-NIXY.nix ];
        };
	
	"alex@NIXEDUP" = home-manager.lib.homeManagerConfiguration { 
	  pkgs = nixpkgs.legacyPackages.aarch64-linux;
	  extraSpecialArgs = commonSpecialArgs;
	  modules = [ ./users/alex/home-NIXEDUP.nix];
	};
 
        "alex@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
	  pkgs = nixpkgs.legacyPackages.x86_64-linux;
	  extraSpecialArgs = commonSpecialArgs;
	  modules = [ ./users/alex/home-NIXSTATION64 ];
	};

	# User: Su Su
	"susu@NIXY" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = commonSpecialArgs;
          modules = [ ./users/susu/home-NIXY.nix ];
        };
	"susu@NIXEDUP" = home-manager.lib.homeManagerConfiguration { 
	  pkgs = nixpkgs.legacyPackages.aarch64-linux;
	  extraSpecialArgs = commonSpecialArgs;
	  modules = [ ./users/susu/home-NIXEDUP.nix];
	};
 
        "susu@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
	  pkgs = nixpkgs.legacyPackages.x86_64-linux;
	  extraSpecialArgs = commonSpecialArgs;
	  modules = [ ./users/susu/home-NIXSTATION64 ];
	};
      };
    in {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      homeConfigurations = homeConfigurations;
      darwinConfigurations = darwinConfigurations;
    };
}


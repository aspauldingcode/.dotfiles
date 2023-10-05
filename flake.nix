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
	inherit (nixpkgs) legacyPackages;

# Define common specialArgs for nixosConfigurations and homeConfigurations
	commonSpecialArgs = { inherit inputs self; };

	in 
	{
# NIXOS - NIXSTATION64 (x86_64-linux)
		nixosConfigurations = {
			NIXSTATION64 = nixpkgs.lib.nixosSystem {
				specialArgs = commonSpecialArgs;
				modules = [ ./system/NIXSTATION64/configuration.nix ];
			};
		};

# Standalone home-manager configuration entrypoint for NIXSTATION64
		homeConfigurations = {
			"alex@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
				pkgs = legacyPackages.x86_64-linux;
				extraSpecialArgs = commonSpecialArgs;
				modules = [ ./users/alex/home.nix ];
			};
			"susu@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
				pkgs = legacyPackages.x86_64-linux;
				extraSpecialArgs = commonSpecialArgs;
				modules = [ ./users/susu/home.nix ];
			};
		};

# NIXOS - NIXEDUP (aarch64-linux)
		nixosConfigurations = {
			NIXEDUP = nixpkgs.lib.nixosSystem {
				specialArgs = commonSpecialArgs;
				modules = [ ./system/NIXEDUP/configuration.nix ];
			};
		};

# Standalone home-manager configuration entrypoint for NIXEDUP
		homeConfigurations = {
			"alex@NIXEDUP" = home-manager.lib.homeManagerConfiguration {
				pkgs = legacyPackages.aarch64-linux;
				extraSpecialArgs = commonSpecialArgs;
				modules = [ ./users/alex/home.nix ];
			};
			"susu@NIXEDUP" = home-manager.lib.homeManagerConfiguration {
				pkgs = legacyPackages.aarch64-linux;
				extraSpecialArgs = commonSpecialArgs;
				modules = [ ./users/susu/home.nix ];
			};
		};

# macOS - NIXY (aarch64-darwin)
		darwinConfigurations = {
			NIXY = darwin.lib.darwinSystem {
				specialArgs = commonSpecialArgs;
				modules = [ ./system/NIXY/darwin-configuration.nix ];
			};
		};

# Standalone home-manager configuration entrypoint for NIXY
		homeConfigurations = {
			"alex@NIXY" = home-manager.lib.homeManagerConfiguration {
				pkgs = legacyPackages.aarch64-darwin;
				extraSpecialArgs = commonSpecialArgs;
				modules = [ ./users/alex/home.nix ];
			};
			"susu@NIXY" = home-manager.lib.homeManagerConfiguration {
				pkgs = legacyPackages.aarch64-darwin;
				extraSpecialArgs = commonSpecialArgs;
				modules = [ ./users/susu/home.nix ];
			};
		};
	};
}

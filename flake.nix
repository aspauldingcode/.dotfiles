
{
	description = "Universal Flake by Alex - macOS and NixOS";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager.url = "github:nix-community/home-manager";
	};

	outputs = { self, nixpkgs, home-manager, ... }: {
# Define NixOS configurations
		nixosConfigurations = {
			NIXSTATION64 = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [./system/NIXSTATION64/configuration.nix];
			};
			NIXEDUP = nixpkgs.lib.nixosSystem {
				system = "aarch64-linux";
				modules = [./system/NIXEDUP/configuration.nix];
			};
			NIXY = nixpkgs.lib.nixosSystem {
				system = "aarch64-darwin";
				modules = [./system/NIXY/configuration.nix];
			};
		};

# Define Home-Manager configurations
		homeConfigurations = {
			"alex@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
				pkgs = nixpkgs.legacyPackages.x86_64-linux;
				modules = [./users/alex/home.nix];
			};
			"susu@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
				pkgs = nixpkgs.legacyPackages.x86_64-linux;
				modules = [./users/susu/home.nix];
			};
			"alex@NIXY" = home-manager.lib.homeManagerConfiguration {
				pkgs = nixpkgs.legacyPackages.aarch64-darwin;
				modules = [./users/alex/home.nix];
			};
			"susu@NIXY" = home-manager.lib.homeManagerConfiguration {
				pkgs = nixpkgs.legacyPackages.aarch64-darwin;
				modules = [./users/susu/home.nix];
			};
# Home-Manager configuration for NIXEDUP (aarch64-linux)
			"alex@NIXEDUP" = home-manager.lib.homeManagerConfiguration {
				pkgs = nixpkgs.legacyPackages.aarch64-linux;
				modules = [./users/alex/home.nix];
			};
		};
	};
}

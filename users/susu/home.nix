# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs, lib, config, pkgs, ... }: 

{
# You can import other home-manager modules here
	imports = [
		./packages.nix
# If you want to use home-manager modules from other flakes (such as nix-colors):
# inputs.nix-colors.homeManagerModule

# You can also split up your configuration and import pieces of it here:
# ./nvim.nix
	];

	nixpkgs = {
# You can add overlays here
		overlays = [
# If you want to use overlays exported from other flakes:
# neovim-nightly-overlay.overlays.default

# Or define it inline, for example:
# (final: prev: {
#   hi = final.hello.overrideAttrs (oldAttrs: {
#     patches = [ ./change-hello-to-hi.patch ];
#   });
# })
		];

# Configure your nixpkgs instance
		config = {
			allowUnfree = true; # Enable Unfree
# Workaround for https://github.com/nix-community/home-manager/issues/2942
				allowUnfreePredicate = _: true; # Still open ticket as of: 10/04/23.
		};
	};

	home = {
		username = "susu";
		homeDirectory = "/home/susu"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
			stateVersion = "23.05";
		file = { # MANAGE DOTFILES?!?
		};
	};

# Configure programs
	programs = {
		home-manager.enable = true;
		git.enable = true;
		neovim = { # TODO: IMPORT from ./nvim.nix!! CREATE SEPERATE NIX MODULE!
			enable = true;
			extraConfig = lib.fileContents ../../extraConfig/nvim/init.lua;
		};
	};
# Nicely reload system units when changing configs
	systemd.user.startServices = "sd-switch"; # TODO: UPDATE IF USING DIFFERENT BOOTLOADER!
}

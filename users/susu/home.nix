# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs, lib, config, pkgs, specialArgs, ... }: 

{
  home = {
    username = "susu";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/susu" else "/home/susu";
    # Other home-related settings
  };

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
		stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
			file = { # MANAGE DOTFILES?
			};
	};

# Configure programs
	programs = {
		home-manager.enable = true;
		git.enable = true;dd
		fish.enable = true;
		neovim = { # TODO: IMPORT from ./nvim.nix!! CREATE SEPERATE NIX MODULE!
			enable = true;
			extraConfig = lib.fileContents ../../extraConfig/nvim/init.lua;
		};
		/*alacritty = { # TODO: IMPORT FROM ./alacritty.nix!! CREATE MODULE!
		  enable = true;
		  extraConfig = '' #alacritty config
key_bindings:
- { key: C, mods: Control|Shift, action: Copy }
- { key: V, mods: Control|Shift, action: Paste }

- { key: Period, mods: Control, chars: "\x03" } 
- { key: Back, mods: Control, chars: "\x0c"} # Replace default terminate SIGTERM thing 

window:
opacity: .3
decorations: buttonless
# Add the following 'padding' setting to control the padding
padding:
x: 5 # Adjust the horizontal padding as needed
y: 5 # Adjust the vertical padding as needed

dynamic_title: true # Uncomment this if you want to enable dynamic title

# Inside your alacritty.yml
font:
normal:
family: "DejaVu Sans Mono"
#style: Regular
size: 14 # Adjust the size as needed

'';
};*/
}; 

# Nicely reload system units when changing configs
systemd.user.startServices = "sd-switch"; # TODO: UPDATE IF USING DIFFERENT BOOTLOADER!
}


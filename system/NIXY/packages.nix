{ lib, pkgs, config,  ... }:

{
nixpkgs = {
		hostPlatform = "aarch64-darwin";
		config = {
			allowUnfree = true;
			allowUnfreePredictate = (_: true);
		};
	};
	# List packages installed in system profile. To search by name, run:
	# $ nix-env -qaP | grep wget
	environment.systemPackages = with pkgs; [ 
		## macosINSTANTView?
		neovim
		neofetch
		htop
		git
		tree
		hexedit
		alacritty
		jdk11
		python311
		python311Packages.pygame
		oh-my-zsh #zsh shell framework
		oh-my-fish #fish shell framework
		#oh-my-git #git learning game
		dmenu
		dwm
		zoom-us
		android-tools
		jq
		libusb
		skhd 
		lolcat
		#yazi # FIXME: NOTWORKINGONDARWIN. TRY BREW!
		#rebuild
		(pkgs.writeShellScriptBin "rebuild" ''
		# NIXY(aarch64-darwin)
		cd ~/.dotfiles
		darwin-rebuild switch --flake .#NIXY
		home-manager switch --flake .#alex@NIXY
		'')
		#update
		(pkgs.writeShellScriptBin "update" ''
		# Navigate to the Repository Directory:
		cd ~/.dotfiles

		#Fetch the Latest Changes:
		git fetch

		# Update Your Local Branch:
		git checkout main
		git merge origin/main

		# Commit Your Changes (if needed):
		git add .
		git commit -m "Updating .dotfiles from NIXY"

		# Push the Changes to the Remote Repository:
		git push origin main
		'')
	];
}
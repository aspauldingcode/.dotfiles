# Configure included packages for NixOS.

{ lib, config, nixpkgs, pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
		neovim
		wl-clipboard
		neofetch
		yazi ueberzugpp 
		pcmanfm			
		wofi-emoji htop fim
		gparted killall tree
		zsh curl lazygit
		wget git
		zoxide
		dnsmasq
		udftools
		element appimage-run
		tree-sitter
		python312
		python311Packages.openrazer
		python311Packages.tree-sitter
		python311Packages.pynvim
		python311Packages.pip
		nodePackages_latest.pyright
		openrazer-daemon
		jdk20
		nodejs
		flex bison
		gnumake gcc
		openssl dtc gnome-themes-extra
		cargo nodePackages_latest.npm
		perl 
		hexedit virt-manager
		#rebuild
		(pkgs.writeShellScriptBin "rebuild" ''
		# NIXSTATION64(x86_64-linux)
		cd ~/.dotfiles
		sudo nixos-rebuild switch --flake .#NIXSTATION64 
		home-manager switch --flake .#alex@NIXSTATION64
		'')
		#update
		(pkgs.writeShellScriptBin "update" ''
		# Navigate to the Repository Directory:
		cd ~/.dotfiles
		
		#Fetch the Latest Changes:
		git fetch
		
		#Pull the changes:
		git pull

		# Update Your Local Branch:
		git checkout main
		git merge origin/main
		
		# Commit Your Changes (if needed):
		git add .
		git commit -m "Updating .dotfiles from NIXSTATION64"
		
		# Push the Changes to the Remote Repository:
		git push origin main
		'')
	]; 
}

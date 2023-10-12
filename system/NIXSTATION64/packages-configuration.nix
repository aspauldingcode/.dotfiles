# Configure included packages for NixOS.

{ lib, config, nixpkgs, pkgs, ... }:

{
    		environment.systemPackages = with pkgs; [
			neovim
			wl-clipboard
			neofetch
			lf ranger pcmanfm			
			wofi-emoji htop fim
			gparted killall tree
			zsh curl lazygit
			wget git
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
			zoom-us
			]; 
}

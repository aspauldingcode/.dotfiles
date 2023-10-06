# Configure included packages for NixOS.

{ config, pkgs, ... }:

{
	config = {
	  allowUnfree = true;
	  allowUnfreePredictate = _: true;   
		environment.systemPackages = with pkgs; [
		checkra1n autotiling neovim
			waydroid wl-clipboard
			neofetch brave zoom-us
			lf ranger pcmanfm			
			wofi-emoji htop fim
			gparted killall tree
			zsh curl lazygit
			wget git w3m obs-studio
			docker home-manager
		android-tools xz 
			element appimage-run
			networkmanagerapplet
			blueman jq
			flameshot
			tree-sitter fd ripgrep
			linuxKernel.packages.linux_latest_libre.openrazer
			razergenie
			python311
			python311Packages.openrazer
			python311Packages.tree-sitter
			python311Packages.pynvim
			python311Packages.pip
			nodePackages_latest.pyright
			openrazer-daemon
			jdk20
			nodejs spotify
			idevicerestore usbmuxd libusbmuxd
			libimobiledevice
			avahi flex bison
			sshfs pciutils socat
			pmbootstrap android-studio
			gnumake gcc libusb1
			openssl dtc gnome-themes-extra
			cargo nodePackages_latest.npm
			xarchiver logseq perl 
			hexedit
			gimp virt-manager

			(
			 pkgs.writeTextFile {
			 name = "startsway";
			 destination = "/bin/startsway";
			 executable = true;
			 text = ''
#! ${pkgs.bash}/bin/bash

# first import environment variables from the login manager
			 systemctl --user import-environment
# then start the service
			 exec systemctl --user start sway.service
			 '';
			 }
			)
			]; 
			};
}

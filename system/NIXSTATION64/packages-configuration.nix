# Configure included packages for NixOS.

{ lib, config, pkgs, ... }:

{
nixpkgs.config = {
  allowUnfreePredicate = pkg:
    builtins.elem (
      lib.getName pkg
    ) (
      map lib.getName [
        pkgs.corefonts
        pkgs.discord
        #pkgs.jetbrains.idea-ultimate
        #pkgs.spotify-unwrapped
        pkgs.unrar
	pkgs.checkra1n
	pkgs.beeper
	pkgs.zoom-us
	pkgs.android-studio
      ]
    ); 
    android_sdk.accept_license = true;


    };
		environment.systemPackages = with pkgs; [
		autotiling neovim
			waydroid wl-clipboard
			neofetch brave
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
			python312
			python311Packages.openrazer
			python311Packages.tree-sitter
			python311Packages.pynvim
			python311Packages.pip
			nodePackages_latest.pyright
			openrazer-daemon
			jdk20
			nodejs
			idevicerestore usbmuxd libusbmuxd
			libimobiledevice
			avahi flex bison
			sshfs pciutils socat
			pmbootstrap
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
}

{ lib, config, pkgs, ... }:

# TODO: Implement an import system-universal.nix MODULE
{
imports = [ 
./yabai.nix
./skhd.nix
./spacebar.nix
./defaults-macos.nix
#./homebrew-pkgs.nix #FIXME

];
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
		#yazi #NOTWORKINGONDARWIN
		#rebuild
		(pkgs.writeShellScriptBin "rebuild" ''
		# NIXY(aarch64-darwin)
		cd ~/.dotfiles
		darwin-rebuild switch --flake .#NIXY
		home-manager switch --flake .#alex@NIXY
		'')
		#update
sp		(pkgs.writeShellScriptBin "update" ''
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




#enable brew packages just in case
	homebrew.enable = true;

	homebrew = {
		brews = [
			"xinit"
				"xorg-server"
		];

		casks = [
			"xquartz"
				"dmenu-mac"
		];

#masApps = [
#"123456789"  # Mac App Store app ID
#"987654321"
#];

#whalebrews = [
#	"wget"
#		"whalesay"
#];

#taps = [
#"user/repo"  # Additional Homebrew tap
#];
	};

	/*homebrew.whalebrews = [
	   f"whalebrew/wget"
	  "whalebrew/whalesay"
	  ];*/

#allow broken packages
#nixpkgs.config.allowBroken = true;
# Use a custom configuration.nix location.
# $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
# environment.darwinConfig = "$HOME/.config/nixpkgs/darwini/configuration.nix";

# Allow Unfree
	nixpkgs.config.allowUnsupportedSystem = true;

	fonts.fontDir.enable = true;
	fonts.fonts = with pkgs; [
		dejavu_fonts
			font-awesome_5
	];


# system.build = builtins.exec "echo 'hello, world.'";

# Auto upgrade nix package and the daemon service.
	services.nix-daemon.enable = true;
# nix.package = pkgs.nix;

# Create /etc/zshrc that loads the nix-darwin environment.
	programs.zsh.enable = true;  # default shell on catalina
# programs.fish.enable = true;

nix.settings.auto-optimise-store = true;

		nix.extraOptions = ''
		extra-platforms = aarch64-darwin x86_64-darwin
		experimental-features = nix-command flakes
		'';

# Used for backwards compatibility, please read the changelog before changing.
# $ darwin-rebuild changelog
	system.stateVersion = 4;
}


{ lib, config, pkgs, ... }:

# TODO: Implement an import system-universal.nix MODULE
{
imports = [
./packages.nix
./yabai.nix
./skhd.nix
./spacebar.nix
./defaults-macos.nix
#./homebrew-pkgs.nix

];



#enable brew packages just in case
	homebrew.enable = true;

	homebrew = {
		brews = [
			"xinit"
			"xorg-server"
			"choose-gui"
		];

		casks = [
			"xquartz"
			"dmenu-mac"
			"hiddenbar"
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


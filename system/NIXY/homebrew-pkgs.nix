{ lib, pkgs, config, ... }:

{
#enable brew packages just in case
	homebrew.enable = true;

	homebrew = {
		brews = [
			"xinit"
			"xorg-server"
			"choose-gui"
            "yazi"
		];

		casks = [
			"xquartz"
            "dmenu-mac"
            "alfred"
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

}

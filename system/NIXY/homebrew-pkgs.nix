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
            "virt-manager"
		];

		casks = [
			"xquartz"
            "dmenu-mac"
            "alfred"
            "brave-browser"
		];

        #masApps = [ #FAILS
          #497799835 #Xcode 
        #];
        whalebrews = [
          #"wget" #FAILS
          #"whalesay" #FAILS
        ];
        taps = [
          #"user/repo"  # Additional Homebrew tap
        ];
	};

#allow broken packages
#nixpkgs.config.allowBroken = true;
# Use a custom configuration.nix location.
# $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
# environment.darwinConfig = "$HOME/.config/nixpkgs/darwini/configuration.nix";

}

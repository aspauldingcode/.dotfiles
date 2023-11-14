{ lib, pkgs, config, ... }:

{
#enable brew packages just in case
	homebrew.enable = true;

	homebrew = {
		brews = [
			"xinit"
			"xorg-server"
            "choose-gui"
		];

		casks = [
            #"xquartz" #what an ugly app
            "dmenu-mac"
            "brave-browser"
            "alt-tab"
            "orbstack"
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
}

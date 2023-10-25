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
        home-manager
		skhd
		neovim
		neofetch
		htop
		git
		tree
		ranger
		hexedit
        #alacritty
		iterm2
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
		lolcat
		#rebuild
		(pkgs.writeShellScriptBin "rebuild" ''
		# NIXY(aarch64-darwin)
		cd ~/.dotfiles
		darwin-rebuild switch --flake .#NIXY
		home-manager switch --flake .#alex@NIXY
		#defaults write com.apple.dock ResetLaunchPad -bool true
		'')
		#update
        (pkgs.writeShellScriptBin "update" ''
          cd ~/.dotfiles
          git fetch
          git pull
          git merge origin/main
          # Prompt the user for a commit message
          echo "Enter a commit message:"
          read commit_message
          git add .
          git commit -m "$commit_message"
          git push origin main
        '')
	];
}

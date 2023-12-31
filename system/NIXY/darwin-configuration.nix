{ pkgs, ... }:
### System Configuration.nix for Darwin
{
	imports = [
	./packages.nix
	./defaults-macos.nix
	./homebrew-pkgs.nix
	];
	# Allow Unfree
	nixpkgs.config.allowUnsupportedSystem = true;

	fonts.fontDir.enable = true;
	fonts.fonts = with pkgs; [
		dejavu_fonts
        font-awesome_5
        jetbrains-mono
		(pkgs.callPackage ./apple-fonts.nix {})
		(nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" "Hack" ]; })
      ];

	# system.build = builtins.exec "echo 'hello, world.'";
	# Auto upgrade nix package and the daemon service.
	services.nix-daemon.enable = true;
	# nix.package = pkgs.nix;

	# Create /etc/zshrc that loads the nix-darwin environment.
	programs.zsh.enable = true;  # default shell on catalina
	programs.fish.enable = false; #NOT Borne COMPAT? 
	users.users.alex.shell = pkgs.zsh; 
	nix = { 
		settings.auto-optimise-store = true;
		extraOptions = ''
			extra-platforms = aarch64-darwin x86_64-darwin
			experimental-features = nix-command flakes
		'';
	};
	# Used for backwards compatibility, please read the changelog before changing.
	# $ darwin-rebuild changelog
	system.stateVersion = 4;
}


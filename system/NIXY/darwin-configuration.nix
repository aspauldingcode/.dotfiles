{ lib, config, pkgs, ... }:
### System Configuration.nix for Darwin
{
imports = [
./packages.nix
#./yabai.nix #FIXME: Migrating to Home-manager!
#./skhd.nix #FIXME: not working. try using the config at /Users/alex/.skhdrc
#./spacebar.nix
./sketchybar.nix
./defaults-macos.nix
./homebrew-pkgs.nix

];
# Allow Unfree
	nixpkgs.config.allowUnsupportedSystem = true;

	fonts.fontDir.enable = true;
	fonts.fonts = with pkgs; [
		dejavu_fonts
		font-awesome_5
		(nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
	];
# system.build = builtins.exec "echo 'hello, world.'";

# Auto upgrade nix package and the daemon service.
	services.nix-daemon.enable = true;
# nix.package = pkgs.nix;

# Create /etc/zshrc that loads the nix-darwin environment.
	programs.zsh.enable = true;  # default shell on catalina
	programs.fish.enable = true;
    users.users.alex.shell = pkgs.fish;

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


{ config, pkgs, ... }:

{
	home = {
		packages = with pkgs; [
			calcurse
				spotify-tui
				spotifyd
				delta
				gnupg
				audacity
				pinentry
				beeper
				libusbmuxd
				sshpass
				gnumake
# It is sometimes useful to fine-tune packages, for example, by applying
# # overrides. You can do that directly here, just don't forget the
# # parentheses. Maybe you want to install Nerd Fonts with a limited number of
# # fonts?
# (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

# # You can also create simple shell scripts directly inside your
# # configuration. For example, this adds a command 'my-hello' to your
# # environment:
				(pkgs.writeShellScriptBin "my-hello" ''
				 echo "Hello, ${config.home.username}!"
				 '')
				];
	};
	pointerCursor = { # add neat cursors
		gtk.enable = true;
		package = pkgs.bibata-cursors;
		name = "Bibata-Modern-Ice";
		size = 22;
	};


}

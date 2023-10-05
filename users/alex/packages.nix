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
				git-crypt
				cowsay

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

				(pkgs.writeShellScriptBin "silly" ''
				 what=$(cat cowsayhi.log)
				 sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$what"
				 '')

				(pkgs.writeShellScriptBin "lockscreen-motd" ''
				 class_directory="/Users/alex/"

# Run the Java program with the classpath option and capture its output in the 'what' variable
				 what=$(java -cp "$class_directory" SineWaveASCII)

# Use the captured output as 'LoginwindowText' directly
				 sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$what"

				 '')

				];
		pointerCursor = { # add neat cursors
			gtk.enable = true;
			package = pkgs.bibata-cursors;
			name = "Bibata-Modern-Ice";
			size = 22;
		};
	};


}

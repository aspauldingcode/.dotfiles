{ lib, config, pkgs, ... }:

# NIXY-specific packages


{
  imports = [
  ];
  
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home.packages = with pkgs; [
  	calcurse
	delta
	sshpass
	git-crypt
	cowsay
	discord
	zoom-us
	spotify-unwrapped
	jetbrains.idea-ultimate
	(prismlauncher.override {
      		jdks = [ jdk8 jdk17 jdk19 ]; 
      	})

    # dmenu-mac
    # yabai?
    # skhd?
    # macports?
    # orbstack?
    # UTM? 
    # xCode?
    # x-code-cli?
    # Townscraper?
    # homebrew?
    # sketchybar?
    # xinit?
    # xorg-server?
    # XQuartz?

    			#hello
                        (pkgs.writeShellScriptBin "my-hello" ''
                         echo "Hello, ${config.home.username}!"
                         '')
			#silly
                        (pkgs.writeShellScriptBin "silly" ''
                         what=$(cat cowsayhi.log)
                         sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$what"
                         '')
			#lockscreen-motd
                        (pkgs.writeShellScriptBin "lockscreen-motd" ''
                         class_directory="/Users/alex/"

# Run the Java program with the classpath option and capture its output in the 'what' variable
                         what=$(java -cp "$class_directory" SineWaveASCII)

# Use the captured output as 'LoginwindowText' directly
                         sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$what"
                         '')
			#fix-skhd
			(pkgs.writeShellScriptBin "fix-skhd" ''
			sudo pkill skhd && skhd &
			'')
			#shutdown without params
			(pkgs.writeShellScriptBin "shutdown" ''
			sudo shutdown -h now
			'')
  ];
}


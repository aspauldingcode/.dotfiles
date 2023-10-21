{ lib, config, pkgs, ... }:
# NIXY-specific packages

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = false;

    };
  };

  home.packages = with pkgs; [
  	calcurse
	ncdu
	delta
	sshpass
	git-crypt
	cowsay
	discord
	#davinci-resolve NEEDS TO BE MAS APP?
	zoom-us
#python311Packages.pyautogui
	spotify-unwrapped
	(prismlauncher.override {
      		jdks = [ jdk8 jdk17 jdk19 ]; 
      	})
    # #TODO
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
    # davinci-resolve?

    			#hello
                        (pkgs.writeShellScriptBin "my-hello" ''
                         echo "Hello, ${config.home.username}!"
                         '')
			#lockscreen-motd
                        (pkgs.writeShellScriptBin "lockscreen-motd" ''
                         class_directory="/Users/alex/"

			# Run the Java program with the classpath option and 
			# capture its output in the 'what' variable
                         what=$(java -cp "$class_directory" SineWaveASCII)

			# Use the captured output as 'LoginwindowText' directly
                        sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$what"
                         '')
			#fix-skhd
			(pkgs.writeShellScriptBin "fix-skhd" ''
			sudo pkill skhd && skhd -c /etc/skhdrc -V
			echo "To run this fix in the background, run \nfix-skhd &"
			'')
			/*#shutdown without params FIXME
			(pkgs.writeShellScriptBin "shutdown" ''
			sudo shutdown -h now
			'')*/
			];
}



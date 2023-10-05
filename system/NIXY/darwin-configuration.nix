{ config, pkgs, ... }:

{

	nixpkgs.hostPlatform = "aarch64-darwin";

# List packages installed in system profile. To search by name, run:
# $ nix-env -qaP | grep wget

	environment.systemPackages = with pkgs; [ 
		neovim
		home-manager
		git
		tree
		hexedit
		alacritty
#obs-studio
#pkgs.brave
		jdk20
		python311
		python311Packages.pygame
		oh-my-zsh
		skhd
		dmenu
		dwm
#xvkbd
		neofetch
		htop
		docker
		zoom-us
		android-tools
		jq
#orbstack
#pkgs.xorg 
		];

	services.yabai = {
		enable = true;
		package = pkgs.yabai;
		enableScriptingAddition = true;
		config = {
			focus_follows_mouse          = "autoraise";
			mouse_follows_focus          = "off";
			window_placement             = "second_child";
			window_opacity               = "on";
			window_opacity_duration      = "0.1";
			window_topmost               = "off";
			window_shadow                = "float";
			active_window_opacity        = "1.0";
			normal_window_opacity        = "0.3";
			split_ratio                  = "0.50";
			auto_balance                 = "on";
			mouse_modifier               = "alt";
			mouse_action1                = "move";
			mouse_action2                = "resize";
			layout                       = "bsp";
			top_padding                  = 36;
			bottom_padding               = 10;
			left_padding                 = 10;
			right_padding                = 10;
			window_gap                   = 10;
		};

		extraConfig = ''
# rules
			yabai -m rule --add app='System Preferences' manage=off
			yabai -m rule --add app='zoom.us' manage=off
# Any other arbitrary config here

			yabai -m config window_border				 on
			yabai -m config window_border_blur			 on
			yabai -m window_border_radius				 0
			yabai -m config window_border_width          0.1
#yabai -m config active_window_border_color   0xff25B2BC
#yabai -m config normal_window_border_color   0xff555555
#yabai -m config insert_feedback_color        0xffd75f5f
#yabai -m config window_origin_display        default

# Toggle test
#yabai -m query --windows --space |
#jq '.[].id' |
#xargs -I{} yabai -m window {} --toggle border

			echo "yabai config loaded...
			'';
	};

	services.skhd = {
		enable = true;
		package = pkgs.skhd;
		skhdConfig = ''
			alt - return : open -n /Applications/Alacritty.app;
# Add more hotkey configurations as needed
# change focus
		alt - h : yabai -m window --focus west
			alt - j : yabai -m window --focus south
			alt - k : yabai -m window --focus north
			alt - l : yabai -m window --focus east
# (alt) change focus (using arrow keys)
			alt - left  : yabai -m window --focus west
			alt - down  : yabai -m window --focus south
			alt - up    : yabai -m window --focus north
			alt - right : yabai -m window --focus east

# shift window in current workspace
			alt + shift - h : yabai -m window --swap west || $(yabai -m window --display west; yabai -m display --focus west)
			alt + shift - j : yabai -m window --swap south || $(yabai -m window --display south; yabai -m display --focus south)
			alt + shift - k : yabai -m window --swap north || $(yabai -m window --display north; yabai -m display --focus north)
			alt + shift - l : yabai -m window --swap east || $(yabai -m window --display east; yabai -m display --focus east)
# alternatively, use the arrow keys
			alt + shift - left : yabai -m window --swap west || $(yabai -m window --display west; yabai -m display --focus west)
			alt + shift - down : yabai -m window --swap south || $(yabai -m window --display south; yabai -m display --focus south)
			alt + shift - up : yabai -m window --swap north || $(yabai -m window --display north; yabai -m display --focus north)
			alt + shift - right : yabai -m window --swap east || $(yabai -m window --display east; yabai -m display --focus east)
# set insertion point in focused container
			alt + ctrl - h : yabai -m window --insert west
			alt + ctrl - j : yabai -m window --insert south
			alt + ctrl - k : yabai -m window --insert north
			alt + ctrl - l : yabai -m window --insert east
# (alt) set insertion point in focused container using arrows
			alt + ctrl - left  : yabai -m window --insert west
			alt + ctrl - down  : yabai -m window --insert south
			alt + ctrl - up    : yabai -m window --insert north
			alt + ctrl - right : yabai -m window --insert east

# go back to previous workspace (kind of like back_and_forth in i3)
			alt - b : yabai -m space --focus recent

# move focused window to previous workspace
			alt + shift - b : yabai -m window --space recent; \
			yabai -m space --focus recent

# move focused window to next/prev workspace
			alt + shift - 1 : yabai -m window --space 1
			alt + shift - 2 : yabai -m window --space 2
			alt + shift - 3 : yabai -m window --space 3
			alt + shift - 4 : yabai -m window --space 4
			alt + shift - 5 : yabai -m window --space 5
			alt + shift - 6 : yabai -m window --space 6
			alt + shift - 7 : yabai -m window --space 7
			alt + shift - 8 : yabai -m window --space 8
			alt + shift - 9 : yabai -m window --space 9
#alt + shift - 0 : yabai -m window --space 10

# # mirror tree y-axis
			alt + shift - y : yabai -m space --mirror y-axis

# # mirror tree x-axis
			alt + shift - x : yabai -m space --mirror x-axis

# balance size of windows
			alt + shift - 0 : yabai -m space --balance

# change layout of desktop
			alt - e : yabai -m space --layout bsp
			alt - l : yabai -m space --layout float
			alt - s : yabai -m space --layout stack

# cycle through stack windows
# alt - p : yabai -m window --focus stack.next || yabai -m window --focus south
# alt - n : yabai -m window --focus stack.prev || yabai -m window --focus north

# forwards
			alt - p : yabai -m query --spaces --space \
			| jq -re ".index" \
			| xargs -I{} yabai -m query --windows --space {} \
			| jq -sre "add | map(select(.minimized != 1)) | sort_by(.display, .frame.y, .frame.x, .id) | reverse | nth(index(map(select(.focused == 1))) - 1).id" \
			| xargs -I{} yabai -m window --focus {}

# backwards
		alt - n : yabai -m query --spaces --space \
			| jq -re ".index" \
			| xargs -I{} yabai -m query --windows --space {} \
			| jq -sre "add | map(select(.minimized != 1)) | sort_by(.display, .frame.y, .frame.y, .id) | nth(index(map(select(.focused == 1))) - 1).id" \
			| xargs -I{} yabai -m window --focus {}

# close focused window
		alt + shift - q : yabai -m window --close

# enter fullscreen mode for the focused container
			alt - f : yabai -m window --toggle zoom-fullscreen

# toggle window native fullscreen
			alt + shift - f : yabai -m window --toggle native-fullscreen

##FIXME toggle floating window NOT WORKING YET
			alt + shift - space : yabai -m window --toggle native-fullscreen

# Launch Brave
#alt + control - space : yabai -m window --togge native-fullscreen

#alt + control - space : open -a "Applications/Brave Browser.app"

			'';
	};
	services.spacebar = {
		enable = true;
		package = pkgs.spacebar;
		config = {

		}; 
		extraConfig = ''
			spacebar -m config right_shell off
			spacebar -m config position                    top
			spacebar -m config height                      26
			spacebar -m config title                       on
			spacebar -m config spaces                      on
			spacebar -m config clock                       on
			spacebar -m config power                       on
			spacebar -m config padding_left                20
			spacebar -m config padding_right               20
			spacebar -m config spacing_left                25
			spacebar -m config spacing_right               15
			spacebar -m config text_font                   "Helvetica Neue:Bold:12.0"
			spacebar -m config icon_font                   "Font Awesome 5 Free:Solid:12.0"
			spacebar -m config background_color            0xff202020
			spacebar -m config foreground_color            0xffa8a8a8
			spacebar -m config power_icon_color            0xffcd950c
			spacebar -m config battery_icon_color          0xffd75f5f
			spacebar -m config dnd_icon_color              0xffa8a8a8
			spacebar -m config clock_icon_color            0xffa8a8a8
			spacebar -m config power_icon_strip             
			spacebar -m config space_icon                  •
			spacebar -m config space_icon_color            0xffffab91
			spacebar -m config space_icon_color_secondary  0xff78c4d4
			spacebar -m config space_icon_color_tertiary   0xfffff9b0
			spacebar -m config space_icon_strip            1 2 3 4 5 6 7 8 9 10
			spacebar -m config clock_icon                  
			spacebar -m config dnd_icon                    
			spacebar -m config clock_format                "%d/%m/%y %R"
			spacebar -m config right_shell                 on
			spacebar -m config right_shell_icon            
			spacebar -m config right_shell_command         "whoami"
			echo "spacebar configuration loaded.."
			'';
	};
# Enable unfree:
	nixpkgs.config.allowUnfree = true;

#enable brew packages just in case
	homebrew.enable = true;

	homebrew = {
		brews = [
			"xinit"
				"xorg-server"
		];

		casks = [
			"xquartz"
				"dmenu-mac"
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
	  "whalebrew/wget"
	  "whalebrew/whalesay"
	  ];*/

#allow broken packages
	nixpkgs.config.allowBroken = true;
# Use a custom configuration.nix location.
# $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
# environment.darwinConfig = "$HOME/.config/nixpkgs/darwini/configuration.nix";

# Allow Unfree
	nixpkgs.config.allowUnsupportedSystem = true;

	fonts.fontDir.enable = true;
	fonts.fonts = with pkgs; [
		dejavu_fonts
			font-awesome_5
	];

##SYSTEM DEFAULTS!!!!

# Hide Desktop icons
	system.defaults.finder.CreateDesktop = false;
# Show all files
	system.defaults.finder.AppleShowAllFiles = true;
# Show all extentions
	system.defaults.finder.AppleShowAllExtensions = true;
# Change the default search scope. Use "SCcf" to default to the current folder.
	system.defaults.finder.FXDefaultSearchScope = "SCcf";
# Whether to show warnings when change the file extension of files. The default is true.
	system.defaults.finder.FXEnableExtensionChangeWarning = false;
# Change the default finder view. “icnv” = Icon view, “Nlsv” = List view, “clmv” = Column View, “Flwv” = Gallery View The default is icnv.
	system.defaults.finder.FXPreferredViewStyle = "Nlsv";
#Whether to allow quitting of the Finder. The default is false.
	system.defaults.finder.QuitMenuItem = true;
#Show path breadcrumbs in finder windows. The default is false.
	system.defaults.finder.ShowPathbar = false;
#Show status bar at bottom of finder windows with item/disk space stats. The default is false.
	system.defaults.finder.ShowStatusBar = false;
#Whether to show the full POSIX filepath in the window title. The default is false.
	system.defaults.finder._FXShowPosixPathInTitle = true;
#Disables the ability for a user to access the console by typing “>console” for a username at the login window. Default is false.
	system.defaults.loginwindow.DisableConsoleAccess = true;
#Allow users to login to the machine as guests using the Guest account. Default is true.
	system.defaults.loginwindow.GuestEnabled = false;

#Text to be shown on the login window. Default is “\\U03bb”.
#system.defaults.loginwindow.LoginwindowText = "Login as: " whoami; ### READ HOMEMANAGER CONFIG!!!

#If set to true, the Power Off menu item will be disabled when the user is logged in. Default is false.
	system.defaults.loginwindow.PowerOffDisabledWhileLoggedIn = false;
#Hides the Restart button on the login screen. Default is false.
	system.defaults.loginwindow.RestartDisabled = false;
#Disables the “Restart” option when users are logged in. Default is false.
	system.defaults.loginwindow.RestartDisabledWhileLoggedIn = false;
# Hides the Sleep button on the login screen. Default is false.
	system.defaults.loginwindow.SleepDisabled = false;
#Whether to enable smooth scrolling. The default is true.
	system.defaults.NSGlobalDomain.NSScrollAnimationEnabled = false;

# system.build = builtins.exec "echo 'hello, world.'";

# Auto upgrade nix package and the daemon service.
	services.nix-daemon.enable = true;
# nix.package = pkgs.nix;

# Create /etc/zshrc that loads the nix-darwin environment.
	programs.zsh.enable = true;  # default shell on catalina
# programs.fish.enable = true;

		nix.extraOptions = ''
		extra-platforms = aarch64-darwin x86_64-darwin
		experimental-features = nix-command flakes
		'';

# Used for backwards compatibility, please read the changelog before changing.
# $ darwin-rebuild changelog
	system.stateVersion = 4;
}


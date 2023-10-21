{ lib, pkgs, config, ... }:
##SYSTEM DEFAULTS!!!! MACOS defaults config.
{
system.defaults = {
	finder = { 
		# Hide Desktop icons
		CreateDesktop = false;
		AppleShowAllFiles = true;
		AppleShowAllExtensions = true;
		# Change the default search scope. Use "SCcf" to default to the current folder.
		FXDefaultSearchScope = "SCcf";	
		# Whether to show warnings when change the file extension of files. The default is true.
		FXEnableExtensionChangeWarning = false;
		# Change the default finder view. “icnv” = Icon view, “Nlsv” = List view, “clmv” = Column View, “Flwv” = Gallery View The default is icnv.
		FXPreferredViewStyle = "Nlsv";
		#Whether to allow quitting of the Finder. The default is false.
		QuitMenuItem = true;
		#Show path breadcrumbs in finder windows. The default is false.
		ShowPathbar = false;
		#Show status bar at bottom of finder windows with item/disk space stats. The default is false.
		ShowStatusBar = false;
		#Whether to show the full POSIX filepath in the window title. The default is false.
		_FXShowPosixPathInTitle = true;
	};
	loginwindow = {
		#Disables the ability for a user to access the console by typing “>console” for a username at the login window. Default is false.
		DisableConsoleAccess = true;
		#Allow users to login to the machine as guests using the Guest account. Default is true.
		GuestEnabled = false;

		#Text to be shown on the login window. Default is “\\U03bb”. 
		#LoginwindowText = "Login as: " whoami; ###FIXME READ HOMEMANAGER CONFIG!!!

		#If set to true, the Power Off menu item will be disabled when the user is logged in. Default is false.
		PowerOffDisabledWhileLoggedIn = false;
		#Hides the Restart button on the login screen. Default is false.
		RestartDisabled = false;
		#Disables the “Restart” option when users are logged in. Default is false.
		RestartDisabledWhileLoggedIn = false;
		# Hides the Sleep button on the login screen. Default is false.
		SleepDisabled = false;
	};
	NSGlobalDomain = {
		#Whether to enable smooth scrolling. The default is true.
		NSScrollAnimationEnabled = false;
		#Whether to animate opening and closing of windows and popovers. The default is true.
		NSAutomaticWindowAnimationsEnabled = false;
		#Sets the speed speed of window resizing. The default is given in the example.
		NSWindowResizeTime = 0.0;
	};
	spaces = {
	# Displays have separate Spaces (note a logout is required before this setting will take effect).
	spans-displays = false;
	};
};
}

{ lib, config, pkgs, ... }:

home-manager.users.alex = {
	programs = {
		git = {
			enable = true;
			userName  = "aspauldingcode";
			userEmail = "aspauldingcode@gmail.com";
		};
	};
}

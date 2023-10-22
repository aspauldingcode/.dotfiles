{ lib, config, pkgs, ... }:

{
	programs = {
		git = {
			enable = true;
			userName  = "aspauldingcode";
			userEmail = "aspauldingcode@gmail.com";
		};
	};
}


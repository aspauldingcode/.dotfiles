{ lib, config, pkgs, ... }: 

{
#import other home-manager modules which are NIXSTATION64-specific
	imports = [
		./packages-NIXSTATION64.nix 
#./modules/extraConfig/git.nix
	];
	home = {
		username = "alex";
		homeDirectory = "/home/alex";
		stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
			file = { # MANAGE DOTFILES?
			};
	};

	programs = {
		#neovim = { #already configured in systemconfig.
		#	enable = true;
		#	extraConfig = lib.fileContents ./modules/extraConfig/nvim/init.lua;
		#};
		git = {
			enable = true;
			userName  = "aspauldingcode";
			userEmail = "aspauldingcode@gmail.com";
		};
	};

# Decoratively fix virt-manager error: "Could not detect a default hypervisor" instead of imperitively through virt-manager's menubar > file > Add Connection
	dconf.settings = {
  "org/virt-manager/virt-manager/connections" = {
    autoconnect = ["qemu:///system"];
    uris = ["qemu:///system"];
  };
};

# Nicely reload system units when changing configs
		systemd.user.startServices = "sd-switch"; # TODO: UPDATE IF USING DIFFERENT BOOTLOADER!
	}
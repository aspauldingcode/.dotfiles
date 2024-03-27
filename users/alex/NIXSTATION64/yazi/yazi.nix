{ config, ... }:

# yazi configuration!
{
    home.file = {
	yazi = {
	    target = ".config/yazi/yazi.toml";
	    source = ./yazi.toml;
	};
	yazitheme = {
	    target = ".config/yazi/theme.toml";
	    source = ./theme.toml;
	};
	yazikeymap = {
	    target = ".config/yazi/keymap.toml";
	    source = ./keymap.toml;
	};
    };
}

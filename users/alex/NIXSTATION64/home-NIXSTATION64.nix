{ lib, config, pkgs, ... }: 

{
#import other home-manager modules which are NIXSTATION64-specific
imports = [
  ./packages-NIXSTATION64.nix 
  ./nvim.nix
]; 
home = {
  username = "alex";
  homeDirectory = "/home/alex";
  stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  file = { # MANAGE DOTFILES?
};
    };

    services = {
      mako = {
        enable = true;
        maxVisible = -1;
        output = "DP-2";
        layer = "overlay";
        anchor = "top-right";
            #font = 
            borderSize = 2;
            borderColor = "#A34A28";
            borderRadius = 10;
            defaultTimeout = 5000;
            ignoreTimeout = false;
          };

        };
        programs = {
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

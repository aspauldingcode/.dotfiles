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
          fish.enable = true;

          alacritty = {
            enable = true;
            settings = {
              window = {
                padding.x = 0;
                padding.y = 0;
                opacity   = 0.1;
                class.instance = "Alacritty";
                class.general  = "Alacritty";
              };

              scrolling = {
                history = 10000;
                multiplier = 3;
              };

              font.size = 13.0;

              /*colors = {
                #primary = {
                #  background = "0x101010";
                #  foreground = "0xC470F7";
                #};
                cursor = {
                  text    ="0xEBEBEB";
                  cursor  ="0xEBEBEB";
                };
                normal = {
                  black   ="0x0d0d0d";
                  red     ="0xFF301B";
                  green   ="0xA0E521";
                  yellow  ="0xFFC620";
                  blue    ="0x1BA6FA";
                  magenta ="0x8763B8";
                  cyan    ="0x21DEEF";
                  white   ="0xEBEBEB";
                };
                bright = {
                  black   ="0x6D7070";
                  red     ="0xFF4352";
                  green   ="0xB8E466";
                  yellow  ="0xFFD750";
                  blue    ="0x1BA6FA";
                  magenta ="0xA578EA";
                  cyan    ="0x73FBF1";
                  white   ="0xFEFEF8";
                };
              };
            */
              cursor = {
                style = "Beam";
                blinking = "On";
                blink_interval = 750;
              };

              draw_bold_text_with_bright_colors = true;
              live_config_reload = true;

              key_bindings = [
                {
                  key = "C";
                  mods = "Control";
                  action = "Copy";
                  }
                  {
                  key = "V";
                      mods = "Control";
                      action = "Paste";
                    }
                    {
                      key = "C"; 
                      mods = "Control|Shift";
                      chars = "\\x03";
                    }
                  ];
                };
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
systemd.user.startServices = "sd-switch"; # TODO: UPDATE IF USING DIFFERENT INIT SYSTEM!
}

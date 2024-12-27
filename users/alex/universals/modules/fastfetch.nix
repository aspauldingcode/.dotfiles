{ config, pkgs, nix-colors, ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        padding = {
          top = 2;
        };
      };
      modules = [
        "title"
        "separator" 
        "os"
        "host"
        "bios"
        "bootmgr"
        "board"
        # "chassis" # didn't work
        "kernel"
        # "initsystem" # didn't work
        "uptime"
        "loadavg"
        "processes"
        {
          type = "packages";
          format = "{1} (nix-system), {2} (nix-default), {3} (brew), {4} (brew-cask)";
        }
        "shell"
        "editor"
        "display"
        "brightness"
      #   "monitor"
        # "lm"
        "de"
        {
          type = "wm";
          format = "Yabai";
        }
        {
          type = "theme";
          themeText = "${config.colorScheme.slug} (${config.colorScheme.variant})";
        }
      #   "icons"
      #   "font"
        {
          type = "cursor";
          format = "Bibata-Modern-Ice";
        }
      #   "wallpaper"
      #   "terminal"
      #   "terminalfont"
      #   "terminalsize"
      #   "terminaltheme"
      #   {
      #     type = "cpu";
      #     showPeCoreCount = true;
      #     temp = true;
      #   }
      #   "cpucache"
      #   "cpuusage"
      #   {
      #     type = "gpu";
      #     driverSpecific = true;
      #     temp = true;
      #   }
      #   "memory"
      #   "physicalmemory"
      #   "swap"
      #   "disk"
      #   "btrfs"
      #   "zpool"
      #   {
      #     type = "battery";
      #     temp = true;
      #   }
      #   "poweradapter"
      #   "player"
      #   "media"
      #   {
      #     type = "publicip";
      #     timeout = 1000;
      #   }
      #   {
      #     type = "localip";
      #     showIpv6 = true;
      #     showMac = true;
      #     showSpeed = true;
      #     showMtu = true;
      #     showLoop = true;
      #     showFlags = true;
      #     showAllIps = true;
      #   }
      #   "dns"
      #   "wifi"
      #   "datetime"
      #   "locale"
      #   "vulkan"
      #   "opengl"
      #   "opencl" 
      #   "users"
      #   "bluetooth"
      #   "bluetoothradio"
      #   "sound"
      #   "camera"
      #   "gamepad"
      #   {
      #     type = "weather";
      #     timeout = 1000;
      #   }
      #   "netio"
      #   "diskio"
      #   {
      #     type = "physicaldisk";
      #     temp = true;
      #   }
      #   "tpm"
      #   "version"
      #   "break"
        "colors"
      ];
    };
  };
}

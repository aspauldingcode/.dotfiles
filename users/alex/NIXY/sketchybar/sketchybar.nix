#Must add a sketchybar dotfile config under home-manager for alex
{ config, pkgs, lib, ... }: 

{ # xdg.configFile."foo/bar".source = ./file/path; will symlink ./file/path to .config/foo/bar
  xdg.configFile."sketchybar/sketchybarrc".source = ./sketchybarrc;
  xdg.configFile."sketchybar/colors.sh".source = ./colors.sh;
  xdg.configFile."sketchybar/icons.sh".source = ./icons.sh;
  xdg.configFile."sketchybar/plugins/apple.sh".source = ./plugins/apple.sh;
  xdg.configFile."sketchybar/plugins/battery.sh".source = ./plugins/battery.sh;
  xdg.configFile."sketchybar/plugins/cpu.sh".source = ./plugins/cpu.sh;
  xdg.configFile."sketchybar/plugins/date.sh".source = ./plugins/date.sh;
  xdg.configFile."sketchybar/plugins/mail.sh".source = ./plugins/mail.sh;
  xdg.configFile."sketchybar/plugins/ram.sh".source = ./plugins/ram.sh;
  xdg.configFile."sketchybar/plugins/spaces.sh".source = ./plugins/spaces.sh;
  xdg.configFile."sketchybar/plugins/speed.sh".source = ./plugins/speed.sh;
  xdg.configFile."sketchybar/plugins/spotify.sh".source = ./plugins/spotify.sh;
  xdg.configFile."sketchybar/plugins/time.sh".source = ./plugins/time.sh;
  xdg.configFile."sketchybar/plugins/volume.sh".source = ./plugins/volume.sh;
  xdg.configFile."sketchybar/plugins/volume_click.sh".source = ./plugins/volume_click.sh;
  xdg.configFile."sketchybar/plugins/wifi.sh".source = ./plugins/wifi.sh;
}

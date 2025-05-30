{ config, lib, ... }:

let
  inherit (config.colorScheme) palette;
in
{
  home.file.".config/maco/config" = {
    text = ''
      max-visible=-1
      sort=-time
      output=DP-2
      layer=overlay
      anchor=top-right

      font=monospace 10
      background-color=#${palette.base00}E6
      text-color=#${palette.base05}
      width=300
      height=100
      margin=10
      padding=5
      border-size=8
      border-color=#${palette.base07}
      border-radius=0
      progress-color=over #${palette.base0D}
      icons=true
      max-icon-size=64

      markup=true
      actions=true
      format=<b>%s</b>\n%b
      default-timeout=5000
      ignore-timeout=false
    '';
  };
}

{ config, lib, ... }:

{
  home.file.".config/maco/config" = {
    text = ''
      max-visible=-1
      sort=-time
      output=DP-2
      layer=overlay
      anchor=top-right

      font=monospace 10
      background-color=#${config.colorScheme.colors.base00}E6
      text-color=#${config.colorScheme.colors.base05}
      width=300
      height=100
      margin=10
      padding=5
      border-size=2
      border-color=#${config.colorScheme.colors.base07}
      border-radius=0
      progress-color=over #${config.colorScheme.colors.base0D}
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

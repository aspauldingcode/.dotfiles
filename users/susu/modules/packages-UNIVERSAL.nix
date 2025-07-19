{
  config,
  pkgs,
  ...
}:
# Su Su's Applications
{
  home.packages = with pkgs; [
    google-chrome
    anydesk
  ];
}

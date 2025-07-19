{
  config,
  pkgs,
  ...
}:
#FIXME: FAILS DUE TO https://github.com/LnL7/nix-darwin/issues/1041
{
  services.karabiner-elements = {
    enable = false; # Whether to enable Karabiner-Elements.
  };

  # configuration for karabiner is in home-manager.
}

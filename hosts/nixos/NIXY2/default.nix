{
  inputs,
  lib,
  config,
  pkgs,
  mobile-nixos,
  apple-silicon,
  ...
}:
{
  imports = [
    ./hardware-configuration
    ./scripts
    ./modules
    ./temporaryfix # FIXME: remove after success https://github.com/tpwrules/nixos-apple-silicon/issues/276
    ./configuration
  ];
}

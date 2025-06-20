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
    apple-silicon.nixosModules.apple-silicon-support
    ./modules
    # ./temporaryfix # FIXME: remove after success https://github.com/tpwrules/nixos-apple-silicon/issues/276
    ./configuration
  ];
}

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
    apple-silicon.nixosModules.apple-silicon-support
    ./hardware-configuration
    ./scripts
    ./modules
    # ./temporaryfix # FIXME: remove after success https://github.com/tpwrules/nixos-apple-silicon/issues/276
    ./configuration
  ];
}

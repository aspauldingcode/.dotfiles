# DELIVERER Home Configuration for alex
{
  inputs,
  lib,
  config,
  pkgs,
  user,
  hostname,
  ...
}: {
  imports = [
    ../../generic
  ];

  # DELIVERER-specific home configuration
  # (stateVersion is inherited from generic configuration)
}

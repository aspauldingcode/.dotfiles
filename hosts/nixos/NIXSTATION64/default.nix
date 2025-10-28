{ lib, hardwareOverride ? null, ... }:
let
  # Define hostname once for this system
  hostname = "NIXSTATION64";
in
{
  imports = [
    ./scripts
    ./modules
    ./configuration
  ]
  ++ lib.optionals (hardwareOverride == null) [ ./hardware-configuration ]
  ++ lib.optionals (hardwareOverride != null) [ hardwareOverride ];

  # Pass hostname to all imported modules
  _module.args = {
    inherit hostname;
  };
}

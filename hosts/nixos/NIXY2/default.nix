{ lib, hardwareOverride ? null, ... }:
let
  # Define hostname once for this system
  hostname = "NIXY2";
in
{
  imports = [
    ./scripts
    ./modules
    ./configuration

    # Import sops configuration for secrets management (using personal secrets)
    # (inputs.self.sopsConfigs.systemSopsConfig { environment = "personal"; })
  ]
  ++ lib.optionals (hardwareOverride == null) [ ./hardware-configuration ]
  ++ lib.optionals (hardwareOverride != null) [ hardwareOverride ];

  # Pass hostname to all imported modules
  _module.args = {
    inherit hostname;
  };
}

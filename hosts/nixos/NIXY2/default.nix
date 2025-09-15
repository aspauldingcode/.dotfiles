{
  inputs,
  lib,
  config,
  pkgs,
  mobile-nixos,
  apple-silicon,
  ...
}: let
  # Define hostname once for this system
  hostname = "NIXY2";
in {
  imports = [
    ./hardware-configuration
    ./scripts
    ./modules
    ./temporaryfix # FIXME: remove after success https://github.com/tpwrules/nixos-apple-silicon/issues/276
    ./configuration

    # Import sops configuration for secrets management (using personal secrets)
    # (inputs.self.sopsConfigs.systemSopsConfig { environment = "personal"; })
  ];

  # Pass hostname to all imported modules
  _module.args = {
    inherit hostname;
  };
}
